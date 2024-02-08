//
//  WindowController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa

final class WindowController: NSWindowController {
    let toolbarViewModel = ToolbarViewModel()

    @IBOutlet var toolbar: Toolbar!
    @IBOutlet var back: NSToolbarItem!
    @IBOutlet var forward: NSToolbarItem!
    @IBOutlet var reload: NSToolbarItem!
    @IBOutlet var location: NSToolbarItem!

    weak var toolbarActionDelegate: ToolbarActionDelegate?

    override func windowDidLoad() {
        if let webViewController = contentViewController as? ViewController {
            toolbarActionDelegate = webViewController
        }

        window?.title = ""
    }

    @IBAction func backButtonClicked(_: NSToolbarItem) {
        print("Prev button clicked")
    }

    @IBAction func forwardButtonClicked(_: NSToolbarItem) {
        print("Next button clicked")
    }

    @IBAction func reloadButtonClicked(_: NSToolbarItem) {
        print("Reload button clicked")
        toolbarActionDelegate?.performReload()
    }

    @IBAction func locationSent(_: Any) {
        print("location sent")
    }
}

extension WindowController: NSToolbarDelegate {}
