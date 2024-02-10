//
//  WebViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/8/24.
//

import Combine
import Foundation
import WebKit

final class WebViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false

    private func parseUrlString(_ urlString: String, completion: @escaping (Result<URL, Error>) -> Void) {
        if let url = try? URL(urlString, strategy: .url.host(.required)) {
            completion(.success(url))
            return
        }

        let connection = NWConnection(host: NWEndpoint.Host(urlString), port: .http, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                if let url = URL(string: "http://\(urlString)") {
                    completion(.success(url))
                    return
                }
                connection.cancel()
            case .failed(let error):
                completion(.failure(error))
            default:
                break
            }
        }
        connection.start(queue: .global())
    }

    func loadUrl(_ urlString: String, for webView: WKWebView) {
        parseUrlString(urlString) { res in
            switch res {
            case .success(let url):
                webView.load(URLRequest(url: url))
            case .failure(let error):
                print("Failed to lookup domain: \(urlString) with error: \(error)")
            }
        }
    }

    init() {
        logChanges()
    }

    private lazy var cancelBag = Set<AnyCancellable>()

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
