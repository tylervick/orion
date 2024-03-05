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
        if let userAgent = webView.value(forKey: "userAgent") as? String {
            // Override UA with Safari for a better time
            webView.customUserAgent = userAgent + "Version/17.3 Safari/605.1.15"
        }

        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        viewModel?.loadUserContentScripts(for: webView)

    }

    init(viewModel: WebViewModel, actionPublisher: AnyPublisher<WebWindowToolbarAction, Never>) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        
        actionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                switch $0 {
                case .back:
                    self?.performBack()
                case .forward:
                    self?.performForward()
                case .reload:
                    self?.performReload()
                case let .urlSubmitted(urlString):
                    self?.loadUrlString(urlString)
                default:
                    break
                }
            }.store(in: &cancelBag)
    }

    required init?(coder: NSCoder) {
        viewModel = nil
        super.init(coder: coder)
    }

    func loadUrlString(_ urlString: String) {
        viewModel?.load(urlString: urlString, for: webView)
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
