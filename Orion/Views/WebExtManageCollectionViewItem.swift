//
//  WebExtManageCollectionViewItem.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Cocoa
import SwiftData

final class WebExtManageCollectionViewItem: NSCollectionViewItem {
    var modelContext: ModelContext?

    override func loadView() {
        view = WebExtMetadataView()
    }

    override var representedObject: Any? {
        didSet {
            if let model = representedObject as? WebExtension {
                (view as? WebExtMetadataView)?.manifest = model.manifest
            }
        }
    }
}
