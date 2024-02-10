//
//  WebViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa
import Combine
import WebKit

protocol ToolbarDelegate: AnyObject {
    var viewModel: WebViewModel { get }
    var cancellables: Set<AnyCancellable> { get set }

    func loadUrlString(_: String)
    func performBack()
    func performForward()
    func performReload()
}

final class WebViewController: NSViewController, ToolbarDelegate {
    var webView: WKWebView!
    let viewModel = WebViewModel()
    var cancellables = Set<AnyCancellable>()

    override func loadView() {
        super.loadView()
        let configuration = WKWebViewConfiguration()

        webView = WebView(
            frame: view.frame,
            configuration: configuration,
            uiDelegate: self,
            navDelegate: self
        )

        view = webView!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func loadUrlString(_ urlString: String) {
        viewModel.loadUrl(urlString, for: webView)
    }

    func performBack() {
        webView?.goBack()
    }

    func performForward() {
        webView?.goForward()
    }

    func performReload() {
        webView?.reload()
    }
}

extension WebViewController: WKUIDelegate {}

extension WebViewController: WKNavigationDelegate {
    private func updateViewModel(_: WKWebView) {
        viewModel.canGoBack = webView.canGoBack
        viewModel.canGoForward = webView.canGoForward
        if let url = webView.url {
            print("setting url from navigation: \(url)")
            viewModel.urlString = url.absoluteString
        }
    }

    func webView(_ webView: WKWebView, didStartProvisionalNavigation _: WKNavigation!) {
        updateViewModel(webView)
    }

    func webView(
        _ webView: WKWebView,
        didReceiveServerRedirectForProvisionalNavigation _: WKNavigation!
    ) {
        updateViewModel(webView)
    }
}
