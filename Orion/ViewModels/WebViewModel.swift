//
//  WebViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/8/24.
//

import Combine
import Foundation
import os.log
import SwiftData
import UniformTypeIdentifiers
import WebKit

@objc
final class WebViewModel: NSObject, ObservableObject {
    @Published var urlString: String = "about:blank"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var title: String?

    private let logger: Logger
    let modelContext: ModelContext
    let xpiDownloadManager: WKDownloadDelegate?
    let configProviders: [WKConfigurationProviding]

    private lazy var cancelBag = Set<AnyCancellable>()

    init(logger: Logger, modelContext: ModelContext, xpiDownloadManager: WKDownloadDelegate?) {
        self.logger = logger
        self.modelContext = modelContext
        self.xpiDownloadManager = xpiDownloadManager
        configProviders = [
            WKExtensionAPIBridge(modelContext: modelContext),
            WKPageBridge(modelContext: modelContext),
        ]
        super.init()
    }

    func loadUserContentScripts(for webView: WKWebView) {
        // TODO: Get content scripts from WebExtensions
        for configProvider in configProviders {
            configProvider.configure(webView: webView)
        }
    }

    func loadUrl(_ urlString: String, for webView: WKWebView) {
        parseUrlString(urlString) { [weak self] res in
            switch res {
            case let .success(url):
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: url))
                }
            case let .failure(error):
                self?.logger.error("Failed to lookup domain: \(urlString) with error: \(error)")
            }
        }
    }

    func addHistoryItem(title: String?, url: URL?) {
        let historyItem = HistoryItem(url: url, title: title, visitTime: Date())
        modelContext.insert(historyItem)
    }

    private func parseUrlString(
        _ urlString: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        if let url = try? URL(urlString, strategy: .url.host(.required)) {
            completion(.success(url))
            return
        }

        let connection = NWConnection(host: NWEndpoint.Host(urlString), port: .http, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                defer {
                    connection.cancel()
                }
                if let url = URL(string: "http://\(urlString)") {
                    completion(.success(url))
                    return
                }
            case let .failed(error):
                completion(.failure(error))
            default:
                break
            }
        }
        connection.start(queue: .global())
    }
}

extension WebViewModel: WKNavigationDelegate {
    private func updateViewModel(_ webView: WKWebView, navigation _: WKNavigation) {
        title = webView.title
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        if let url = webView.url, urlString != url.absoluteString {
            logger.debug("setting url from navigation: \(url)")
            urlString = url.absoluteString
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateViewModel(webView, navigation: navigation)
        addHistoryItem(title: webView.title, url: webView.url)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateViewModel(webView, navigation: navigation)
    }

    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        updateViewModel(webView, navigation: navigation)
    }

    func webView(
        _: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        preferences: WKWebpagePreferences
    ) async -> (WKNavigationActionPolicy, WKWebpagePreferences) {
        if navigationAction.shouldPerformDownload {
            (.download, preferences)
        } else {
            (.allow, preferences)
        }
    }

    func webView(
        _: WKWebView,
        decidePolicyFor navigationResponse: WKNavigationResponse
    ) async
        -> WKNavigationResponsePolicy {
        if navigationResponse.canShowMIMEType {
            .allow
        } else {
            .download
        }
    }

    func webView(
        _: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        if let mimeType = navigationResponse.response.mimeType,
           let xpiMimeType = UTType.xpi.preferredMIMEType,
           mimeType == xpiMimeType {
            download.delegate = xpiDownloadManager
        }
    }
}
