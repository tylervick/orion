//
//  WindowController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa
import Combine
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

    private lazy var xpiDownloadManager = XPIDownloadManager()
    private var container: ModelContainer!

    override func windowDidLoad() {
        do {
            let storeUrl = try FileManager.default.url(
                for: .documentDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            )
            .appendingPathComponent("orion.store")
            let configuration = ModelConfiguration(url: storeUrl, allowsSave: true)
            container = try ModelContainer(for: HistoryItem.self, configurations: configuration)
            container.mainContext.autosaveEnabled = true
            let webViewModel = WebViewModel(
                modelContext: container.mainContext,
                xpiDownloadManager: xpiDownloadManager
            )
            contentViewController = WebViewController(viewModel: webViewModel)
        } catch {
            fatalError("Unable to create model container for window: \(error.localizedDescription)")
        }

        bindViewModel()
    }

    private func bindViewModel() {
        if let webViewController {
            webViewController.viewModel?.$urlString
                .receive(on: DispatchQueue.main)
                .sink { [weak self] urlString in
                    print("Setting locationTextField string value to \(urlString)")
                    self?.locationTextField.stringValue = urlString
                }.store(in: &webViewController.cancellables)

            xpiDownloadManager.xpiPublisher
                .compactMap { [weak self] xpiUrl -> WebExtensionViewModel? in
                    guard let self else {
                        return nil
                    }
                    return WebExtensionViewModel(
                        modelContext: container.mainContext,
                        xpiUrl: xpiUrl
                    )
                }.eraseToAnyPublisher()
                .receive(on: DispatchQueue.main).sink { [weak self] vm in
                    if let sb = self?.storyboard {
                        if let vc = sb
                            .instantiateController(
                                withIdentifier: "extensionInstallVC"
                            ) as? ExtensionInstallViewController
                        {
                            vc.viewModel = vm
                            self?.contentViewController?.presentAsSheet(vc)
                        }
                    }
                }.store(in: &webViewController.cancellables)
        }
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
        if let sb = storyboard {
            if let vc = sb
                .instantiateController(
                    withIdentifier: "extensionInstallVC"
                ) as? ExtensionInstallViewController
            {
                contentViewController?.presentAsSheet(vc)
            }
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
