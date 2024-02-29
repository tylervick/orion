//
//  WebExtMessageHandler.swift
//  Orion
//
//  Created by Tyler Vick on 2/16/24.
//

import Foundation
import os.log
import SwiftData
import WebKit

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

final class WebExtMessageHandler: NSObject, WebViewConfiguring {
    private let modelContext: ModelContext
    private let logger: Logger

    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()
    private lazy var browserScript: WKUserScript? = {
        // Load WebExtension API bridge script
        guard let bridgeBundleUrl = Bundle.main.url(
            forResource: "OrionJSBridge",
            withExtension: "bundle"
        ),
            let bridgeBundle = Bundle(url: bridgeBundleUrl),
            let jsUrl = bridgeBundle.url(forResource: "browser.umd", withExtension: "js"),
            let jsSource = try? String(contentsOf: jsUrl)
        else {
            print("Unable to locate browser.umd.js resource. Skipping WebExtMessageHandler.")
            return nil
        }

        return WKUserScript(
            source: jsSource,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
    }()

    enum Message: String {
        case history
    }

    init(logger: Logger, modelContext: ModelContext) {
        self.logger = logger
        self.modelContext = modelContext
    }

    func configure(webViewConfiguration: WKWebViewConfiguration) {
        if let browserScript {
            webViewConfiguration.userContentController.addUserScript(browserScript)
            webViewConfiguration.userContentController.addScriptMessageHandler(
                self,
                contentWorld: .page,
                name: MessageName.extension
            )
        }
    }
}

@MainActor
extension WebExtMessageHandler: WKScriptMessageHandlerWithReply {
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

        let mostVisitedUrls = results.reduce(into: [String: (Int, String)]()) { accumCount, hi in
            if let url = hi.url {
                if let (curCount, curTitle) = accumCount[url] {
                    accumCount[url] = (curCount + 1, hi.title ?? curTitle)
                    return
                }
                accumCount[url] = (0, hi.title ?? url)
            }
        }.sorted {
            $0.value.0 > $1.value.0
        }.map { url, arg1 in
            let (_, title) = arg1
            return MostVisitedURL(url: url, title: title, favicon: nil)
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
