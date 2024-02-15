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
    @IBOutlet var reloadItem: NSToolbarItem!
    @IBOutlet var locationTextField: NSTextField!
    @IBOutlet var extensionItem: NSToolbarItem!

    private var webViewController: WebViewController? {
        contentViewController as? WebViewController
    }

    private lazy var logger = Logger()
    private lazy var xpiDownloadManager = XPIDownloadManager(logger: logger)

    private var cancelBag = Set<AnyCancellable>()

    private let container: ModelContainer = {
        do {
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
        } catch {
            fatalError("Unable to configure SwiftData storage: \(error.localizedDescription)")
        }
    }()

    override func windowDidLoad() {
        let webViewModel = WebViewModel(
            modelContext: container.mainContext,
            xpiDownloadManager: xpiDownloadManager
        )
        contentViewController = WebViewController(viewModel: webViewModel)

        bindViewModel()
    }

    private func bindViewModel() {
        webViewController?.viewModel?.$urlString
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urlString in
                print("Setting locationTextField string value to \(urlString)")
                self?.locationTextField.stringValue = urlString
            }
            .store(in: &cancelBag)

        xpiDownloadManager.xpiPublisher
            .compactMap { [weak self] xpiUrl -> WebExtensionViewModel? in
                guard let self else {
                    return nil
                }
                return try? WebExtensionViewModel(
                    modelContext: container.mainContext,
                    xpiUrl: xpiUrl,
                    logger: logger
                )
            }
            .eraseToAnyPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] vm in
                if let vc = self?.storyboard?
                    .instantiateController(
                        withIdentifier: "extensionInstallVC"
                    ) as? WebExtensionInstallViewController
                {
                    vc.viewModel = vm
                    self?.contentViewController?.presentAsSheet(vc)
                }
            }
            .store(in: &cancelBag)
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

    @IBAction func extensionButtonClicked(_: NSToolbarItem) {
        if let vc = storyboard?
            .instantiateController(
                withIdentifier: "extensionManagementVC"
            ) as? WebExtensionManagementViewController
        {
            vc.viewModel = WebExtensionManagementViewModel(
                modelContext: container.mainContext,
                logger: logger
            )
            contentViewController?.presentAsSheet(vc)
        }
    }
}

extension WindowController: NSToolbarDelegate {}

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
