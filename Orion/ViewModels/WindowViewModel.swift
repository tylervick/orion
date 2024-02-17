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

final class WindowViewModel: NSObject, ObservableObject {
    @Published private var browserActionExtensions: [WebExtensionModel] = []

    private let logger: Logger
    private let xpiPublisher: AnyPublisher<URL, Never>
    private let modelContext: ModelContext

    private var cancelBag = Set<AnyCancellable>()

    private var toolbarMap: [NSToolbarItem.Identifier: NSToolbarItem] = [:]

    init(logger: Logger, xpiPublisher: AnyPublisher<URL, Never>, modelContext: ModelContext) {
        self.logger = logger
        self.xpiPublisher = xpiPublisher
        self.modelContext = modelContext
        super.init()

        loadExtensions()

        $browserActionExtensions.print("Browser Action Extensions").sink(receiveValue: { _ in

        }).store(in: &cancelBag)
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
                toolbar.insertItem(withItemIdentifier: itemIdentifier, at: toolbar.items.count)
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
        popover.contentSize = CGSize(width: 200, height: 200)
        popover.animates = true
        popover.behavior = .semitransient
        if let webExtension = browserActionExtensions.first(where: {
            $0.id == toolbarItem.itemIdentifier.rawValue
        }) {
            let browserActionViewController =
                BrowserActionViewController(webExtension: webExtension)
            popover.contentViewController = browserActionViewController
        }
        popover.show(relativeTo: toolbarItem)

        logger.info("toolbar item clicked: \(toolbarItem.itemIdentifier.rawValue)")
    }
}

final class BrowserActionViewController: NSViewController {
    let webView: WKWebView?
    let webExtension: WebExtensionModel?

    init(webExtension: WebExtensionModel) {
        self.webExtension = webExtension
        webView = WKWebView()
        super.init(nibName: nil, bundle: nil)
        setupWebView()
    }

    required init?(coder: NSCoder) {
        webExtension = nil
        webView = nil
        super.init(coder: coder)
//        fatalError("\(Self.self) must be instantiated directly")
    }

    func setupWebView() {
        guard let webView else {
            return
        }

        webView.frame = view.frame
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.isInspectable = true
        view.addSubview(webView)
        NSLayoutConstraint.activate([
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            webView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            webView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])

        // TODO: render file types other than html
        if let defaultPopup = webExtension?.manifest.browserAction?.defaultPopup,
           let popupUrl = webExtension?.path.appending(path: defaultPopup.path()),
           let htmlContent = try? String(contentsOf: popupUrl)
        {
//            let popupRequest = URLRequest(url: popupUrl)

            webView.loadHTMLString(
                htmlContent,
                baseURL: webExtension!.path.appending(path: "popup")
            )
//            webView.loadFileURL(popupUrl, allowingReadAccessTo: webExtension!.path.appending(path:
//            "popup"))
//            webView.load(popupRequest)
        }
    }
}
