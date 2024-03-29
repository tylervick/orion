//
//  WebExtInstallViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Foundation
import os.log
import SwiftData
import UniformTypeIdentifiers
import ZIPFoundation

final class WebExtInstallViewModel: ObservableObject {
    @Published var manifest: WebExtensionManifest?
    @Published var xpiUrl: URL

    private let modelContext: ModelContext
    private let logger: Logger

    enum Errors: Error {
        case manifestMissingOrMalformed
    }

    init(modelContext: ModelContext, xpiUrl: URL, logger: Logger) throws {
        self.xpiUrl = xpiUrl
        self.modelContext = modelContext
        self.logger = logger
        manifest = try parseManifestFromArchive(xpiUrl)
    }

    private func parseManifestFromArchive(_ url: URL) throws -> WebExtensionManifest {
        let archive = try Archive(url: url, accessMode: .read)
        guard let entry = archive["manifest.json"] else {
            throw Archive.ArchiveError.invalidEntryPath
        }

        var data = Data()
        let crc32 = try archive.extract(entry, bufferSize: defaultReadChunkSize) { chunk in
            data.append(chunk)
        }
        guard crc32 == entry.checksum else {
            throw Archive.ArchiveError.invalidCRC32
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(WebExtensionManifest.self, from: data)
    }

    func installExtension() throws {
        guard let manifest else {
            logger.error("Failed to install extension: manifest is missing or malformed")
            throw Errors.manifestMissingOrMalformed
        }

        // Move the xpi archive from the tmp staging area to app support
        let id = UUID().uuidString
        let installUrl = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        )
        .appending(path: "WebExtensions")
        .appending(component: id)

        if FileManager.default.fileExists(atPath: installUrl.path()) {
            try FileManager.default.removeItem(at: installUrl)
        }

        try FileManager.default.createDirectory(at: installUrl, withIntermediateDirectories: true)
        try FileManager.default.unzipItem(at: xpiUrl, to: installUrl)

        let model = WebExtension(id: id, manifest: manifest, path: installUrl)
        modelContext.insert(model)
        try modelContext.save()
    }
}
