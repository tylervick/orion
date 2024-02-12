//
//  WebExtensionModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Foundation
import SwiftData

@Model
final class WebExtensionModel {
    @Attribute(.unique)
    var id: String
    var metadata: WebExtensionMetadata
    var path: URL

    init(id: String, metadata: WebExtensionMetadata, path: URL) {
        self.id = id
        self.metadata = metadata
        self.path = path
    }
}

struct WebExtensionMetadata: Codable {
    let applications: [String: [String: String]]
    let author: String
    let browserAction: BrowserAction?
    let defaultLocale: String?
    let description: String
    let homepageUrl: URL?
    let icons: [String: URL]?
    let manifestVersion: Int
    let name: String
    let optionsUi: OptionsUI?
    let permissions: [String]
    let version: String
}

struct BrowserAction: Codable {
    let browserStyle: Bool
    let defaultIcon: [String: URL]?
    let defaultPopup: URL?
    let defaultTitle: String
}

struct OptionsUI: Codable {
    let browserStyle: Bool
    let page: URL?
}

extension WebExtensionMetadata {
    // TODO: keep this test-only
    static let sample = WebExtensionMetadata(
        applications: [:],
        author: "Test Author",
        browserAction: nil,
        defaultLocale: "en-US",
        description: "Test Description",
        homepageUrl: nil,
        icons: nil,
        manifestVersion: 2,
        name: "Test Name",
        optionsUi: nil,
        permissions: [],
        version: "1.0"
    )
}
