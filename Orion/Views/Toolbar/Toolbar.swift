//
//  Toolbar.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import AppKit

final class Toolbar: NSToolbar {
    
    init(identifier: NSToolbar.Identifier = "toolbar", delegate: NSToolbarDelegate) {
        super.init(identifier: identifier)
        
        self.delegate = delegate
    }
}

extension NSToolbarItem.Identifier {
    static let prev = NSToolbarItem.Identifier(rawValue: "prev")
    static let next = NSToolbarItem.Identifier(rawValue: "next")
    static let navGroup = NSToolbarItem.Identifier(rawValue: "navGroup")

    static let reload = NSToolbarItem.Identifier(rawValue: "reload")
}

enum ToolbarItemFactory {
    static func createItem(
        itemIdentifier: NSToolbarItem.Identifier,
        label: String,
        paletteLabel: String,
        toolTip: String,
        image: NSImage?,
        target: AnyObject?,
        action: Selector?
    ) -> NSToolbarItem {
        let item = NSToolbarItem(itemIdentifier: itemIdentifier)
        item.label = label
        item.paletteLabel = paletteLabel
        item.toolTip = toolTip
        item.image = image
        item.target = target
        item.action = action
        return item
    }

    static func createItemGroup(
        itemIdentifier: NSToolbarItem.Identifier,
        label: String?,
        paletteLabel: String,
        toolTip: String,
        items: [NSToolbarItem]
    ) -> NSToolbarItemGroup {
        let itemGroup = NSToolbarItemGroup(itemIdentifier: itemIdentifier)
        if let label {
            itemGroup.label = label
        }
        itemGroup.paletteLabel = paletteLabel
        itemGroup.toolTip = toolTip
        itemGroup.subitems = items
        return itemGroup
    }
}
