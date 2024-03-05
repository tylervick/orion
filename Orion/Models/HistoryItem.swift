//
//  HistoryItem.swift
//  Orion
//
//  Created by Tyler Vick on 2/10/24.
//

import Foundation
import SwiftData

typealias HistoryItem = HistoryItemSchemaV2.HistoryItem

enum HistoryItemSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [HistoryItem.self]
    }

    @Model
    final class HistoryItem {
        var url: URL?
        var title: String?
        var visitTime: Date?

        init(
            url: URL? = nil,
            title: String? = nil,
            visitTime: Date? = nil
        ) {
            self.url = url
            self.title = title
            self.visitTime = visitTime
        }
    }
}

enum HistoryItemSchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 1)

    static var models: [any PersistentModel.Type] {
        [HistoryItem.self]
    }

    @Model
    final class HistoryItem {
        var url: String?
        var title: String?
        var visitTime: Date?

        init(
            url: String? = nil,
            title: String? = nil,
            visitTime: Date? = nil
        ) {
            self.url = url
            self.title = title
            self.visitTime = visitTime
        }
    }
}

enum HistoryItemMigrationPlan: SchemaMigrationPlan {
    static var schemas: [VersionedSchema.Type] {
        [HistoryItemSchemaV1.self, HistoryItemSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [v1ToV2]
    }

    static let v1ToV2 = MigrationStage.custom(
        fromVersion: HistoryItemSchemaV1.self,
        toVersion: HistoryItemSchemaV2.self,
        willMigrate: nil
    ) { context in
        let oldItems = try context.fetch(FetchDescriptor<HistoryItemSchemaV1.HistoryItem>())

        for oldItem in oldItems {
            let newItem = HistoryItemSchemaV2.HistoryItem(
                url: oldItem.url?.absoluteString,
                title: oldItem.title,
                visitTime: oldItem.visitTime
            )
            context.insert(newItem)
            context.delete(oldItem)
        }

        try? context.save()
    }
}

struct MostVisitedURL: Codable {
    let url: String
    let title: String
    let favicon: String?
}
