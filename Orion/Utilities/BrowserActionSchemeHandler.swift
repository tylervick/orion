//
//  BrowserActionSchemeHandler.swift
//  Orion
//
//  Created by Tyler Vick on 2/28/24.
//

import Foundation
import os.log
import UniformTypeIdentifiers
import WebKit

enum BrowserActionError: Error {
    case invalidURL
    case invalidHost(String?)
    case noFileAccess(URL?)
}

// Scheme handler expects a pattern of "extension://\(webExtension.id)/resources"
final class BrowserActionSchemeHandler: NSObject, WKURLSchemeHandler {
    static let scheme = "extension"
    private let logger: Logger
    private let webExtension: WebExtension

    private let lock = NSLock()
    private var activeUrlRequests = Set<URLRequest>()

    init(logger: Logger, webExtension: WebExtension) {
        self.logger = logger
        self.webExtension = webExtension
    }

    func webView(_: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
        lock.with {
            activeUrlRequests.insert(urlSchemeTask.request)
        }
        defer {
            lock.with {
                activeUrlRequests.remove(urlSchemeTask.request)
            }
        }
        do {
            try process(urlSchemeTask: urlSchemeTask)
            performIfActive(request: urlSchemeTask.request) {
                urlSchemeTask.didFinish()
            }
        } catch {
            performIfActive(request: urlSchemeTask.request) {
                urlSchemeTask.didFailWithError(error)
            }
        }
    }

    private func performIfActive(request: URLRequest, block: @escaping () -> Void) {
        lock.with {
            if activeUrlRequests.contains(request) {
                block()
            } else {
                logger.warning("Request \(request) is not active, skipping")
            }
        }
    }

    private func process(urlSchemeTask: WKURLSchemeTask) throws {
        guard let url = urlSchemeTask.request.url else {
            throw BrowserActionError.invalidURL
        }
        let fileUrl = try localFileUrl(for: url)
        let contentLength = try contentLength(of: fileUrl)
        let resp = URLResponse(
            url: url,
            mimeType: fileUrl.mimeType,
            expectedContentLength: contentLength,
            textEncodingName: nil
        )

        urlSchemeTask.didReceive(resp)

        try streamFile(from: fileUrl, urlSchemeTask: urlSchemeTask)
    }

    private func localFileUrl(for requestUrl: URL) throws -> URL {
        // Host should be the WebExtension ID
        let host = requestUrl.host(percentEncoded: false)
        guard let host, host == webExtension.id else {
            throw BrowserActionError.invalidHost(host)
        }

        return webExtension.path.appending(path: requestUrl.path())
    }

    private func contentLength(of fileUrl: URL) throws -> Int {
        let attributes = try FileManager.default
            .attributesOfItem(atPath: fileUrl.path(percentEncoded: false))
        if let size = attributes[.size] as? Int {
            return size
        }
        return 0
    }

    private func streamFile(from fileUrl: URL, urlSchemeTask: WKURLSchemeTask) throws {
        guard let stream = InputStream(url: fileUrl) else {
            throw BrowserActionError.noFileAccess(fileUrl)
        }

        stream.open()

        let bufferSize = 1024
        let buffer = UnsafeMutablePointer<UInt8>.allocate(capacity: bufferSize)
        defer {
            buffer.deallocate()
            stream.close()
        }

        while stream.hasBytesAvailable {
            let readCount = stream.read(buffer, maxLength: bufferSize)
            if readCount < 0 {
                if let error = stream.streamError {
                    throw error
                }
                break
            }

            let data = Data(bytes: buffer, count: readCount)
            performIfActive(request: urlSchemeTask.request) {
                urlSchemeTask.didReceive(data)
            }
        }
    }

    func webView(_: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
        lock.with {
            activeUrlRequests.remove(urlSchemeTask.request)
        }
    }
}

extension BrowserActionSchemeHandler: WebViewConfiguring {
    func configure(webViewConfiguration: WKWebViewConfiguration) {
        webViewConfiguration.setURLSchemeHandler(
            self,
            forURLScheme: BrowserActionSchemeHandler.scheme
        )
    }
}

extension URL {
    var mimeType: String? {
        UTType(filenameExtension: pathExtension)?.preferredMIMEType
    }
}

extension NSLock {
    @discardableResult
    func with<T>(_ block: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try block()
    }
}
