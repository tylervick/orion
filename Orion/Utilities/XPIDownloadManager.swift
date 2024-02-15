//
//  XPIDownloadManager.swift
//  Orion
//
//  Created by Tyler Vick on 2/15/24.
//

import Foundation
import WebKit
import Combine

final class XPIDownloadManager: NSObject, WKDownloadDelegate {
    private var pendingDownloads = [WKDownload: URL]()
    private var downloadFinishedSubject = PassthroughSubject<URL, Never>()

    var xpiPublisher: AnyPublisher<URL, Never> {
        downloadFinishedSubject.eraseToAnyPublisher()
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
                print("Overwriting file at URL \(destUrl.path())")
                try FileManager.default.removeItem(at: destUrl)
            } catch {
                print("Failed to delete existing file with error: \(error.localizedDescription)")
            }
        }

        pendingDownloads[download] = destUrl
        return destUrl
    }

    func downloadDidFinish(_ download: WKDownload) {
        print("Download finished")
        if let url = pendingDownloads.removeValue(forKey: download) {
            downloadFinishedSubject.send(url)
        }
    }
}
