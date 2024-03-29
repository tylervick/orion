//
//  WebWindowViewModel.swift
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

enum WebWindowToolbarAction: Equatable {
    case back
    case forward
    case reload
    case newTab
    case urlSubmitted(String)
}

final class WebWindowViewModel: NSObject, ObservableObject {
    @Published private var browserActionExtensions: [WebExtension] = []

    @Published var backEnabled = false
    @Published var forwardEnabled = false
    @Published var title: String? = nil

    private let logger: Logger
    private let webExtDownloadManager: WebExtDownloadManager
    private let modelContext: ModelContext

    private var cancelBag = Set<AnyCancellable>()
    private var toolbarMap: [NSToolbarItem.Identifier: NSToolbarItem] = [:]

    private let toolbarActionSubject = PassthroughSubject<WebWindowToolbarAction, Never>()
    var toolbarActionPublisher: AnyPublisher<WebWindowToolbarAction, Never> {
        toolbarActionSubject.eraseToAnyPublisher()
    }

    init(logger: Logger, webExtDownloadManager: WebExtDownloadManager, modelContext: ModelContext) {
        self.logger = logger
        self.webExtDownloadManager = webExtDownloadManager
        self.modelContext = modelContext
        super.init()

        NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange)
            .sink { [weak self] _ in
                self?.loadExtensions()
            }
            .store(in: &cancelBag)
        loadExtensions()
    }

    func makeWebViewModel() -> WebViewModel {
        let webViewModel = WebViewModel(
            logger: logger,
            modelContext: modelContext,
            xpiDownloadManager: webExtDownloadManager
        )
        webViewModel.$canGoBack.removeDuplicates().assign(to: &$backEnabled)
        webViewModel.$canGoForward.removeDuplicates().assign(to: &$forwardEnabled)
        webViewModel.$title.removeDuplicates().assign(to: &$title)

        return webViewModel
    }

    // Creates a new instance of WebWindowController to be added as a new "tab" in the supplied window
    func newTab(currentWindow: NSWindow) {
        let sb = NSStoryboard(name: "Main", bundle: nil)

        guard let newController = sb.instantiateInitialController() as? WebWindowController,
              let newWindow = newController.window
        else {
            return
        }

        currentWindow.addTabbedWindow(newWindow, ordered: .above)
        newWindow.makeKeyAndOrderFront(currentWindow)
    }

    func publishToolbarAction(_ action: WebWindowToolbarAction) {
        toolbarActionSubject.send(action)
    }

    private func loadExtensions() {
        let hasBrowserAction = #Predicate<WebExtension> {
            $0.manifest.browserAction != nil
        }
        let fd = FetchDescriptor<WebExtension>(predicate: hasBrowserAction)

        do {
            browserActionExtensions = try modelContext.fetch(fd)
        } catch {
            logger.error("failed to fetch browser action extensions: \(error.localizedDescription)")
        }
    }

    func subscribeToWebExtensionInstallRequest(_ subscriber: any Subscriber<
        WebExtInstallViewModel,
        Never
    >) {
        webExtDownloadManager.xpiPublisher
            .compactMap { [weak self] xpiUrl -> WebExtInstallViewModel? in
                guard let self else {
                    return nil
                }
                return try? WebExtInstallViewModel(
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
        $browserActionExtensions.removeDuplicates().receive(on: DispatchQueue.main)
            .sink { [weak self] models in

                modelLoop: for model in models {
                    let itemIdentifier = NSToolbarItem.Identifier(rawValue: model.id)

                    // Don't insert existing extension IDs
                    // The better way is to subscribe to individual models and CRUD them without
                    // re-creating everything
                    for item in toolbar.items {
                        if item.itemIdentifier == itemIdentifier {
                            continue modelLoop
                        }
                    }

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
                    let insertIndex = toolbar.items.count > 2 ? toolbar.items.count - 2 : toolbar
                        .items
                        .count

                    if !toolbar.items.contains(toolbarItem) {
                        toolbar.insertItem(withItemIdentifier: itemIdentifier, at: insertIndex)
                        self?.logger.info("Inserted item into toolbar: \(model.id)")
                    }
                }
            }.store(in: &cancelBag)
    }

    func makeWebExManagementViewModel() -> WebExtManageViewModel {
        WebExtManageViewModel(modelContext: modelContext, logger: logger)
    }
}

extension WebWindowViewModel: NSToolbarDelegate {
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
            let browserActionViewModel = BrowserActionViewModel(
                logger: logger,
                modelContext: modelContext,
                webExtension: webExtension
            )
            let browserActionViewController =
                BrowserActionViewController(viewModel: browserActionViewModel)
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
