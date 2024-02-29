//
//  WebExtManageViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/10/24.
//

import Cocoa
import SwiftData

private extension NSUserInterfaceItemIdentifier {
    static let extensionCollectionViewItem =
        NSUserInterfaceItemIdentifier(rawValue: "WebExtManagementCollectionViewItem")
}

final class WebExtManageViewController: NSViewController {
    @IBOutlet var closeButton: NSButton!
    @IBOutlet var collectionView: NSCollectionView!

    var viewModel: WebExtManageViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: collectionView.frame.width, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView.collectionViewLayout = layout

        collectionView.register(
            WebExtManageCollectionViewItem.self,
            forItemWithIdentifier: .extensionCollectionViewItem
        )
    }

    @IBAction func closeButtonPressed(_: NSButton) {
        dismiss(self)
    }
}

extension WebExtManageViewController: NSCollectionViewDataSource {
    final class UninstallButton: NSButton {
        var webExtension: WebExtension?
    }

    func collectionView(_: NSCollectionView, numberOfItemsInSection _: Int) -> Int {
        viewModel?.extensions.count ?? 0
    }

    func collectionView(
        _ collectionView: NSCollectionView,
        itemForRepresentedObjectAt indexPath: IndexPath
    ) -> NSCollectionViewItem {
        let item = collectionView.makeItem(
            withIdentifier: .extensionCollectionViewItem,
            for: indexPath
        )

        if let data = viewModel?.extensions[indexPath.item] {
            item.representedObject = data

            if let webExtensionMetadataView = item as? WebExtManageCollectionViewItem {
                let uninstallButton = UninstallButton(
                    title: "Uninstall",
                    target: self,
                    action: #selector(uninstallButtonClicked(_:))
                )
                uninstallButton.webExtension = data
                uninstallButton.translatesAutoresizingMaskIntoConstraints = false
                webExtensionMetadataView.view.addSubview(uninstallButton)
                NSLayoutConstraint.activate([
                    uninstallButton.trailingAnchor.constraint(
                        equalTo: webExtensionMetadataView.view.trailingAnchor,
                        constant: -20
                    ),
                    uninstallButton.bottomAnchor.constraint(
                        equalTo: webExtensionMetadataView.view.bottomAnchor,
                        constant: -20
                    ),
                ])
            }
        }

        return item
    }

    @objc func uninstallButtonClicked(_ button: UninstallButton) {
        if let webExtension = button.webExtension {
            viewModel?.uninstallExtension(webExtension)
        }
    }
}

extension WebExtManageViewController: NSCollectionViewDelegate {}
