import SwiftUI

// Add the AppLanguage typealias for easier reference
typealias AppLanguage = LanguageManager.AppLanguage

/// Focused app settings view for core preferences and defaults
struct AppSettingsView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @Environment(\.colorScheme) private var colorScheme
    
    // State for preferences - simplified further
    @State private var selectedStoryLength: StoryLength = .medium
    @State private var selectedAgeGroup: AgeGroup = .preschooler
    
    var body: some View {
        NavigationView {
            Form {
                storyGenerationSection
                resetSection
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .onAppear {
            loadPreferences()
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("App Settings")
    }
    
    // MARK: - UI Sections
    private var storyGenerationSection: some View {
        Section {
            // Language Selection
            HStack {
                Text("Language")
                    .foregroundColor(.primary)
                Spacer()
                Picker("Language", selection: Binding(
                    get: { languageManager.currentLanguage },
                    set: { newLanguage in
                        languageManager.setLanguage(newLanguage)
                        savePreferences()
                    }
                )) {
                    ForEach(AppLanguage.allCases, id: \.self) { language in
                        Text(language.displayName).tag(language)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.purple)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Language selection: \(languageManager.currentLanguage.displayName)")
            
            // Story Length
            HStack {
                Text("Default Story Length")
                    .foregroundColor(.primary)
                Spacer()
                Picker("Story Length", selection: $selectedStoryLength) {
                    ForEach(StoryLength.allCases, id: \.self) { length in
                        Text(length.displayName).tag(length)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.purple)
                .onChange(of: selectedStoryLength) { _, newValue in
                    savePreferences()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Default story length: \(selectedStoryLength.displayName)")
            
            // Age Group
            HStack {
                Text("Default Age Group")
                    .foregroundColor(.primary)
                Spacer()
                Picker("Age Group", selection: $selectedAgeGroup) {
                    ForEach(AgeGroup.allCases, id: \.self) { group in
                        Text(group.displayName).tag(group)
                    }
                }
                .pickerStyle(MenuPickerStyle())
                .tint(.purple)
                .onChange(of: selectedAgeGroup) { _, newValue in
                    savePreferences()
                }
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Default age group: \(selectedAgeGroup.displayName)")
            
        } header: {
            Text("Story Defaults")
                .accessibilityAddTraits(.isHeader)
        } footer: {
            Text("These settings will be used as defaults when creating new stories. Text size can be adjusted while reading stories.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var resetSection: some View {
        Section {
            Button(action: resetToDefaults) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                        .foregroundColor(.red)
                        .accessibilityHidden(true)
                    Text("Reset to Defaults")
                        .foregroundColor(.red)
                }
            }
            .accessibilityLabel("Reset all settings to default values")
            .accessibilityHint("This will restore all preferences to their original settings")
        } footer: {
            Text("This will reset all preferences to their default values.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Data Management
    private func loadPreferences() {
        // Load story length
        if let lengthRaw = UserDefaults.standard.object(forKey: "defaultStoryLength") as? String,
           let length = StoryLength.allCases.first(where: { $0.rawValue == lengthRaw }) {
            selectedStoryLength = length
        }
        
        // Load age group
        if let groupRaw = UserDefaults.standard.object(forKey: "defaultAgeGroup") as? String,
           let group = AgeGroup.allCases.first(where: { $0.rawValue == groupRaw }) {
            selectedAgeGroup = group
        }
    }
    
    private func savePreferences() {
        UserDefaults.standard.set(selectedStoryLength.rawValue, forKey: "defaultStoryLength")
        UserDefaults.standard.set(selectedAgeGroup.rawValue, forKey: "defaultAgeGroup")
    }
    
    private func resetToDefaults() {
        selectedStoryLength = .medium
        selectedAgeGroup = .preschooler
        languageManager.setLanguage(.english)
        
        // Clear UserDefaults
        UserDefaults.standard.removeObject(forKey: "defaultStoryLength")
        UserDefaults.standard.removeObject(forKey: "defaultAgeGroup")
        
        // Note: Text size is now handled in StoryReaderView, so no global reset needed
        
        print("Settings reset to defaults")
    }
}

#Preview {
    AppSettingsView()
} 