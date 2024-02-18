//
//  WindowViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/15/24.
//

import Cocoa
import Combine
import Foundation
import os.log
import SwiftData
import WebKit

enum ToolbarAction: Equatable {
    case back
    case forward
    case reload
    case newTab
    case urlSubmitted(String)
}

final class WindowViewModel: NSObject, ObservableObject {
    @Published private var browserActionExtensions: [WebExtensionModel] = []

    @Published var backEnabled = false
    @Published var forwardEnabled = false

    private let logger: Logger
    private let xpiPublisher: AnyPublisher<URL, Never>
    private let modelContext: ModelContext
    private let toolbarActionSubject = PassthroughSubject<ToolbarAction, Never>()

    private var cancelBag = Set<AnyCancellable>()
    private var toolbarMap: [NSToolbarItem.Identifier: NSToolbarItem] = [:]

    var toolbarActionPublisher: AnyPublisher<ToolbarAction, Never> {
        toolbarActionSubject.eraseToAnyPublisher()
    }

    init(logger: Logger, xpiPublisher: AnyPublisher<URL, Never>, modelContext: ModelContext) {
        self.logger = logger
        self.xpiPublisher = xpiPublisher
        self.modelContext = modelContext
        super.init()

        loadExtensions()
    }

    func publishToolbarAction(_ action: ToolbarAction) {
        toolbarActionSubject.send(action)
    }

    private func loadExtensions() {
        let hasBrowserAction = #Predicate<WebExtensionModel> {
            $0.manifest.browserAction != nil
        }
        let fd = FetchDescriptor<WebExtensionModel>(predicate: hasBrowserAction)

        do {
            browserActionExtensions = try modelContext.fetch(fd)
        } catch {
            logger.error("failed to fetch browser action extensions: \(error.localizedDescription)")
        }
    }

    func subscribeToWebExtensionInstallRequest(_ subscriber: any Subscriber<
        WebExtensionInstallViewModel,
        Never
    >) {
        xpiPublisher.compactMap { [weak self] xpiUrl -> WebExtensionInstallViewModel? in
            guard let self else {
                return nil
            }
            return try? WebExtensionInstallViewModel(
                modelContext: modelContext,
                xpiUrl: xpiUrl,
                logger: logger
            )
        }
        .receive(on: DispatchQueue.main)
        .subscribe(subscriber)
    }

    func subscribeToBrowserActionExtensions(_ toolbar: NSToolbar) {
        toolbar.delegate = self
        $browserActionExtensions.receive(on: DispatchQueue.main).sink { [weak self] models in
            for model in models {
                let itemIdentifier = NSToolbarItem.Identifier(rawValue: model.id)

                let toolbarItem = NSToolbarItem(itemIdentifier: itemIdentifier)
                toolbarItem.label = model.manifest.name
                toolbarItem.paletteLabel = model.manifest.name
                toolbarItem.target = self
                toolbarItem.action = #selector(self?.browserActionExtensionClicked(_:))

                if
                    let filteredKeys = model.manifest.icons?.keys.compactMap({ Int($0) })
                    .filter({ $0 <= 64 }),
                    let maxKey = filteredKeys.max(),
                    let iconPath = model.manifest.icons?[String(maxKey)]
                {
                    let imageUrl = model.path.appending(path: iconPath.path())
                    let image = NSImage(contentsOf: imageUrl)
                    image?.size = CGSize(width: 20, height: 20)
                    toolbarItem.image = image
                }

                self?.toolbarMap[itemIdentifier] = toolbarItem

                self?.logger.info("Created toolbar item for extension: \(model.id)")
                let insertIndex = toolbar.items.count > 2 ? toolbar.items.count - 2 : toolbar.items
                    .count
                toolbar.insertItem(withItemIdentifier: itemIdentifier, at: insertIndex)
                self?.logger.info("Inserted item into toolbar: \(model.id)")
            }
        }.store(in: &cancelBag)
    }

    func makeWebExManagementViewModel() -> WebExtensionManagementViewModel {
        WebExtensionManagementViewModel(modelContext: modelContext, logger: logger)
    }
}

extension WindowViewModel: NSToolbarDelegate {
    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier itemIdentifier: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        toolbarMap[itemIdentifier]
    }

    @objc func browserActionExtensionClicked(_ toolbarItem: NSToolbarItem) {
        let popover = NSPopover()
        popover.contentSize = CGSize(width: 400, height: 600)
        popover.animates = true
        popover.behavior = .semitransient
        if let webExtension = browserActionExtensions.first(where: {
            $0.id == toolbarItem.itemIdentifier.rawValue
        }) {
            let browserActionViewController = BrowserActionViewController(
                logger: logger,
                modelContext: modelContext,
                webExtension: webExtension
            )
            popover.contentViewController = browserActionViewController
        }
        popover.show(relativeTo: toolbarItem)
    }
}

extension Published.Publisher where Value: Equatable {
    mutating func link(with other: inout Self) {
        removeDuplicates().assign(to: &other)
        other.removeDuplicates().assign(to: &self)
    }
}
