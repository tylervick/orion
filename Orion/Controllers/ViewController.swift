//
//  ViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa
import WebKit

protocol ToolbarActionDelegate: AnyObject {
    func performBack()
    func performForward()
    func performReload()
}

final class ViewController: NSViewController, ToolbarActionDelegate {
    var webView: WKWebView?

    func performBack() {
        webView?.goBack()
    }

    func performForward() {
        webView?.goForward()
    }

    func performReload() {
        webView?.reload()
    }

    override func loadView() {
        super.loadView()
        let configuration = WKWebViewConfiguration()
        let uiDelegate = WebUIViewModel()
        let navDelegate = WebNavigationViewModel()

        webView = WebView(
            frame: view.frame,
            configuration: configuration,
            uiDelegate: uiDelegate,
            navDelegate: navDelegate
        )

        view = webView!
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let startUrl = URL(string: "https://apple.com")!
        let req = URLRequest(url: startUrl)
        webView?.load(req)
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
}
