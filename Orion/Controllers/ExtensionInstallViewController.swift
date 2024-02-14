//
//  ExtensionInstallViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Cocoa

final class ExtensionInstallViewController: NSViewController {
    @IBOutlet var extensionMetadataContainerView: NSView!

    var viewModel: WebExtensionViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let manifest = viewModel?.manifest else {
            dismiss(self)
            return
        }
        let extensionMetadataView = ExtensionMetadataView(
            frame: extensionMetadataContainerView.frame,
            metadata: manifest
        )
        extensionMetadataView.translatesAutoresizingMaskIntoConstraints = false
        extensionMetadataContainerView.addSubview(extensionMetadataView)

        NSLayoutConstraint.activate([
            extensionMetadataView.leadingAnchor
                .constraint(equalTo: extensionMetadataContainerView.leadingAnchor),
            extensionMetadataView.trailingAnchor
                .constraint(equalTo: extensionMetadataContainerView.trailingAnchor),
            extensionMetadataView.topAnchor
                .constraint(equalTo: extensionMetadataContainerView.topAnchor),
            extensionMetadataView.bottomAnchor
                .constraint(equalTo: extensionMetadataContainerView.bottomAnchor),
        ])
    }

    @IBAction func cancelButtonClicked(_: NSButton) {
        dismiss(self)
    }

    @IBAction func installButtonClicked(_: NSButton) {
        dismiss(self)
    }
}
