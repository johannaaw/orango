//
//  OranGoApp.swift
//  OranGo
//
//  Created by Davin P on 06/08/26.
//

import SwiftUI

@main
struct OranGoApp: App {
    @State private var store = SortingStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(store)
        }
    }
}
