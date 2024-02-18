//
//  WindowController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa
import Combine
import os.log
import SwiftData

final class WindowController: NSWindowController {
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet var backItem: NSToolbarItem!
    @IBOutlet var forwardItem: NSToolbarItem!
    @IBOutlet var locationTextField: NSTextField!

    private var tabViewController: TabViewController? {
        contentViewController as? TabViewController
    }

    private var windowViewModel: WindowViewModel?
    private var cancelBag = Set<AnyCancellable>()

    private func makeContainer() throws -> ModelContainer {
        let storeUrl = try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        ).appendingPathComponent("orion.store")

        let configuration = ModelConfiguration(url: storeUrl, allowsSave: true)
        let container = try ModelContainer(
            for: HistoryItem.self,
            WebExtension.self,
            configurations: configuration
        )
        container.mainContext.autosaveEnabled = true
        return container
    }

    override func windowDidLoad() {
        super.windowDidLoad()

        guard let container = try? makeContainer() else {
            fatalError("Failed to create ModelContainer")
        }
        let logger = Logger()
        let xpiDownloadManager = XPIDownloadManager(logger: logger)
        let windowViewModel = WindowViewModel(
            logger: logger,
            xpiPublisher: xpiDownloadManager.xpiPublisher,
            modelContext: container.mainContext
        )
        self.windowViewModel = windowViewModel

        windowViewModel.subscribeToBrowserActionExtensions(toolbar)
        windowViewModel.subscribeToWebExtensionInstallRequest(self)

        let tabViewModel = TabViewModel(
            logger: logger,
            modelContext: container.mainContext,
            xpiDownloadDelegate: xpiDownloadManager,
            toolbarActionPublisher: windowViewModel.toolbarActionPublisher
        )

        tabViewModel.$canGoBack.link(with: &windowViewModel.$backEnabled)
        tabViewModel.$canGoForward.link(with: &windowViewModel.$forwardEnabled)
        tabViewModel.$activeUrlString.removeDuplicates().receive(on: DispatchQueue.main)
            .sink { [weak self] urlString in
                self?.locationTextField.stringValue = urlString
            }.store(in: &cancelBag)

        if let tabViewController = storyboard?
            .instantiateController(
                withIdentifier: "tabViewController"
            ) as? TabViewController {
            tabViewController.tabViewModel = tabViewModel
            tabViewController.view.setFrameSize(NSSize(width: 1280, height: 720))
            contentViewController = tabViewController
        }
    }

    @IBAction func backButtonClicked(_: NSToolbarItem) {
        windowViewModel?.publishToolbarAction(.back)
    }

    @IBAction func forwardButtonClicked(_: NSToolbarItem) {
        windowViewModel?.publishToolbarAction(.forward)
    }

    @IBAction func reloadButtonClicked(_: NSToolbarItem) {
        windowViewModel?.publishToolbarAction(.reload)
    }

    @IBAction func newTabButtonClicked(_: NSToolbarItem) {
        windowViewModel?.publishToolbarAction(.newTab)
    }

    override func prepare(for segue: NSStoryboardSegue, sender _: Any?) {
        if let webExManagementViewController = segue
            .destinationController as? WebExtManagementViewController {
            webExManagementViewController.viewModel = windowViewModel?
                .makeWebExManagementViewModel()
        }
    }
}

extension WindowController: Subscriber {
    func receive(subscription: Subscription) {
        subscription.request(.max(1))
    }

    func receive(_ viewModel: WebExtInstallViewModel) -> Subscribers.Demand {
        if let vc = storyboard?
            .instantiateController(
                withIdentifier: "extensionInstallVC"
            ) as? WebExtInstallViewController {
            vc.viewModel = viewModel
            contentViewController?.presentAsSheet(vc)
        }
        return .max(1)
    }

    func receive(completion _: Subscribers.Completion<Never>) {}
}

extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item {
        case backItem:
            windowViewModel?.backEnabled ?? false
        case forwardItem:
            windowViewModel?.forwardEnabled ?? false
        default:
            true
        }
    }
}

extension WindowController: NSTextFieldDelegate {
    func control(
        _: NSControl,
        textView _: NSTextView,
        doCommandBy commandSelector: Selector
    ) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            windowViewModel?.publishToolbarAction(.urlSubmitted(locationTextField.stringValue))
            return true
        }
        return false
    }
}
