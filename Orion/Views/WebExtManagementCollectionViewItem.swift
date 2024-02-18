//
//  WebExtManagementCollectionViewItem.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Cocoa
import SwiftData

final class WebExtManagementCollectionViewItem: NSCollectionViewItem {
    var modelContext: ModelContext?

    override func loadView() {
        view = WebExtensionMetadataView()
    }

    override var representedObject: Any? {
        didSet {
            if let model = representedObject as? WebExtension {
                (view as? WebExtensionMetadataView)?.manifest = model.manifest
            }
        }
    }
}
