//
//  WindowViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/15/24.
//

import Combine
import Foundation
import os.log
import SwiftData

final class WindowViewModel: ObservableObject {
    private let logger: Logger
    private let xpiPublisher: AnyPublisher<URL, Never>
    private let modelContext: ModelContext

    init(logger: Logger, xpiPublisher: AnyPublisher<URL, Never>, modelContext: ModelContext) {
        self.logger = logger
        self.xpiPublisher = xpiPublisher
        self.modelContext = modelContext
    }

    func subscribeToWebExtension(_ subscriber: any Subscriber<WebExtensionViewModel, Never>) {
        xpiPublisher.compactMap { [weak self] xpiUrl -> WebExtensionViewModel? in
            guard let self else {
                return nil
            }
            return try? WebExtensionViewModel(
                modelContext: modelContext,
                xpiUrl: xpiUrl,
                logger: logger
            )
        }
        .receive(on: DispatchQueue.main)
        .subscribe(subscriber)
    }

    func makeWebExManagementViewModel() -> WebExtensionManagementViewModel {
        WebExtensionManagementViewModel(modelContext: modelContext, logger: logger)
    }
}
