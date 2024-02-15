//
//  WebViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/8/24.
//

import Combine
import Foundation
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

    let modelContext: ModelContext
    let xpiDownloadManager: WKDownloadDelegate?

    private lazy var cancelBag = Set<AnyCancellable>()

    init(modelContext: ModelContext, xpiDownloadManager: WKDownloadDelegate?) {
        self.modelContext = modelContext
        self.xpiDownloadManager = xpiDownloadManager
        super.init()
        logChanges()
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

    func addHistoryItem(id: Int, url: URL?) {
        let historyItem = HistoryItem(id: id, url: url, visitTime: Date())
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
    private func updateViewModel(_ webView: WKWebView, navigation: WKNavigation) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        if let url = webView.url {
            print("setting url from navigation: \(url)")
            urlString = url.absoluteString
        }
        addHistoryItem(id: navigation.hash, url: webView.url)
    }

    func webView(_: WKWebView, didFinish _: WKNavigation!) {}

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
        let xpiType = UTType("com.tylervick.orion.xpi")

        if let mimeType = navigationResponse.response.mimeType,
           let xpiMimeType = xpiType?.preferredMIMEType,
           mimeType == xpiMimeType
        {
            download.delegate = xpiDownloadManager
        }
    }
}
