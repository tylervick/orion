//
//  WindowController.swift
//  Orion
//
//  Created by Tyler Vick on 2/6/24.
//

import Cocoa

final class WindowController: NSWindowController {
    @IBOutlet var toolbar: NSToolbar!
    @IBOutlet var backItem: NSToolbarItem!
    @IBOutlet var forwardItem: NSToolbarItem!
    @IBOutlet var reloadItem: NSToolbarItem!
    @IBOutlet var locationTextField: NSTextField!

    weak var toolbarDelegate: ToolbarDelegate?

    override func windowDidLoad() {
        toolbarDelegate = contentViewController as? ToolbarDelegate
        bindViewModel()
    }

    private func bindViewModel() {
        if let toolbarDelegate {
            toolbarDelegate.viewModel.$urlString
                .receive(on: DispatchQueue.main)
                .sink { [weak self] urlString in
                    print("Setting locationTextField string value to \(urlString)")
                    self?.locationTextField.stringValue = urlString
                }.store(in: &toolbarDelegate.cancellables)
        }
    }

    @IBAction func backButtonClicked(_: NSToolbarItem) {
        toolbarDelegate?.performBack()
    }

    @IBAction func forwardButtonClicked(_: NSToolbarItem) {
        toolbarDelegate?.performForward()
    }

    @IBAction func reloadButtonClicked(_: NSToolbarItem) {
        print("Reload button clicked")
        toolbarDelegate?.performReload()
    }
}

extension WindowController: NSToolbarDelegate {}

extension WindowController: NSToolbarItemValidation {
    func validateToolbarItem(_ item: NSToolbarItem) -> Bool {
        switch item {
        case backItem:
            toolbarDelegate?.viewModel.canGoBack ?? false
        case forwardItem:
            toolbarDelegate?.viewModel.canGoForward ?? false
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
            toolbarDelegate?.loadUrlString(locationTextField.stringValue)
            return true
        }
        return false
    }
}
