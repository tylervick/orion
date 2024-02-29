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
    @Published var urlString: String = aboutBlank
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false
    @Published var title: String?

    private let logger: Logger
    let modelContext: ModelContext
    let xpiDownloadManager: WKDownloadDelegate?
    let configProviders: [WebViewConfiguring]

    private lazy var cancelBag = Set<AnyCancellable>()

    init(logger: Logger, modelContext: ModelContext, xpiDownloadManager: WKDownloadDelegate?) {
        self.logger = logger
        self.modelContext = modelContext
        self.xpiDownloadManager = xpiDownloadManager
        configProviders = [
            WebExtMessageHandler(logger: logger, modelContext: modelContext),
        ]
        super.init()
    }

    func loadUserContentScripts(for webView: WKWebView) {
        // TODO: Get content scripts from WebExtensions
        for configProvider in configProviders {
            configProvider.configure(webViewConfiguration: webView.configuration)
        }
    }

    func load(urlString: String, for webView: WKWebView) {
        do {
            let url = try parse(urlString: urlString)
            DispatchQueue.main.async {
                webView.load(URLRequest(url: url))
            }
        } catch {
            logger.error("Failed to create URL from input: \(urlString)")
        }
    }

    func addHistoryItem(title: String?, url: URL?) {
        let historyItem = HistoryItem(url: url?.absoluteString, title: title, visitTime: Date())
        modelContext.insert(historyItem)
    }
    
    func updateHistoryItem(newTitle title: String, forUrl url: URL) {
        let urlString = url.absoluteString
        let predicate = #Predicate<HistoryItem> {
            $0.url == urlString
        }
        let descriptor = FetchDescriptor<HistoryItem>(predicate: predicate)
        do {
            let items = try modelContext.fetch(descriptor)
            items.forEach { $0.title = title }
            try modelContext.save()
        } catch {
            logger.error("Failed to fetch items for url \(url) with error \(error)")
        }
    }

    private func parse(urlString: String) throws -> URL {
        // If the user entered a valid URL, use it
        if let url = try? URL(urlString, strategy: .url.host(.required)) {
            return url
        }
        
        // Next, attempt to "fix" the URL by adding a scheme.
        // E.g. the input "google.com" is not a valid URL, but "https://google.com" is.
        // TODO: Perform a DNS lookup to first check if the "domain" is valid
        if let url = URL(string: "https://\(urlString)") {
            return url
        }
        
        // If the above didn't work, fallback to a search query
        if let url = URL(string: "\(searchPrefixUrl)\(urlString)") {
            return url
        }

        throw URLError(.badURL)
    }
}

extension WebViewModel: WKNavigationDelegate {
    private func updateViewModel(_ webView: WKWebView) {
        canGoBack = webView.canGoBack
        canGoForward = webView.canGoForward
        if let url = webView.url, urlString != url.absoluteString {
            logger.debug("setting url from navigation: \(url)")
            urlString = url.absoluteString
        }
        if let webViewTitle = webView.title, webViewTitle != "" {
            title = webViewTitle
        }
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        updateViewModel(webView)
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        updateViewModel(webView)
    }

    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation navigation: WKNavigation!
    ) {
        updateViewModel(webView)
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

    func webView(_: WKWebView, didNavigateWith navigationData: WKNavigationData) {
        addHistoryItem(title: navigationData.title, url: navigationData.destinationURL)
    }
    
    func webView(_ webView: WKWebView, didUpdateHistoryTitle title: String, for url: URL) {
        // Update the current tab/window's title
        self.title = title
        updateHistoryItem(newTitle: title, forUrl: url)
    }
}
