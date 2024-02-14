//
//  WebExtensionViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Foundation
import SwiftData
import ZIPFoundation

final class WebExtensionViewModel: ObservableObject {
    @Published var manifest: WebExtensionManifest?
    @Published var xpiUrl: URL

    let modelContext: ModelContext

    init(modelContext: ModelContext, xpiUrl: URL) {
        self.xpiUrl = xpiUrl
        self.modelContext = modelContext
        do {
            manifest = try parseManifestFromArchive(xpiUrl)
        } catch {
            print("""
            Failed to parse manifest.
            URL: \(xpiUrl)
            Error: \(error.localizedDescription)
            """)
        }
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

//    func unpackExtension(path _: URL) -> WebExtensionMetadata {}

    func installExtension() throws {
        // Move the xpi archive from the tmp staging area to app support
        let id = UUID().uuidString
        let webExtDir = try FileManager.default.url(
            for: .applicationSupportDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: true
        ).appending(path: "WebExtensions")

        if !FileManager.default.fileExists(atPath: webExtDir.path()) {
            try FileManager.default.createDirectory(
                at: webExtDir,
                withIntermediateDirectories: true
            )
        }

        if !FileManager.default.isWritableFile(atPath: webExtDir.path()) {
            print("webext dir is not writable")
            return
        }

        let installUrl = webExtDir.appending(component: id).appendingPathExtension(".xpi")
        if FileManager.default.fileExists(atPath: installUrl.path()) {
            try FileManager.default.removeItem(at: installUrl)
        }

        try FileManager.default.moveItem(at: xpiUrl, to: installUrl)

        if let manifest {
            let model = WebExtensionModel(id: id, metadata: manifest, path: installUrl)
            modelContext.insert(model)
            try modelContext.save()
        }
    }

    func uninstallExtension(_ model: WebExtensionModel) throws {
        modelContext.delete(model)
        try modelContext.save()
        try FileManager.default.removeItem(at: model.path)
    }
}
