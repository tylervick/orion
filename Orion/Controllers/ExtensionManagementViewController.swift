//
//  ExtensionManagementViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/10/24.
//

import Cocoa

final class ExtensionManagementViewController: NSViewController {
    @IBOutlet var closeButton: NSButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        print("extension management view loaded")
        print(closeButton)
    }

    @IBAction func closeButtonPressed(_: NSButton) {
        dismiss(self)
    }
}
