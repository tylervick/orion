//
//  WindowController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa

final class WindowController: NSWindowController {
    weak var toolbarActionDelegate: ToolbarActionDelegate?

    let vm = ToolbarViewModel()

    override func windowDidLoad() {
        let toolbar = Toolbar(delegate: self)
//        let toolbar = NSToolbar(identifier: "default")
//        toolbar.delegate = self
        window?.toolbar = toolbar
        if let webViewController = contentViewController as? ViewController {
            toolbarActionDelegate = webViewController
        }

//        let tb = NSToolbar(identifier: "toolbar")
//        tb.delegate = self
//        window?.toolbar = tb
    }

    @objc func prevButtonClicked(_: NSToolbarItem) {
        print("Prev button clicked")
    }

    @objc func nextButtonClicked(_: NSToolbarItem) {
        print("Next button clicked")
    }

    @objc func reloadButtonClicked(_: NSToolbarItem) {
        print("Reload button clicked")
        toolbarActionDelegate?.performReload()
    }
}

extension WindowController: NSToolbarDelegate {
    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        switch itemIdentifier {
        case .navGroup:
            let prevItem = ToolbarItemFactory.createItem(
                itemIdentifier: .prev,
                label: "Back",
                paletteLabel: "Back",
                toolTip: "Go Back",
                image: NSImage(
                    systemSymbolName: "chevron.left",
                    accessibilityDescription: "A left arrow"
                ),
                target: self,
                action: #selector(prevButtonClicked(_:))
            )
            let nextItem = ToolbarItemFactory.createItem(
                itemIdentifier: .next,
                label: "Forward",
                paletteLabel: "Forward",
                toolTip: "Go forward",
                image: NSImage(
                    systemSymbolName: "chevron.right",
                    accessibilityDescription: "A right arrow"
                ),
                target: self,
                action: #selector(nextButtonClicked(_:))
            )
            return ToolbarItemFactory.createItemGroup(
                itemIdentifier: itemIdentifier,
                label: nil,
                paletteLabel: "Navigation",
                toolTip: "Navigation",
                items: [prevItem, nextItem]
            )
        case .reload:
            return ToolbarItemFactory.createItem(
                itemIdentifier: .reload,
                label: "Reload",
                paletteLabel: "Reload",
                toolTip: "Reload Page",
                image: NSImage(
                    systemSymbolName: "arrow.clockwise",
                    accessibilityDescription: "A clockwise arrow"
                ),
                target: self,
                action: #selector(reloadButtonClicked(_:))
            )
        default:
            return nil
        }
    }

    func toolbarAllowedItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.navGroup]
    }

    func toolbarDefaultItemIdentifiers(_: NSToolbar) -> [NSToolbarItem.Identifier] {
        [.navGroup]
    }
}
