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

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
