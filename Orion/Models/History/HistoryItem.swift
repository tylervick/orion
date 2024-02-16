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
    @Attribute(.unique)
    var id: Int
    var url: URL?
    var visitTime: Date?
//    var title: String?
//    var lastVisitTime: UInt?
//    var visitCount: UInt?
//    var typedCount: UInt?

    init(
        id: Int,
        url: URL? = nil,
        visitTime: Date? = nil
//        title: String? = nil,
//        lastVisitTime: UInt? = nil,
//        visitCount: UInt? = nil,
//        typedCount: UInt? = nil
    ) {
        self.id = id
        self.url = url
        self.visitTime = visitTime
//        self.title = title
//        self.lastVisitTime = lastVisitTime
//        self.visitCount = visitCount
//        self.typedCount = typedCount
    }
}
