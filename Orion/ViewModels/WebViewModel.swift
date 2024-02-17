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
    @Published var urlString: String =
        "https://addons.mozilla.org/en-US/firefox/addon/top-sites-button/"
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false

    private let logger: Logger
    let modelContext: ModelContext
    let xpiDownloadManager: WKDownloadDelegate?
    let apiBridge: WKExtensionAPIBridge

    private lazy var cancelBag = Set<AnyCancellable>()

    init(logger: Logger, modelContext: ModelContext, xpiDownloadManager: WKDownloadDelegate?) {
        self.logger = logger
        self.modelContext = modelContext
        self.xpiDownloadManager = xpiDownloadManager
        apiBridge = WKExtensionAPIBridge(modelContext: modelContext)
        super.init()
        logChanges()
    }

    func loadUserContentScripts(for webView: WKWebView) {
        // TODO: Get content scripts from WebExtensions
        apiBridge.configure(webView: webView)
    }

    func loadUrl(_ urlString: String, for webView: WKWebView) {
        parseUrlString(urlString) { res in
            switch res {
            case let .success(url):
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: url))
                }
            case let .failure(error):
                print("Failed to lookup domain: \(urlString) with error: \(error)")
            }
        }
    }

    func addHistoryItem(id _: Int, url: URL?) {
        let historyItem = HistoryItem(url: url, visitTime: Date())
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

    private func logChanges() {
        $urlString
            .combineLatest($canGoBack, $canGoForward, $isLoading)
            .sink { urlString, canGoBack, canGoForward, isLoading in
                print("""
                WebViewModel:
                    urlString: \(urlString)
                    canGoBack: \(canGoBack)
                    canGoForward: \(canGoForward)
                    isLoading: \(isLoading)
                """)
            }.store(in: &cancelBag)
    }
}

extension WebViewModel: WKNavigationDelegate {
    private func updateViewModel(_ webView: WKWebView, navigation _: WKNavigation) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        if let url = webView.url {
            print("setting url from navigation: \(url)")
            urlString = url.absoluteString
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateViewModel(webView, navigation: navigation)
        addHistoryItem(id: navigation.hash, url: webView.url)
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
        -> WKNavigationResponsePolicy
    {
        if navigationResponse.canShowMIMEType {
            .allow
        } else {
            .download
        }
    }

    func webView(
        _: WKWebView,
        navigationAction _: WKNavigationAction,
        didBecome _: WKDownload
    ) {
//        download.delegate = xpiDownloadManager
    }

    func webView(
        _: WKWebView,
        navigationResponse: WKNavigationResponse,
        didBecome download: WKDownload
    ) {
        if let mimeType = navigationResponse.response.mimeType,
           let xpiMimeType = UTType.xpi.preferredMIMEType,
           mimeType == xpiMimeType
        {
            download.delegate = xpiDownloadManager
        }
    }
}
