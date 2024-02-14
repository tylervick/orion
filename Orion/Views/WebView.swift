//
//  WebView.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import WebKit

// TODO: Remove if specific overrides for WebExtensions aren't needed
final class WebView: WKWebView {
//    init(
//        frame: CGRect,
//        configuration: WKWebViewConfiguration,
//        uiDelegate: WKUIDelegate,
//        navDelegate: WKNavigationDelegate
//    ) {
//        super.init(frame: frame, configuration: configuration)
//        self.uiDelegate = uiDelegate
//        navigationDelegate = navDelegate
//    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
