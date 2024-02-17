//
//  WKExtensionAPIBridge.swift
//  Orion
//
//  Created by Tyler Vick on 2/16/24.
//

import Foundation
import SwiftData
import WebKit

final class WKExtensionAPIBridge: NSObject {
    private let modelContext: ModelContext
    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()

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
            name: "extension"
        )
        webView.configuration.userContentController.addScriptMessageHandler(
            self,
            contentWorld: .page,
            name: "history"
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
        case MessageName.history:
            handleHistoryMessage(body: message.body)
        default:
            (nil, "Invalid message")
        }
    }

    func handleHistoryMessage(body: Any) -> (Any?, String?) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: body, options: [])
            let message = try decoder.decode(HistoryItemMessage.self, from: jsonData)
            let url = {
                if let href = message.href {
                    return URL(string: href)
                }
                if let host = message.host,
                   let url = message.url,
                   let components = URLComponents(string: "\(host)\(url)")
                {
                    return components.url
                }
                return nil
            }()
            let historyItem = HistoryItem(url: url, visitTime: Date())
            modelContext.insert(historyItem)
            try modelContext.save()
        } catch {
            return (nil, error.localizedDescription)
        }
        return (nil, nil)
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
    static let history = "history"
}

// This is a translated version of `HistoryItem` at ./OrionJSBrdige/lib/types.ts#HistoryItem
// FIXME: Use a single source-of-truth with language-specific bindings (e.g. Proto, maybe github.com/Apple/pkl?)
struct HistoryItemMessage: Codable {
    enum HistoryEvent: String, Codable {
        case pushState
        case replaceState
        case popState
    }

    let event: HistoryEvent
    let href: String?
    let host: String?
    let state: [String: String]?
    let title: String?
    let url: String?
}

struct MostVisitedURL: Codable {
    let url: String
    let title: String
    let favicon: String?
}
