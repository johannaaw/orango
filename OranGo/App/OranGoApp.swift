//
//  OranGoApp.swift
//  OranGo
//
//  Created by Davin P on 06/08/26.
//

import SwiftUI

@main
struct OranGoApp: App {
    /// Single source of truth for sorting data, shared by every screen.
    @State private var store = SortingStore()

    /// Onboarding runs once; clearing it means deleting the app from the device.
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView()
                    .environment(store)
            } else {
                OnboardingView {
                    hasCompletedOnboarding = true
                }
            }
        }
    }
}
