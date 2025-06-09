import SwiftUI
import Combine

/// Observable object to handle tab switching from anywhere in the app
class TabSwitcher: ObservableObject {
    @Published var selectedTab: Int = 0
    
    /// Switch to the Create Story tab
    func switchToCreateStory() {
        selectedTab = 0
    }
    
    /// Switch to the My Stories tab
    func switchToMyStories() {
        selectedTab = 1
    }
    
    /// Switch to the Profile tab
    func switchToProfile() {
        selectedTab = 2
    }
} 