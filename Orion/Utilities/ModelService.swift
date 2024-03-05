//
//  ModelService.swift
//  Orion
//
//  Created by Tyler Vick on 3/4/24.
//

import Foundation
import SwiftData

// Extract ModelContainer logic to singleton
// This is an anti-pattern and preferably would be "injected" from AppDelegate
final class ModelService {
    @MainActor
    static let shared: ModelService = .init()

    let context: ModelContext

    @MainActor
    private init() {
        context = ModelService.makeContainer().mainContext
    }

    @MainActor
    private static func makeContainer(recreateIfNeeded: Bool = true) -> ModelContainer {
        do {
            let storeUrl = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appendingPathComponent("orion.store")

            let configuration = ModelConfiguration(url: storeUrl, allowsSave: true)
            do {
                let container = try ModelContainer(
                    for: HistoryItem.self,
                    WebExtension.self,
                    migrationPlan: HistoryItemMigrationPlan.self,
                    configurations: configuration
                )

                container.mainContext.autosaveEnabled = true
                return container
            } catch {
                if recreateIfNeeded {
                    // We're only here if the expected DB migration failed,
                    // therefore we delete the "bad" store.
                    // TODO: Backup the "corrupted" db and alert the user
                    try FileManager.default.removeItem(at: storeUrl)
                    return makeContainer(recreateIfNeeded: false)
                } else {
                    throw error
                }
            }
        } catch {
            fatalError("Failed to create ModelContainer with error: \(error)")
        }
    }
}
