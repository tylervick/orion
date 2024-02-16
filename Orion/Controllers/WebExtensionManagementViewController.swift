//
//  WebExtensionManagementViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/10/24.
//

import Cocoa

extension NSUserInterfaceItemIdentifier {
    static let extensionCollectionViewItem =
        NSUserInterfaceItemIdentifier(rawValue: "WebExtensionManagementCollectionViewItem")
}

final class WebExtensionManagementCollectionViewItem: NSCollectionViewItem {
    override func loadView() {
        view = WebExtensionMetadataView()
    }

    override var representedObject: Any? {
        didSet {
            if let model = representedObject as? WebExtensionModel {
                (view as? WebExtensionMetadataView)?.manifest = model.manifest
            }
        }
    }
}

final class WebExtensionManagementViewController: NSViewController {
    @IBOutlet var closeButton: NSButton!
    @IBOutlet var collectionView: NSCollectionView!

    var viewModel: WebExtensionManagementViewModel?

    override func viewDidLoad() {
        super.viewDidLoad()
        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: collectionView.frame.width, height: 100)
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10

        collectionView.collectionViewLayout = layout

        collectionView.register(
            WebExtensionManagementCollectionViewItem.self,
            forItemWithIdentifier: .extensionCollectionViewItem
        )
    }

    @IBAction func closeButtonPressed(_: NSButton) {
        dismiss(self)
    }
}

extension WebExtensionManagementViewController: NSCollectionViewDataSource {
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
        }

        return item
    }
}

extension WebExtensionManagementViewController: NSCollectionViewDelegate {}
