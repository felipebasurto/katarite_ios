//
//  Persistence.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    @MainActor
    static let preview: PersistenceController = {
        // Use shared instance in production to avoid model conflicts
        #if DEBUG
        let result = PersistenceController(inMemory: true)
        let viewContext = result.container.viewContext
        
        // Create sample data for previews
        let sampleProfile = UserProfileEntity(context: viewContext)
        sampleProfile.id = UUID()
        sampleProfile.appleUserID = "sample_user_123"
        sampleProfile.childName = "Emma"
        sampleProfile.preferredLanguage = "english"
        sampleProfile.defaultAgeGroup = "preschooler"
        sampleProfile.createdDate = Date()
        sampleProfile.modifiedDate = Date()
        
        // API keys are now embedded in the app, no longer stored in Core Data
        
        // Create sample usage limits
        let usageLimits = UsageLimitsEntity(context: viewContext)
        usageLimits.id = UUID()
        usageLimits.dailyStoriesUsed = 3
        usageLimits.dailyStoriesLimit = 10
        usageLimits.dailyLimitResetDate = Date()
        usageLimits.totalStoriesGenerated = 15
        usageLimits.lastResetDate = Date()
        usageLimits.userProfile = sampleProfile
        sampleProfile.usageLimits = usageLimits
        
        // Create sample stories
        for i in 0..<5 {
            let story = StoryEntity(context: viewContext)
            story.id = UUID()
            story.title = "The Adventure of Luna the Cat \(i + 1)"
            story.content = "Once upon a time, in a magical forest, there lived a curious little cat named Luna. She loved to explore and discover new things every day. One sunny morning, Luna decided to venture deeper into the forest than she had ever gone before..."
            story.ageGroup = "preschooler"
            story.language = "english"
            story.characters = "Luna the Cat, Forest Animals"
            story.setting = "Magical Forest"
            story.moralMessage = "Curiosity and kindness lead to wonderful adventures"
            story.storyLength = "medium"
            story.aiModel = "deepseek"
            story.isFavorite = i % 2 == 0
            story.createdDate = Date().addingTimeInterval(-Double(i * 86400)) // Different days
            story.modifiedDate = story.createdDate
            story.wordCount = 150 + Int32(i * 25)
            story.readingTimeMinutes = 1 + Int32(i / 2)
            story.userProfile = sampleProfile
            
            // Create analytics for the story
            let analytics = StoryAnalyticsEntity(context: viewContext)
            analytics.id = UUID()
            analytics.generationTimeMs = 2500 + Int32(i * 200)
            analytics.modelUsed = "deepseek"
            analytics.success = true
            analytics.retryAttempts = 0
            analytics.timestamp = story.createdDate
            analytics.parametersUsed = "temperature: 0.7, max_tokens: 500"
            analytics.story = story
            story.analytics = analytics
        }
        
        // Create app settings
        let appSettings = AppSettingsEntity(context: viewContext)
        appSettings.id = UUID()
        appSettings.isDarkModeEnabled = false
        appSettings.defaultTextSize = "medium"
        appSettings.enableHapticFeedback = true
        appSettings.enableNotifications = true
        appSettings.appVersion = "1.0.0"
        appSettings.createdDate = Date()
        appSettings.modifiedDate = Date()
        
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
        #else
        return shared
        #endif
    }()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "katarite")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        
        // Enable persistent history tracking for better data synchronization
        container.persistentStoreDescriptions.forEach { storeDescription in
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            storeDescription.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        
        // Configure merge policy for better conflict resolution
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
}
