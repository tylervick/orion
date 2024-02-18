//
//  WKPageBridge.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Foundation
import SwiftData
import WebKit

final class WKPageBridge: NSObject, WKConfigurationProviding {
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

    private let modelContext: ModelContext
    private lazy var encoder = JSONEncoder()
    private lazy var decoder = JSONDecoder()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func configure(webView: WKWebView) {
        // Assumes "browser.umd.js" is already injected into to the "page" content world
        // Ideally we would update the TypeScript build to output multiple, namespaced bundles,
        // loading them as-needed.
        webView.configuration.userContentController.addScriptMessageHandler(
            self,
            contentWorld: .page,
            name: "history"
        )
    }
}

@MainActor
extension WKPageBridge: WKScriptMessageHandlerWithReply {
    func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        guard message.name == "history" else {
            return (nil, nil)
        }
        return handleHistoryMessage(body: message.body)
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
            let historyItem = HistoryItem(url: url, title: message.title, visitTime: Date())
            modelContext.insert(historyItem)
            try modelContext.save()
        } catch {
            return (nil, error.localizedDescription)
        }
        return (nil, nil)
    }
}
