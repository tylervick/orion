//
//  BrowserActionViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Cocoa
import os.log
import SwiftData
import WebKit

final class BrowserActionViewController: NSViewController {
    let webView: WKWebView?
    let logger: Logger
    let webExtension: WebExtension?
    private lazy var fileServer = FileServer(addr: .inet(port: 0))

    init(logger: Logger, modelContext: ModelContext, webExtension: WebExtension) {
        self.logger = logger
        self.webExtension = webExtension
        let webView = WKWebView()

        let configProvider = WKExtensionAPIBridge(modelContext: modelContext)
        configProvider.configure(webView: webView)
        self.webView = webView

        super.init(nibName: nil, bundle: nil)
        setupFileServer(extensionUrl: webExtension.path)
    }

    override func viewWillDisappear() {
        Task {
            await fileServer.stop()
        }
    }

    required init?(coder: NSCoder) {
        logger = Logger()
        webExtension = nil
        webView = nil
        super.init(coder: coder)
    }

    private func setupFileServer(extensionUrl: URL) {
        Task {
            try await fileServer.start(root: extensionUrl)
            if let address = await fileServer.getAddress() {
                switch address {
                case let .ip4(_, port):
                    if let url = URL(string: "http://localhost:\(port)") {
                        setupWebView(baseUrl: url)
                        return
                    }
                default:
                    break
                }
                logger.error("Invalid address for Browser Action")
            }
        }
    }

    private func setupWebView(baseUrl: URL) {
        guard let webView else {
            return
        }

        webView.frame = view.frame
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isInspectable = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // TODO: render file types other than html
        if let defaultPopup = webExtension?.manifest.browserAction?.defaultPopup {
            let popupUrl = baseUrl.appending(path: defaultPopup.path)
            let popupRequest = URLRequest(url: popupUrl)
            webView.load(popupRequest)
        }
    }
}
