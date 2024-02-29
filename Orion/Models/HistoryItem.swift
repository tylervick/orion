//
//  HistoryItem.swift
//  Orion
//
//  Created by Tyler Vick on 2/10/24.
//

import Foundation
import SwiftData

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

struct MostVisitedURL: Codable {
    let url: String
    let title: String
    let favicon: String?
}
