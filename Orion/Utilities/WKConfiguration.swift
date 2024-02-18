//
//  WKConfiguration.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import WebKit

protocol WKConfigurationProviding {
    func configure(webView: WKWebView)
}
