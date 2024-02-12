//
//  WebViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/8/24.
//

import Combine
import Foundation
import SwiftData
import WebKit

final class WebViewModel: ObservableObject {
    @Published var urlString: String = ""
    @Published var canGoBack: Bool = false
    @Published var canGoForward: Bool = false
    @Published var isLoading: Bool = false

    let modelContext: ModelContext

    private lazy var cancelBag = Set<AnyCancellable>()

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        logChanges()
    }

    func loadUrl(_ urlString: String, for webView: WKWebView) {
        parseUrlString(urlString) { res in
            switch res {
            case let .success(url):
                DispatchQueue.main.async {
                    webView.load(URLRequest(url: url))
                }
            case let .failure(error):
                print("Failed to lookup domain: \(urlString) with error: \(error)")
            }
        }
    }

    func addHistoryItem(id: Int, url: URL?) {
        let historyItem = HistoryItem(id: id, url: url, visitTime: Date())
        modelContext.insert(historyItem)
    }

    private func parseUrlString(
        _ urlString: String,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        if let url = try? URL(urlString, strategy: .url.host(.required)) {
            completion(.success(url))
            return
        }

        let connection = NWConnection(host: NWEndpoint.Host(urlString), port: .http, using: .tcp)
        connection.stateUpdateHandler = { state in
            switch state {
            case .ready:
                defer {
                    connection.cancel()
                }
                if let url = URL(string: "http://\(urlString)") {
                    completion(.success(url))
                    return
                }
            case let .failed(error):
                completion(.failure(error))
            default:
                break
            }
        }
        connection.start(queue: .global())
    }

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
