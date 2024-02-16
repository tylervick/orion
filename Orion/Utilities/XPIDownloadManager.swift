//
//  XPIDownloadManager.swift
//  Orion
//
//  Created by Tyler Vick on 2/15/24.
//

import Combine
import Foundation
import os.log
import WebKit

final class XPIDownloadManager: NSObject, WKDownloadDelegate {
    private var pendingDownloads = [WKDownload: URL]()
    private var downloadFinishedSubject = PassthroughSubject<URL, Never>()

    var xpiPublisher: AnyPublisher<URL, Never> {
        downloadFinishedSubject.eraseToAnyPublisher()
    }

    private let logger: Logger

    init(logger: Logger) {
        self.logger = logger
    }

    func download(
        _ download: WKDownload,
        decideDestinationUsing _: URLResponse,
        suggestedFilename: String
    ) async -> URL? {
        let tmpDir = FileManager.default.temporaryDirectory
        let destUrl = tmpDir.appendingPathComponent(suggestedFilename, isDirectory: false)
        if FileManager.default.fileExists(atPath: destUrl.path()) {
            do {
                logger.info("Overwriting file at URL \(destUrl.path())")
                try FileManager.default.removeItem(at: destUrl)
            } catch {
                logger
                    .error(
                        "Failed to delete existing file with error: \(error.localizedDescription)"
                    )
            }
        }

        logger.debug("XPI download started: \(download), destUrl: \(destUrl)")
        pendingDownloads[download] = destUrl
        return destUrl
    }

    func downloadDidFinish(_ download: WKDownload) {
        logger.debug("XPI download finished: \(download)")
        if let url = pendingDownloads.removeValue(forKey: download) {
            downloadFinishedSubject.send(url)
        }
    }
}
