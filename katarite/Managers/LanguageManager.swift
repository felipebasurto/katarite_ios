import Foundation
import SwiftUI

/// Manages language detection and user language preferences
class LanguageManager: ObservableObject {
    
    // MARK: - Singleton
    static let shared = LanguageManager()
    
    // MARK: - Published Properties
    @Published var currentLanguage: AppLanguage = .english
    
    // MARK: - Constants
    private let languageKey = "user_selected_language"
    
    // MARK: - Supported Languages
    enum AppLanguage: String, CaseIterable {
        case english = "en"
        case spanish = "es"
        
        var displayName: String {
            switch self {
            case .english:
                return "English"
            case .spanish:
                return "Español"
            }
        }
        
        var localizedDisplayName: String {
            switch self {
            case .english:
                return NSLocalizedString("language.english", value: "English", comment: "English language name")
            case .spanish:
                return NSLocalizedString("language.spanish", value: "Español", comment: "Spanish language name")
            }
        }
        
        var storyGenerationCode: String {
            switch self {
            case .english:
                return "english"
            case .spanish:
                return "spanish"
            }
        }
        
        var toStoryLanguage: StoryLanguage {
            switch self {
            case .english:
                return .english
            case .spanish:
                return .spanish
            }
        }
    }
    
    // MARK: - Initialization
    private init() {
        self.currentLanguage = loadSavedLanguage() ?? detectDeviceLanguage()
        print("🌍 LanguageManager initialized with language: \(currentLanguage.displayName)")
    }
    
    // MARK: - Public Methods
    
    /// Set the app language manually (from settings)
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        saveLanguage(language)
        print("🌍 Language manually set to: \(language.displayName)")
    }
    
    /// Reset to device language
    func resetToDeviceLanguage() {
        let deviceLanguage = detectDeviceLanguage()
        setLanguage(deviceLanguage)
        print("🌍 Language reset to device default: \(deviceLanguage.displayName)")
    }
    
    /// Get localized string for current language
    func localizedString(for key: String, defaultValue: String = "") -> String {
        return NSLocalizedString(key, value: defaultValue, comment: "")
    }
    
    // MARK: - Private Methods
    
    /// Detect language based on device locale
    private func detectDeviceLanguage() -> AppLanguage {
        let deviceLanguageCode = Locale.current.language.languageCode?.identifier ?? "en"
        print("🌍 Device language code detected: \(deviceLanguageCode)")
        
        // Check for Spanish variants
        if deviceLanguageCode.hasPrefix("es") {
            return .spanish
        }
        
        // Check for specific Spanish-speaking regions
        let regionCode = Locale.current.region?.identifier ?? ""
        let spanishRegions = ["MX", "ES", "AR", "CO", "PE", "VE", "CL", "EC", "GT", "CU", "BO", "DO", "HN", "PY", "SV", "NI", "CR", "PA", "UY", "GQ"]
        
        if spanishRegions.contains(regionCode) {
            print("🌍 Spanish-speaking region detected: \(regionCode)")
            return .spanish
        }
        
        // Default to English for all other cases
        return .english
    }
    
    /// Load saved language preference
    private func loadSavedLanguage() -> AppLanguage? {
        guard let savedLanguageString = UserDefaults.standard.string(forKey: languageKey),
              let savedLanguage = AppLanguage(rawValue: savedLanguageString) else {
            print("🌍 No saved language preference found")
            return nil
        }
        
        print("🌍 Loaded saved language: \(savedLanguage.displayName)")
        return savedLanguage
    }
    
    /// Save language preference
    private func saveLanguage(_ language: AppLanguage) {
        UserDefaults.standard.set(language.rawValue, forKey: languageKey)
        print("🌍 Language preference saved: \(language.displayName)")
    }
}

// MARK: - Convenience Extensions

extension LanguageManager {
    
    /// Quick access to current language code for API calls
    var currentLanguageCode: String {
        return currentLanguage.storyGenerationCode
    }
    
    /// Check if current language is Spanish
    var isSpanish: Bool {
        return currentLanguage == .spanish
    }
    
    /// Check if current language is English
    var isEnglish: Bool {
        return currentLanguage == .english
    }
}

// MARK: - SwiftUI Environment Integration

struct LanguageEnvironmentKey: EnvironmentKey {
    static let defaultValue: LanguageManager = LanguageManager.shared
}

extension EnvironmentValues {
    var languageManager: LanguageManager {
        get { self[LanguageEnvironmentKey.self] }
        set { self[LanguageEnvironmentKey.self] = newValue }
    }
} 