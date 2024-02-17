//
//  WKExtensionAPIBridge.swift
//  Orion
//
//  Created by Tyler Vick on 2/16/24.
//

import Foundation
import SwiftData
import WebKit

final class WKExtensionAPIBridge: NSObject, WKConfigurationProviding {
    private let modelContext: ModelContext
    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()

    enum Message: String {
        case history
    }

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func configure(webView: WKWebView) {
        // Load WebExtension API bridge script
        guard let bridgeBundleUrl = Bundle.main.url(
            forResource: "OrionJSBridge",
            withExtension: "bundle"
        ),
            let bridgeBundle = Bundle(url: bridgeBundleUrl),
            let jsUrl = bridgeBundle.url(forResource: "browser.umd", withExtension: "js"),
            let jsSource = try? String(contentsOf: jsUrl)
        else {
            print("Unable to locate browser.umd.js resource")
            return
        }

        let browserScript = WKUserScript(
            source: jsSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )

        webView.configuration.userContentController.addUserScript(browserScript)
        webView.configuration.userContentController.addScriptMessageHandler(
            self,
            contentWorld: .page,
            name: MessageName.extension
        )
    }
}

@MainActor
extension WKExtensionAPIBridge: WKScriptMessageHandlerWithReply {
    func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        switch message.name {
        case MessageName.extension:
            await handleWebExAPI(body: message.body)
        default:
            (nil, "Invalid message")
        }
    }

    func handleWebExAPI(body: Any) async -> (Any?, String?) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            let apiBody = try decoder.decode(WebExtAPIBody.self, from: jsonData)
            switch apiBody.method {
            case .topSites:
                return handleTopSites(payload: apiBody.payload)
            }
        } catch {
            return (nil, error.localizedDescription)
        }
    }

    func handleTopSites(payload _: [String: String]?) -> (Any?, String?) {
        let pred = #Predicate<HistoryItem> {
            $0.url != nil
        }
        let fd = FetchDescriptor<HistoryItem>(
            predicate: pred,
            sortBy: [.init(\.visitTime, order: .reverse)]
        )

        guard let results = try? modelContext.fetch(fd) else {
            return (nil, "Unable to fetch HistoryItem objects")
        }

        let mostVisitedUrls = results.reduce(into: [URL: (Int, String)]()) { accumCount, hi in
            if let url = hi.url {
                if let (curCount, curTitle) = accumCount[url] {
                    accumCount[url] = (curCount + 1, hi.title ?? curTitle)
                    return
                }
                accumCount[url] = (0, hi.title ?? url.absoluteString)
            }
        }.sorted {
            $0.value.0 > $1.value.0
        }.map { url, arg1 in
            let (_, title) = arg1
            return MostVisitedURL(url: url.absoluteString, title: title, favicon: nil)
        }

        do {
            let encodedResponse = try encoder.encode(mostVisitedUrls)
            let jsonData = try JSONSerialization.jsonObject(with: encodedResponse)
            // TODO: Apply input options, such as limit, one entry per domain, etc.
            return (jsonData, nil)
        } catch {
            return (nil, error.localizedDescription)
        }
    }
}

enum WebExtAPIMethod: String, Codable {
    case topSites
}

struct WebExtAPIBody: Codable {
    let method: WebExtAPIMethod
    let payload: [String: String]?
}

enum MessageName {
    static let `extension` = "extension"
}

struct MostVisitedURL: Codable {
    let url: String
    let title: String
    let favicon: String?
}
