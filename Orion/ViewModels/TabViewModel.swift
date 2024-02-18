//
//  TabViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Combine
import os.log
import SwiftData
import WebKit

final class TabViewModel: ObservableObject {
    @Published var activeUrlString = ""
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var activeTitle: String?

    private let logger: Logger
    private let modelContext: ModelContext
    private let xpiDownloadDelegate: WKDownloadDelegate?
    private let toolbarActionPublisher: AnyPublisher<ToolbarAction, Never>

    private var cancelBag = Set<AnyCancellable>()

    private var activeTabCancellable: AnyCancellable?

    init(
        logger: Logger,
        modelContext: ModelContext,
        xpiDownloadDelegate: WKDownloadDelegate?,
        toolbarActionPublisher: AnyPublisher<ToolbarAction, Never>
    ) {
        self.logger = logger
        self.modelContext = modelContext
        self.xpiDownloadDelegate = xpiDownloadDelegate
        self.toolbarActionPublisher = toolbarActionPublisher
    }

    func subscribeNewTabAction(_ onNewTab: @escaping (NSTabViewItem) -> Void) {
        toolbarActionPublisher
            .print()
            .filter {
                $0 == .newTab
            }
            .debounce(for: .seconds(0.5), scheduler: RunLoop.main)
            .receive(on: DispatchQueue.main)
            .map { [weak self] _ in
                self?.makeWebViewTab()
            }
            .compactMap { $0 }
            .sink {
                onNewTab($0)
            }.store(in: &cancelBag)
    }

    func handleTabSwitch(newTabItem: NSTabViewItem) {
        guard let webViewController = newTabItem.viewController as? WebViewController else {
            return
        }

        webViewController.viewModel?.$title.removeDuplicates().assign(to: &$activeTitle)
        webViewController.viewModel?.$urlString.removeDuplicates().assign(to: &$activeUrlString)
        webViewController.viewModel?.$canGoBack.removeDuplicates().assign(to: &$canGoBack)
        webViewController.viewModel?.$canGoForward.removeDuplicates().assign(to: &$canGoForward)

        activeTabCancellable?.cancel()

        activeTabCancellable = toolbarActionPublisher
            .receive(on: DispatchQueue.main)
            .sink {
                switch $0 {
                case .back:
                    webViewController.performBack()
                case .forward:
                    webViewController.performForward()
                case .reload:
                    webViewController.performReload()
                case let .urlSubmitted(urlString):
                    webViewController.loadUrlString(urlString)
                default:
                    break
                }
            }
    }

    func makeWebViewTab() -> NSTabViewItem {
        let webViewModel = WebViewModel(
            logger: logger,
            modelContext: modelContext,
            xpiDownloadManager: xpiDownloadDelegate
        )

        let viewController = WebViewController(viewModel: webViewModel)
        let tabItem = NSTabViewItem(viewController: viewController)

        webViewModel.$title.compactMap { $0 }.sink { title in
            tabItem.label = title
        }.store(in: &cancelBag)
        tabItem.label = webViewModel.title ?? "New Tab"

        return tabItem
    }
}
