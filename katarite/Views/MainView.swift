import SwiftUI

/// Main navigation view that handles tab-based navigation in the app
struct MainView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    @State private var selectedTab = 0
    @State private var hasPerformedCleanup = false
    
    // Observable object to handle tab switching from anywhere in the app
    @StateObject private var tabSwitcher = TabSwitcher()
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView(selection: $tabSwitcher.selectedTab) {
                    // Story Creation Tab
                    NavigationView {
                        ContentView()
                    }
                    .environmentObject(tabSwitcher)
                    .tabItem {
                        Image(systemName: "wand.and.stars")
                        Text("Create Story")
                    }
                    .tag(0)
                    
                    // My Stories Tab
                    NavigationView {
                        MyStoriesView(selectedTab: $tabSwitcher.selectedTab)
                    }
                    .environmentObject(tabSwitcher)
                    .tabItem {
                        Image(systemName: "book.fill")
                        Text("My Stories")
                    }
                    .tag(1)
                }
                .accentColor(.purple)
                .onAppear {
                    // Perform one-time cleanup of existing stories when app loads
                    if !hasPerformedCleanup {
                        hasPerformedCleanup = true
                        Task {
                            CoreDataManager.shared.cleanupExistingStories()
                        }
                    }
                }
            } else {
                AuthenticationView()
            }
        }
    }
}

#Preview {
    MainView()
        .environmentObject(AuthenticationManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 