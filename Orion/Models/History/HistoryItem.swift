//
//  HistoryItem.swift
//  Orion
//
//  Created by Tyler Vick on 2/10/24.
//

import SwiftData

@Model
final class HistoryItem {
    @Attribute(.unique)
    var id: String
    var url: String?
    var title: String?
    var lastVisitTime: UInt?
    var visitCount: UInt?
    var typedCount: UInt?

    init(
        id: String,
        url: String? = nil,
        title: String? = nil,
        lastVisitTime: UInt? = nil,
        visitCount: UInt? = nil,
        typedCount: UInt? = nil
    ) {
        self.id = id
        self.url = url
        self.title = title
        self.lastVisitTime = lastVisitTime
        self.visitCount = visitCount
        self.typedCount = typedCount
    }
}
