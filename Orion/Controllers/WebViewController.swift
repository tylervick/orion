//
//  WebViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa
import Combine
import WebKit

final class WebViewController: NSViewController {
    var webView: WKWebView!
    let viewModel: WebViewModel?
    private var cancelBag = Set<AnyCancellable>()

    override func loadView() {
        super.loadView()

        webView = WKWebView(frame: view.frame)
        webView.isInspectable = true
        webView.navigationDelegate = viewModel
        webView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        webView.configuration.preferences.setValue(true, forKey: "developerExtrasEnabled")
        viewModel?.loadUserContentScripts(for: webView)
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
        // Load initial urlString if present
        if let urlString = viewModel?.urlString {
            loadUrlString(urlString)
        }
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
