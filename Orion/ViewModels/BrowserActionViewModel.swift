//
//  BrowserActionViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/28/24.
//

import Combine
import os.log
import SwiftData
import WebKit

final class BrowserActionViewModel: ObservableObject {
    private let logger: Logger
    private let webExtension: WebExtension
    private let handlers: [WebViewConfiguring]

    var configuration: WKWebViewConfiguration {
        let config = WKWebViewConfiguration()
        handlers.forEach { $0.configure(webViewConfiguration: config) }
        return config
    }

    init(logger: Logger, modelContext: ModelContext, webExtension: WebExtension) {
        self.logger = logger
        self.webExtension = webExtension

        handlers = [
            BrowserActionSchemeHandler(logger: logger, webExtension: webExtension),
            WebExtMessageHandler(logger: logger, modelContext: modelContext),
        ]
    }

    func makeBrowserActionWebView() -> WKWebView {
        let webView = WKWebView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 0),
            configuration: configuration
        )

        // TODO: render file types other than html
        if let baseUrl = URL(string: "\(BrowserActionSchemeHandler.scheme)://\(webExtension.id)"),
           let defaultPopup = webExtension.manifest.browserAction?.defaultPopup
        {
            let popupUrl = baseUrl.appending(path: defaultPopup.path())
            let popupRequest = URLRequest(url: popupUrl)
            webView.load(popupRequest)
        }

        return webView
    }
}
