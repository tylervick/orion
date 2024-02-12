//
//  ExtensionManagementViewModel.swift
//  Orion
//
//  Created by Tyler Vick on 2/11/24.
//

import Foundation
import SwiftData

final class ExtensionManagementViewModel: ObservableObject {
    let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

//    func unpackExtension(path _: URL) -> WebExtensionMetadata {}

//    func installExtension(_ extension: WebExtensionModel) {
//
//    }

    func uninstallExtension(_: WebExtensionModel) {}
}
