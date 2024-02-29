//
//  BrowserActionViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Cocoa
import Foundation
import os.log
import SwiftData
import WebKit

final class BrowserActionViewController: NSViewController {
    let webView: WKWebView?
    let viewModel: BrowserActionViewModel?

    init(viewModel: BrowserActionViewModel) {
        self.viewModel = viewModel
        webView = viewModel.makeBrowserActionWebView()
        super.init(nibName: nil, bundle: nil)

        setupWebView()
    }

    required init?(coder: NSCoder) {
        webView = nil
        viewModel = nil
        super.init(coder: coder)
    }

    private func setupWebView() {
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
    }
}
