//
//  WebWindowController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa
import Combine
import os.log
import SwiftData

final class WebWindowController: NSWindowController {
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet var backItem: NSToolbarItem!
    @IBOutlet var forwardItem: NSToolbarItem!
    @IBOutlet var locationTextField: NSTextField!

    private var windowViewModel: WebWindowViewModel?
    private var cancelBag = Set<AnyCancellable>()

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.setAccessibilityIdentifier("webWindow")
        window?.titleVisibility = .hidden

        // Show tab bar by default
        if let tabBarVisible = window?.tabGroup?.isTabBarVisible, !tabBarVisible {
            window?.toggleTabBar(self)
        }

        let logger = Logger()
        let webExtDownloadManager = WebExtDownloadManager(logger: logger)
        let windowViewModel = WebWindowViewModel(
            logger: logger,
            webExtDownloadManager: webExtDownloadManager,
            modelContext: ModelService.shared.context
        )

        windowViewModel.subscribeToBrowserActionExtensions(toolbar)
        windowViewModel.subscribeToWebExtensionInstallRequest(self)
        self.windowViewModel = windowViewModel

        let webViewModel = windowViewModel.makeWebViewModel()

        // observe webview location changes and update the URL bar (locationTextField)
        webViewModel.$urlString.removeDuplicates().receive(on: DispatchQueue.main)
            .sink { [weak self] urlString in
                self?.locationTextField.stringValue = urlString
            }.store(in: &cancelBag)

        // observe document title and set to current window title (aka tab title)
        webViewModel.$title.removeDuplicates().compactMap { $0 }.receive(on: DispatchQueue.main)
            .sink { [weak self] title in
                self?.window?.title = title
            }.store(in: &cancelBag)

        let viewController = WebViewController(
            viewModel: webViewModel,
            actionPublisher: windowViewModel.toolbarActionPublisher
        )
        viewController.view.setFrameSize(NSSize(width: 1280, height: 720))
        contentViewController = viewController
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
        newWindowForTab(self)
    }

    override func newWindowForTab(_: Any?) {
        if let window {
            windowViewModel?.newTab(currentWindow: window)
        }
    }

    override func prepare(for segue: NSStoryboardSegue, sender _: Any?) {
        if let webExManagementViewController = segue
            .destinationController as? WebExtManageViewController
        {
            webExManagementViewController.viewModel = windowViewModel?
                .makeWebExManagementViewModel()
        }
    }
}

extension WebWindowController: Subscriber {
    func receive(subscription: Subscription) {
        subscription.request(.max(1))
    }

    func receive(_ viewModel: WebExtInstallViewModel) -> Subscribers.Demand {
        if let vc = storyboard?
            .instantiateController(
                withIdentifier: "extensionInstallVC"
            ) as? WebExtInstallViewController
        {
            vc.viewModel = viewModel
            contentViewController?.presentAsSheet(vc)
        }
        return .max(1)
    }

    func receive(completion _: Subscribers.Completion<Never>) {}
}

extension WebWindowController: NSToolbarItemValidation {
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

extension WebWindowController: NSTextFieldDelegate {
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
