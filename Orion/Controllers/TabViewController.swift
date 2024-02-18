//
//  TabViewController.swift
//  Orion
//
//  Created by Tyler Vick on 2/17/24.
//

import Cocoa
import Combine
import os.log
import SwiftData
import WebKit

final class TabViewController: NSTabViewController {
    var tabViewModel: TabViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()

        tabStyle = .segmentedControlOnTop

        if tabViewItems.isEmpty {
            createInitialTab()
        }

        tabViewModel.subscribeNewTabAction { [weak self] in
            self?.receiveTabItem($0)
        }
    }

    func createInitialTab() {
        let tabItem = tabViewModel.makeWebViewTab()
        receiveTabItem(tabItem)
    }

    func receiveTabItem(_ tabItem: NSTabViewItem) {
        insertTabViewItem(tabItem, at: 0)
        tabView.selectTabViewItem(tabItem)
    }

    override func tabView(_ tabView: NSTabView, willSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, willSelect: tabViewItem)
        if let tabViewItem {
            tabViewModel.handleTabSwitch(newTabItem: tabViewItem)
        }
    }
}
