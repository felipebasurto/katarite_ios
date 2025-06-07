//
//  CoreDataManager.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation
import CoreData
import Combine

@MainActor
class CoreDataManager: ObservableObject {
    static let shared = CoreDataManager()
    
    var context: NSManagedObjectContext {
        PersistenceController.shared.container.viewContext
    }
    
    private init() {}
    
    // MARK: - Save Context
    func save() {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save Core Data context: \(error)")
            }
        }
    }
    
    // MARK: - Story Management
    
    func createStory(
        title: String,
        content: String,
        ageGroup: String,
        language: String,
        characters: String,
        setting: String,
        moralMessage: String,
        storyLength: String,
        aiModel: String,
        imageData: Data? = nil,
        generationParameters: String? = nil,
        userProfile: UserProfileEntity
    ) -> StoryEntity {
        let story = StoryEntity(context: context)
        story.id = UUID()
        story.title = title
        story.content = content
        story.ageGroup = ageGroup
        story.language = language
        story.characters = characters
        story.setting = setting
        story.moralMessage = moralMessage
        story.storyLength = storyLength
        story.aiModel = aiModel
        story.isFavorite = false
        story.createdDate = Date()
        story.modifiedDate = Date()
        story.imageData = imageData
        story.generationParameters = generationParameters
        story.userProfile = userProfile
        
        // Calculate word count and reading time
        story.wordCount = Int32(calculateWordCount(content))
        story.readingTimeMinutes = Int32(calculateReadingTime(wordCount: Int(story.wordCount)))
        
        save()
        return story
    }
    
    func fetchStories(for userProfile: UserProfileEntity) -> [StoryEntity] {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userProfile == %@", userProfile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch stories: \(error)")
            return []
        }
    }
    
    func fetchFavoriteStories(for userProfile: UserProfileEntity) -> [StoryEntity] {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        request.predicate = NSPredicate(format: "userProfile == %@ AND isFavorite == YES", userProfile)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to fetch favorite stories: \(error)")
            return []
        }
    }
    
    func searchStories(for userProfile: UserProfileEntity, searchText: String) -> [StoryEntity] {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "userProfile == %@ AND (title CONTAINS[cd] %@ OR content CONTAINS[cd] %@)",
            userProfile, searchText, searchText
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)]
        
        do {
            return try context.fetch(request)
        } catch {
            print("Failed to search stories: \(error)")
            return []
        }
    }
    
    func toggleFavorite(story: StoryEntity) {
        story.isFavorite.toggle()
        story.modifiedDate = Date()
        save()
    }
    
    func deleteStory(_ story: StoryEntity) {
        context.delete(story)
        save()
    }
    
    // MARK: - User Profile Management
    
    func createUserProfile(
        appleUserID: String,
        childName: String? = nil,
        preferredLanguage: String = "english",
        defaultAgeGroup: String = "preschooler"
    ) -> UserProfileEntity {
        let profile = UserProfileEntity(context: context)
        profile.id = UUID()
        profile.appleUserID = appleUserID
        profile.childName = childName
        profile.preferredLanguage = preferredLanguage
        profile.defaultAgeGroup = defaultAgeGroup
        profile.createdDate = Date()
        profile.modifiedDate = Date()
        
        // Create associated entities
        let usageLimits = createUsageLimits(for: profile)
        
        // API keys are now embedded in the app, no Core Data storage needed
        profile.usageLimits = usageLimits
        
        save()
        return profile
    }
    
    func fetchUserProfile(appleUserID: String) -> UserProfileEntity? {
        let request: NSFetchRequest<UserProfileEntity> = UserProfileEntity.fetchRequest()
        request.predicate = NSPredicate(format: "appleUserID == %@", appleUserID)
        request.fetchLimit = 1
        
        do {
            return try context.fetch(request).first
        } catch {
            print("Failed to fetch user profile: \(error)")
            return nil
        }
    }
    
    func updateUserProfile(
        _ profile: UserProfileEntity,
        childName: String?,
        preferredLanguage: String,
        defaultAgeGroup: String
    ) {
        profile.childName = childName
        profile.preferredLanguage = preferredLanguage
        profile.defaultAgeGroup = defaultAgeGroup
        profile.modifiedDate = Date()
        save()
    }
    
    // MARK: - API Keys Management
    // API keys are now embedded in the app via APIKeyManager, no Core Data storage needed
    
    // MARK: - Usage Limits Management
    
    private func createUsageLimits(for userProfile: UserProfileEntity) -> UsageLimitsEntity {
        let usageLimits = UsageLimitsEntity(context: context)
        usageLimits.id = UUID()
        usageLimits.dailyStoriesUsed = 0
        usageLimits.dailyStoriesLimit = 10
        usageLimits.dailyLimitResetDate = Date()
        usageLimits.totalStoriesGenerated = 0
        usageLimits.lastResetDate = Date()
        usageLimits.userProfile = userProfile
        return usageLimits
    }
    
    func checkAndResetDailyLimits(for userProfile: UserProfileEntity) {
        guard let usageLimits = userProfile.usageLimits else { return }
        
        let calendar = Calendar.current
        let today = Date()
        
        if !calendar.isDate(usageLimits.dailyLimitResetDate!, inSameDayAs: today) {
            usageLimits.dailyStoriesUsed = 0
            usageLimits.dailyLimitResetDate = today
            usageLimits.lastResetDate = today
            save()
        }
    }
    
    func incrementStoryUsage(for userProfile: UserProfileEntity) -> Bool {
        guard let usageLimits = userProfile.usageLimits else { return false }
        
        checkAndResetDailyLimits(for: userProfile)
        
        if usageLimits.dailyStoriesUsed < usageLimits.dailyStoriesLimit {
            usageLimits.dailyStoriesUsed += 1
            usageLimits.totalStoriesGenerated += 1
            save()
            return true
        }
        
        return false
    }
    
    func getRemainingDailyStories(for userProfile: UserProfileEntity) -> Int {
        guard let usageLimits = userProfile.usageLimits else { return 0 }
        
        checkAndResetDailyLimits(for: userProfile)
        
        return max(0, Int(usageLimits.dailyStoriesLimit - usageLimits.dailyStoriesUsed))
    }
    
    // MARK: - Story Analytics
    
    func createStoryAnalytics(
        for story: StoryEntity,
        generationTimeMs: Int32,
        modelUsed: String,
        success: Bool,
        errorMessage: String? = nil,
        retryAttempts: Int32 = 0,
        parametersUsed: String? = nil
    ) -> StoryAnalyticsEntity {
        let analytics = StoryAnalyticsEntity(context: context)
        analytics.id = UUID()
        analytics.generationTimeMs = generationTimeMs
        analytics.modelUsed = modelUsed
        analytics.success = success
        analytics.errorMessage = errorMessage
        analytics.retryAttempts = retryAttempts
        analytics.timestamp = Date()
        analytics.parametersUsed = parametersUsed
        analytics.story = story
        
        save()
        return analytics
    }
    
    // MARK: - App Settings
    
    func getOrCreateAppSettings() -> AppSettingsEntity {
        let request: NSFetchRequest<AppSettingsEntity> = AppSettingsEntity.fetchRequest()
        request.fetchLimit = 1
        
        do {
            if let settings = try context.fetch(request).first {
                return settings
            } else {
                // Create default settings
                let settings = AppSettingsEntity(context: context)
                settings.id = UUID()
                settings.isDarkModeEnabled = false
                settings.defaultTextSize = "medium"
                settings.enableHapticFeedback = true
                settings.enableNotifications = true
                settings.appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
                settings.createdDate = Date()
                settings.modifiedDate = Date()
                
                save()
                return settings
            }
        } catch {
            print("Failed to fetch app settings: \(error)")
            // Return default settings without saving
            let settings = AppSettingsEntity(context: context)
            settings.id = UUID()
            settings.isDarkModeEnabled = false
            settings.defaultTextSize = "medium"
            settings.enableHapticFeedback = true
            settings.enableNotifications = true
            settings.appVersion = "1.0"
            settings.createdDate = Date()
            settings.modifiedDate = Date()
            return settings
        }
    }
    
    func updateAppSettings(_ settings: AppSettingsEntity) {
        settings.modifiedDate = Date()
        save()
    }
    
    // MARK: - Utility Functions
    
    private func calculateWordCount(_ text: String) -> Int {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        return words.filter { !$0.isEmpty }.count
    }
    
    private func calculateReadingTime(wordCount: Int) -> Int {
        // Assuming 200 words per minute reading speed
        return max(1, wordCount / 200)
    }
    
    // MARK: - Story Content Cleanup
    
    /// Clean existing stories to remove title duplication from content
    @MainActor
    func cleanupExistingStories() {
        let request: NSFetchRequest<StoryEntity> = StoryEntity.fetchRequest()
        
        do {
            let allStories = try context.fetch(request)
            var updatedCount = 0
            
            for story in allStories {
                guard let title = story.title,
                      let content = story.content else { continue }
                
                let cleanedContent = cleanStoryContent(from: content, title: title)
                
                // Only update if content actually changed
                if cleanedContent != content {
                    story.content = cleanedContent
                    story.modifiedDate = Date()
                    updatedCount += 1
                }
            }
            
            if updatedCount > 0 {
                save()
                print("✅ Cleaned up \(updatedCount) stories to remove title duplication")
            } else {
                print("ℹ️ No stories needed cleanup")
            }
            
        } catch {
            print("❌ Failed to cleanup existing stories: \(error)")
        }
    }
    
    /// Clean story content by removing title duplication and formatting markers
    private func cleanStoryContent(from content: String, title: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        var foundTitle = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip lines with ** title format
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                foundTitle = true
                continue
            }
            
            // Skip empty lines immediately after title
            if foundTitle && trimmed.isEmpty {
                continue
            }
            
            // Skip lines that exactly match the title
            if trimmed == title {
                foundTitle = true
                continue
            }
            
            // Skip lines that contain the title repeated at the start
            if trimmed.hasPrefix(title) && trimmed.count > title.count {
                let remainingText = trimmed.dropFirst(title.count).trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainingText.isEmpty {
                    cleanedLines.append(remainingText)
                }
                foundTitle = true
                continue
            }
            
            foundTitle = false
            cleanedLines.append(line)
        }
        
        return cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Data Export/Import (for future backup functionality)
    
    func exportUserData(for userProfile: UserProfileEntity) -> [String: Any] {
        let stories = fetchStories(for: userProfile)
        
        return [
            "userProfile": [
                "appleUserID": userProfile.appleUserID ?? "",
                "childName": userProfile.childName ?? "",
                "preferredLanguage": userProfile.preferredLanguage ?? "english",
                "defaultAgeGroup": userProfile.defaultAgeGroup ?? "preschooler",
                "createdDate": userProfile.createdDate ?? Date()
            ],
            "stories": stories.map { story in
                [
                    "title": story.title ?? "",
                    "content": story.content ?? "",
                    "ageGroup": story.ageGroup ?? "",
                    "language": story.language ?? "",
                    "characters": story.characters ?? "",
                    "setting": story.setting ?? "",
                    "moralMessage": story.moralMessage ?? "",
                    "storyLength": story.storyLength ?? "",
                    "aiModel": story.aiModel ?? "",
                    "isFavorite": story.isFavorite,
                    "createdDate": story.createdDate ?? Date(),
                    "wordCount": story.wordCount,
                    "readingTimeMinutes": story.readingTimeMinutes
                ]
            },
            "totalStories": stories.count,
            "favoriteStories": stories.filter { $0.isFavorite }.count
        ]
    }
} 