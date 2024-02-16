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

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func configure(webView: WKWebView) {
        // Load WebExtension API bridge script
        guard let jsUrl = Bundle.main.url(forResource: "browser.umd", withExtension: "js"),
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
            contentWorld: .defaultClient,
            name: MessageNames.topSites
        )
    }
}

extension WKExtensionAPIBridge: WKScriptMessageHandlerWithReply {
    func userContentController(
        _: WKUserContentController,
        didReceive message: WKScriptMessage
    ) async -> (Any?, String?) {
        switch message.name {
        default:
            (nil, "Invalid message")
        }
    }
}

enum MessageNames {
    static let topSites = "topSites"
}
