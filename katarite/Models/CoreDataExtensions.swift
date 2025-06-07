//
//  CoreDataExtensions.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation
import CoreData

// MARK: - StoryEntity Extensions
extension StoryEntity {
    
    var displayTitle: String {
        return title ?? "Untitled Story"
    }
    
    var displayContent: String {
        return content ?? ""
    }
    
    var displayCharacters: String {
        return characters ?? "Unknown Characters"
    }
    
    var displaySetting: String {
        return setting ?? "Unknown Setting"
    }
    
    var displayMoralMessage: String {
        return moralMessage ?? "No moral message"
    }
    
    var displayAgeGroup: AgeGroup {
        return AgeGroup(rawValue: ageGroup ?? "preschooler") ?? .preschooler
    }
    
    var displayLanguage: Language {
        return Language(rawValue: language ?? "english") ?? .english
    }
    
    var displayStoryLength: StoryLength {
        return StoryLength(rawValue: storyLength ?? "medium") ?? .medium
    }
    
    var displayAIModel: AIModel {
        return AIModel(rawValue: aiModel ?? "deepseek") ?? .deepseek
    }
    
    var formattedCreatedDate: String {
        guard let date = createdDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    var relativeCreatedDate: String {
        guard let date = createdDate else { return "Unknown" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var readingTimeText: String {
        if readingTimeMinutes <= 1 {
            return "1 min read"
        } else {
            return "\(readingTimeMinutes) min read"
        }
    }
    
    var wordCountText: String {
        return "\(wordCount) words"
    }
    
    var hasImage: Bool {
        return imageData != nil
    }
    
    // Convert to our Swift model for easier use in SwiftUI
    func toStoryModel() -> Story {
        return Story(
            id: id ?? UUID(),
            title: displayTitle,
            content: displayContent,
            ageGroup: displayAgeGroup.rawValue,
            language: displayLanguage.rawValue,
            isFavorite: isFavorite,
            createdDate: createdDate ?? Date(),
            modifiedDate: modifiedDate ?? Date(),
            aiModel: displayAIModel.rawValue,
            parameters: StoryParameters(
                ageGroup: displayAgeGroup,
                storyLength: displayStoryLength,
                characters: displayCharacters,
                setting: displaySetting,
                moralMessage: displayMoralMessage,
                language: displayLanguage
            ),
            imageData: imageData
        )
    }
}

// MARK: - UserProfileEntity Extensions
extension UserProfileEntity {
    
    var displayName: String {
        if let childName = childName, !childName.isEmpty {
            return childName
        }
        return "Child"
    }
    
    var displayAppleUserID: String {
        return appleUserID ?? "Unknown User"
    }
    
    var displayPreferredLanguage: Language {
        return Language(rawValue: preferredLanguage ?? "english") ?? .english
    }
    
    var displayDefaultAgeGroup: AgeGroup {
        return AgeGroup(rawValue: defaultAgeGroup ?? "preschooler") ?? .preschooler
    }
    
    var storiesArray: [StoryEntity] {
        let set = stories as? Set<StoryEntity> ?? []
        return set.sorted { 
            ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast)
        }
    }
    
    var favoriteStoriesArray: [StoryEntity] {
        return storiesArray.filter { $0.isFavorite }
    }
    
    var totalStoriesCount: Int {
        return storiesArray.count
    }
    
    var favoriteStoriesCount: Int {
        return favoriteStoriesArray.count
    }
    
    var hasAPIKeys: Bool {
        // API keys are now embedded in the app, always available
        return true
    }
    
    var availableAIModels: [AIModel] {
        // All models are available since API keys are embedded in the app
        return [.deepseek, .gemini]
    }
    
    // Convert to our Swift model for easier use in SwiftUI
    func toUserPreferencesModel() -> UserPreferences {
        let apiKeysModel = APIKeys(
            deepseekKey: "embedded_in_app",
            geminiKey: "embedded_in_app",
            openaiKey: nil // Not using OpenAI currently
        )
        
        return UserPreferences(
            id: id ?? UUID(),
            appleUserID: displayAppleUserID,
            childName: childName,
            preferredLanguage: displayPreferredLanguage,
            defaultAgeGroup: displayDefaultAgeGroup,
            apiKeys: apiKeysModel
        )
    }
}



// MARK: - UsageLimitsEntity Extensions
extension UsageLimitsEntity {
    
    var remainingDailyStories: Int {
        return max(0, Int(dailyStoriesLimit - dailyStoriesUsed))
    }
    
    var usagePercentage: Double {
        guard dailyStoriesLimit > 0 else { return 0.0 }
        return Double(dailyStoriesUsed) / Double(dailyStoriesLimit)
    }
    
    var isAtLimit: Bool {
        return dailyStoriesUsed >= dailyStoriesLimit
    }
    
    var usageText: String {
        return "\(dailyStoriesUsed) of \(dailyStoriesLimit) stories used today"
    }
    
    var needsReset: Bool {
        guard let resetDate = dailyLimitResetDate else { return true }
        return !Calendar.current.isDate(resetDate, inSameDayAs: Date())
    }
    
    var formattedResetDate: String {
        guard let date = dailyLimitResetDate else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - StoryAnalyticsEntity Extensions
extension StoryAnalyticsEntity {
    
    var generationTimeText: String {
        let seconds = Double(generationTimeMs) / 1000.0
        return String(format: "%.1f seconds", seconds)
    }
    
    var displayModelUsed: AIModel {
        return AIModel(rawValue: modelUsed ?? "deepseek") ?? .deepseek
    }
    
    var statusText: String {
        if success {
            if retryAttempts > 0 {
                return "Success (after \(retryAttempts) retries)"
            } else {
                return "Success"
            }
        } else {
            return "Failed"
        }
    }
    
    var formattedTimestamp: String {
        guard let date = timestamp else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - AppSettingsEntity Extensions
extension AppSettingsEntity {
    
    var displayTextSize: String {
        return defaultTextSize ?? "medium"
    }
    
    var displayAppVersion: String {
        return appVersion ?? "1.0"
    }
    
    var formattedLastBackup: String {
        guard let date = lastBackupDate else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
    
    var settingsSummary: String {
        var summary: [String] = []
        
        if isDarkModeEnabled {
            summary.append("Dark Mode")
        }
        
        summary.append("Text: \(displayTextSize.capitalized)")
        
        if enableHapticFeedback {
            summary.append("Haptics")
        }
        
        if enableNotifications {
            summary.append("Notifications")
        }
        
        return summary.joined(separator: " • ")
    }
}

// MARK: - Core Data Properties
extension StoryEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryEntity> {
        return NSFetchRequest<StoryEntity>(entityName: "StoryEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var title: String?
    @NSManaged public var content: String?
    @NSManaged public var ageGroup: String?
    @NSManaged public var language: String?
    @NSManaged public var characters: String?
    @NSManaged public var setting: String?
    @NSManaged public var moralMessage: String?
    @NSManaged public var storyLength: String?
    @NSManaged public var aiModel: String?
    @NSManaged public var isFavorite: Bool
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
    @NSManaged public var wordCount: Int32
    @NSManaged public var readingTimeMinutes: Int32
    @NSManaged public var imageData: Data?
    @NSManaged public var generationParameters: String?
    @NSManaged public var userProfile: UserProfileEntity?
    @NSManaged public var analytics: StoryAnalyticsEntity?
}

extension UserProfileEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UserProfileEntity> {
        return NSFetchRequest<UserProfileEntity>(entityName: "UserProfileEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var appleUserID: String?
    @NSManaged public var childName: String?
    @NSManaged public var preferredLanguage: String?
    @NSManaged public var defaultAgeGroup: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
    @NSManaged public var stories: NSSet?
    @NSManaged public var usageLimits: UsageLimitsEntity?
}

// MARK: Generated accessors for UserProfileEntity.stories
extension UserProfileEntity {

    @objc(addStoriesObject:)
    @NSManaged public func addToStories(_ value: StoryEntity)

    @objc(removeStoriesObject:)
    @NSManaged public func removeFromStories(_ value: StoryEntity)

    @objc(addStories:)
    @NSManaged public func addToStories(_ values: NSSet)

    @objc(removeStories:)
    @NSManaged public func removeFromStories(_ values: NSSet)

}



extension UsageLimitsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<UsageLimitsEntity> {
        return NSFetchRequest<UsageLimitsEntity>(entityName: "UsageLimitsEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var dailyStoriesUsed: Int32
    @NSManaged public var dailyStoriesLimit: Int32
    @NSManaged public var dailyLimitResetDate: Date?
    @NSManaged public var totalStoriesGenerated: Int32
    @NSManaged public var lastResetDate: Date?
    @NSManaged public var userProfile: UserProfileEntity?
}

extension StoryAnalyticsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<StoryAnalyticsEntity> {
        return NSFetchRequest<StoryAnalyticsEntity>(entityName: "StoryAnalyticsEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var generationTimeMs: Int32
    @NSManaged public var modelUsed: String?
    @NSManaged public var success: Bool
    @NSManaged public var errorMessage: String?
    @NSManaged public var retryAttempts: Int32
    @NSManaged public var timestamp: Date?
    @NSManaged public var parametersUsed: String?
    @NSManaged public var story: StoryEntity?
}

extension AppSettingsEntity {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<AppSettingsEntity> {
        return NSFetchRequest<AppSettingsEntity>(entityName: "AppSettingsEntity")
    }
    
    @NSManaged public var id: UUID?
    @NSManaged public var isDarkModeEnabled: Bool
    @NSManaged public var defaultTextSize: String?
    @NSManaged public var enableHapticFeedback: Bool
    @NSManaged public var enableNotifications: Bool
    @NSManaged public var lastBackupDate: Date?
    @NSManaged public var appVersion: String?
    @NSManaged public var createdDate: Date?
    @NSManaged public var modifiedDate: Date?
} 