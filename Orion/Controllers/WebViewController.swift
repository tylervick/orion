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

final class WebViewController: NSViewController {
    var webView: WKWebView!
    let viewModel: WebViewModel?
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

    init(viewModel: WebViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        viewModel = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    func loadUrlString(_ urlString: String) {
        viewModel?.loadUrl(urlString, for: webView)
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
    private func updateViewModel(_ webView: WKWebView, navigation: WKNavigation) {
        viewModel?.canGoBack = webView.canGoBack
        viewModel?.canGoForward = webView.canGoForward
        if let url = webView.url {
            print("setting url from navigation: \(url)")
            viewModel?.urlString = url.absoluteString
        }
        viewModel?.addHistoryItem(id: navigation.hash, url: webView.url)
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
}
