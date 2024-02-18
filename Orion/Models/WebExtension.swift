//
//  WebExtension.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Foundation
import SwiftData

@Model
final class WebExtension {
    @Attribute(.unique)
    var id: String
    var manifest: WebExtensionManifest
    var path: URL

    init(id: String, manifest: WebExtensionManifest, path: URL) {
        self.id = id
        self.manifest = manifest
        self.path = path
    }
}

@Model
final class WebExtensionManifest: Codable {
    let applications: [String: [String: String]]
    let author: String
    let browserAction: BrowserAction?
    let defaultLocale: String?
    let desc: String?
    let homepageUrl: URL?
    let icons: [String: URL]?
    let manifestVersion: Int
    let name: String
    let optionsUi: OptionsUI?
    let permissions: [String]
    let version: String

    enum CodingKeys: CodingKey {
        case applications
        case author
        case browserAction
        case defaultLocale
        case description
        case desc
        case homepageUrl
        case icons
        case manifestVersion
        case name
        case optionsUi
        case permissions
        case version
    }

    init(
        applications: [String: [String: String]],
        author: String,
        browserAction: BrowserAction?,
        defaultLocale: String?,
        desc: String?,
        homepageUrl: URL?,
        icons: [String: URL]?,
        manifestVersion: Int,
        name: String,
        optionsUi: OptionsUI?,
        permissions: [String],
        version: String
    ) {
        self.applications = applications
        self.author = author
        self.browserAction = browserAction
        self.defaultLocale = defaultLocale
        self.desc = desc
        self.homepageUrl = homepageUrl
        self.icons = icons
        self.manifestVersion = manifestVersion
        self.name = name
        self.optionsUi = optionsUi
        self.permissions = permissions
        self.version = version
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        applications = try container.decode([String: [String: String]].self, forKey: .applications)
        author = try container.decode(String.self, forKey: .author)
        browserAction = try container.decodeIfPresent(BrowserAction.self, forKey: .browserAction)
        defaultLocale = try container.decodeIfPresent(String.self, forKey: .defaultLocale)
        desc = try container.decodeIfPresent(String.self, forKey: .desc)
        desc = try container.decodeIfPresent(String.self, forKey: .description)
        homepageUrl = try container.decodeIfPresent(URL.self, forKey: .homepageUrl)
        icons = try container.decodeIfPresent([String: URL].self, forKey: .icons)
        manifestVersion = try container.decode(Int.self, forKey: .manifestVersion)
        name = try container.decode(String.self, forKey: .name)
        optionsUi = try container.decodeIfPresent(OptionsUI.self, forKey: .optionsUi)
        permissions = try container.decode([String].self, forKey: .permissions)
        version = try container.decode(String.self, forKey: .version)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(applications, forKey: .applications)
        try container.encode(author, forKey: .author)
        try container.encodeIfPresent(browserAction, forKey: .browserAction)
        try container.encodeIfPresent(defaultLocale, forKey: .defaultLocale)
        try container.encodeIfPresent(desc, forKey: .desc)
        try container.encodeIfPresent(homepageUrl, forKey: .homepageUrl)
        try container.encodeIfPresent(icons, forKey: .icons)
        try container.encode(manifestVersion, forKey: .manifestVersion)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(optionsUi, forKey: .optionsUi)
        try container.encode(permissions, forKey: .permissions)
        try container.encode(version, forKey: .version)
    }
}

@Model
final class BrowserAction: Codable {
    let browserStyle: Bool
    let defaultIcon: [String: URL]?
    let defaultPopup: URL?
    let defaultTitle: String

    init(
        browserStyle: Bool,
        defaultIcon: [String: URL]?,
        defaultPopup: URL?,
        defaultTitle: String
    ) {
        self.browserStyle = browserStyle
        self.defaultIcon = defaultIcon
        self.defaultPopup = defaultPopup
        self.defaultTitle = defaultTitle
    }

    enum CodingKeys: CodingKey {
        case browserStyle
        case defaultIcon
        case defaultPopup
        case defaultTitle
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        browserStyle = try container.decode(Bool.self, forKey: .browserStyle)
        defaultIcon = try container.decodeIfPresent([String: URL].self, forKey: .defaultIcon)
        defaultPopup = try container.decodeIfPresent(URL.self, forKey: .defaultPopup)
        defaultTitle = try container.decode(String.self, forKey: .defaultTitle)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(browserStyle, forKey: .browserStyle)
        try container.encodeIfPresent(defaultIcon, forKey: .defaultIcon)
        try container.encodeIfPresent(defaultPopup, forKey: .defaultPopup)
        try container.encode(defaultTitle, forKey: .defaultTitle)
    }
}

struct OptionsUI: Codable {
    let browserStyle: Bool
    let page: URL?
}

extension WebExtensionManifest {
    // TODO: keep this test-only
    static let sample = WebExtensionManifest(
        applications: [:],
        author: "Test Author",
        browserAction: nil,
        defaultLocale: "en-US",
        desc: "Test Description",
        homepageUrl: nil,
        icons: nil,
        manifestVersion: 2,
        name: "Test Name",
        optionsUi: nil,
        permissions: [],
        version: "1.0"
    )
}
