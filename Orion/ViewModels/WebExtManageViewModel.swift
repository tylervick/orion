//
//  WebExtManageViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/14/24.
//

import Combine
import Foundation
import os.log
import SwiftData

final class WebExtManageViewModel: ObservableObject {
    @Published var extensions: [WebExtension] = []

    private let modelContext: ModelContext
    private let logger: Logger

    private var cancelBag = Set<AnyCancellable>()

    init(modelContext: ModelContext, logger: Logger) {
        self.modelContext = modelContext
        self.logger = logger
        updateExtensions()
        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .sink { [weak self] _ in
                self?.updateExtensions()
            }.store(in: &cancelBag)
    }

    private func updateExtensions() {
        let descriptor = FetchDescriptor<WebExtension>()
        do {
            let webExtensionModels = try modelContext.fetch(descriptor)
            logger.debug("Installed extension count: \(webExtensionModels.count)")
            extensions = webExtensionModels
        } catch {
            logger.error("Failed to fetch WebExtensionModel")
        }
    }

    func uninstallExtension(_ model: WebExtension) {
        logger.info("Deleting extension: \(model.id)")
        modelContext.delete(model)
        do {
            try modelContext.save()
            try FileManager.default.removeItem(at: model.path)
        } catch {
            logger
                .error(
                    "Failed to remove extension at path: \(model.path) with error: \(error.localizedDescription)"
                )
        }
    }
}
