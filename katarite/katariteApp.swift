//
//  katariteApp.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import SwiftUI

@main
struct katariteApp: App {
    let persistenceController = PersistenceController.shared
    @StateObject private var authManager = AuthenticationManager()

    init() {
        #if DEBUG
        // API keys are embedded and encrypted in the app
        print("🔐 Katarite: Using embedded API keys for secure operation")
        #endif
    }

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authManager)
        }
    }
}
