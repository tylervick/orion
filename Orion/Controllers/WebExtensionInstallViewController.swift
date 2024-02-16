//
//  WebExtensionInstallViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Cocoa
import os.log

final class WebExtensionInstallViewController: NSViewController {
    @IBOutlet var metadataContainerView: NSView!

    var viewModel: WebExtensionViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        guard let manifest = viewModel?.manifest else {
            dismiss(self)
            return
        }
        let extensionMetadataView = WebExtensionMetadataView(
            frame: metadataContainerView.frame,
            manifest: manifest
        )
        extensionMetadataView.translatesAutoresizingMaskIntoConstraints = false
        metadataContainerView.addSubview(extensionMetadataView)

        NSLayoutConstraint.activate([
            extensionMetadataView.leadingAnchor
                .constraint(equalTo: metadataContainerView.leadingAnchor),
            extensionMetadataView.trailingAnchor
                .constraint(equalTo: metadataContainerView.trailingAnchor),
            extensionMetadataView.topAnchor
                .constraint(equalTo: metadataContainerView.topAnchor),
            extensionMetadataView.bottomAnchor
                .constraint(equalTo: metadataContainerView.bottomAnchor),
        ])
    }

    @IBAction func cancelButtonClicked(_: NSButton) {
        dismiss(self)
    }

    @IBAction func installButtonClicked(_: NSButton) {
        do {
            try viewModel?.installExtension()
        } catch {
            // show alert here
            Logger().error("Failed to install extension: \(error.localizedDescription)")
        }
        dismiss(self)
    }
}
