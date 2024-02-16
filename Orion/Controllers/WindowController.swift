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

    private var webViewController: WebViewController? {
        contentViewController as? WebViewController
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
            WebExtensionModel.self,
            configurations: configuration
        )
        container.mainContext.autosaveEnabled = true
        return container
    }

    override func windowDidLoad() {
        guard let container = try? makeContainer() else {
            fatalError("Failed to create ModelContainer")
        }
        let logger = Logger()
        let xpiDownloadManager = XPIDownloadManager(logger: logger)
        windowViewModel = WindowViewModel(
            logger: logger,
            xpiPublisher: xpiDownloadManager.xpiPublisher,
            modelContext: container.mainContext
        )
        let webViewModel = WebViewModel(
            modelContext: container.mainContext,
            xpiDownloadManager: xpiDownloadManager
        )
        contentViewController = WebViewController(viewModel: webViewModel)
        toolbar.insertItem(
            withItemIdentifier: NSToolbarItem.Identifier(rawValue: "Test"),
            at: toolbar.items.count
        )

        windowViewModel?.subscribeToWebExtension(self)
//        windowViewModel?.subscribeToWebExtension()
        bindViewModel()
    }

    private func setupContentView() {}

    private func bindViewModel() {
        webViewController?.viewModel?.$urlString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlString in
                print("Setting locationTextField string value to \(urlString)")
                self?.locationTextField.stringValue = urlString
            }
            .store(in: &cancelBag)

//        xpiDownloadManager.xpiPublisher
//            .compactMap { [weak self] xpiUrl -> WebExtensionViewModel? in
//                guard let self else {
//                    return nil
//                }
//                return try? WebExtensionViewModel(
//                    modelContext: container.mainContext,
//                    xpiUrl: xpiUrl,
//                    logger: logger
//                )
//            }
//            .eraseToAnyPublisher()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] vm in
//                if let vc = self?.storyboard?
//                    .instantiateController(
//                        withIdentifier: "extensionInstallVC"
//                    ) as? WebExtensionInstallViewController
//                {
//                    vc.viewModel = vm
//                    self?.contentViewController?.presentAsSheet(vc)
//                }
//            }
//            .store(in: &cancelBag)
    }

    @IBAction func backButtonClicked(_: NSToolbarItem) {
        webViewController?.performBack()
    }

    @IBAction func forwardButtonClicked(_: NSToolbarItem) {
        webViewController?.performForward()
    }

    @IBAction func reloadButtonClicked(_: NSToolbarItem) {
        webViewController?.performReload()
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        if let webExManagementViewController = segue.destinationController as? WebExtensionManagementViewController {
            webExManagementViewController.viewModel = windowViewModel?.makeWebExManagementViewModel()
        }
    }
}

extension WindowController: Subscriber {
    func receive(subscription: Subscription) {
        subscription.store(in: &cancelBag)
    }
    
    func receive(_ viewModel: WebExtensionViewModel) -> Subscribers.Demand {
        if let vc = self.storyboard?.instantiateController(withIdentifier: "extensionInstallVC") as? WebExtensionInstallViewController {
            vc.viewModel = viewModel
            contentViewController?.presentAsSheet(vc)
        }
        return .max(1)
    }
    
    func receive(completion: Subscribers.Completion<Never>) {
        
    }
}

extension WindowController: NSToolbarDelegate {
    func toolbar(
        _: NSToolbar,
        itemForItemIdentifier _: NSToolbarItem.Identifier,
        willBeInsertedIntoToolbar _: Bool
    ) -> NSToolbarItem? {
        print("Test2")
        return nil
    }
}

extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item {
        case backItem:
            webViewController?.viewModel?.canGoBack ?? false
        case forwardItem:
            webViewController?.viewModel?.canGoForward ?? false
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
            webViewController?.loadUrlString(locationTextField.stringValue)
            return true
        }
        return false
    }
}
