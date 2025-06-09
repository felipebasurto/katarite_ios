import SwiftUI
import CoreData

/// Comprehensive user statistics view showing analytics and usage patterns
struct UserStatisticsView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var statistics = UserStatisticsData()
    @State private var isLoading = true
    
    // Core Data fetch request for stories
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)],
        animation: .default)
    private var stories: FetchedResults<StoryEntity>
    
    // Core Data fetch request for user profiles
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfileEntity.createdDate, ascending: true)],
        animation: .default)
    private var userProfiles: FetchedResults<UserProfileEntity>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if isLoading {
                    ProgressView("Loading statistics...")
                        .frame(maxWidth: .infinity, maxHeight: 200)
                } else {
                    // Overview Stats
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Total Stories", value: "\(statistics.totalStories)", icon: "book.fill", color: .blue)
                        StatCard(title: "Favorites", value: "\(statistics.favoriteStories)", icon: "heart.fill", color: .red)
                        StatCard(title: "Images Created", value: "\(statistics.totalImagesGenerated)", icon: "photo.fill", color: .green)
                        StatCard(title: "Avg. Words", value: "\(statistics.averageWordsPerStory)", icon: "textformat", color: .orange)
                    }
                    .padding(.horizontal)
                    
                    // Language Distribution
                    if !statistics.storiesByLanguage.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Stories by Language")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            ForEach(Array(statistics.storiesByLanguage.keys.sorted()), id: \.self) { language in
                                if let count = statistics.storiesByLanguage[language] {
                                    StatBreakdownRow(
                                        title: language.capitalized,
                                        count: count,
                                        total: statistics.totalStories,
                                        color: language == "english" ? .blue : .purple
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // AI Model Usage
                    if !statistics.storiesByAIModel.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("AI Model Usage")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            ForEach(Array(statistics.storiesByAIModel.keys.sorted()), id: \.self) { model in
                                if let count = statistics.storiesByAIModel[model] {
                                    StatBreakdownRow(
                                        title: model == "deepseek" ? "DeepSeek" : "Gemini",
                                        count: count,
                                        total: statistics.totalStories,
                                        color: model == "deepseek" ? .green : .orange
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Age Group Distribution
                    if !statistics.storiesByAgeGroup.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Stories by Age Group")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            ForEach(Array(statistics.storiesByAgeGroup.keys.sorted()), id: \.self) { ageGroup in
                                if let count = statistics.storiesByAgeGroup[ageGroup] {
                                    StatBreakdownRow(
                                        title: ageGroup.capitalized,
                                        count: count,
                                        total: statistics.totalStories,
                                        color: .indigo
                                    )
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Activity Timeline
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Activity")
                                .font(.headline)
                            Spacer()
                        }
                        
                        if statistics.lastStoryDate.isEmpty {
                            Text("No stories created yet")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Image(systemName: "clock")
                                        .foregroundColor(.secondary)
                                    Text("Last story: \(statistics.lastStoryDate)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack {
                                    Image(systemName: "calendar")
                                        .foregroundColor(.secondary)
                                    Text("Member since: \(statistics.accountCreationDate)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                if !statistics.mostUsedStoryLength.isEmpty {
                                    HStack {
                                        Image(systemName: "doc.text")
                                            .foregroundColor(.secondary)
                                        Text("Preferred length: \(statistics.mostUsedStoryLength)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
        }
        .navigationTitle("Statistics")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadStatistics()
        }
        .onAppear {
            Task {
                await loadStatistics()
            }
        }
        .onChange(of: stories.count) { _, _ in
            Task {
                await loadStatistics()
            }
        }
    }
    
    @MainActor
    private func loadStatistics() async {
        isLoading = true
        
        // Calculate statistics from Core Data
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let storiesArray = Array(stories)
                let userProfilesArray = Array(userProfiles)
                
                let newStatistics = calculateStatistics(
                    from: storiesArray,
                    userProfiles: userProfilesArray
                )
                
                DispatchQueue.main.async {
                    self.statistics = newStatistics
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
    
    private func calculateStatistics(from stories: [StoryEntity], userProfiles: [UserProfileEntity]) -> UserStatisticsData {
        var stats = UserStatisticsData()
        
        // Basic counts
        stats.totalStories = stories.count
        stats.favoriteStories = stories.filter { $0.isFavorite }.count
        stats.totalImagesGenerated = stories.filter { $0.hasImage }.count
        
        // Calculate average word count
        let totalWords = stories.reduce(0) { sum, story in
            sum + Int(story.wordCount)
        }
        stats.averageWordsPerStory = stories.count > 0 ? totalWords / stories.count : 0
        
        // Group by language
        stats.storiesByLanguage = Dictionary(grouping: stories, by: { $0.language ?? "unknown" })
            .mapValues { $0.count }
        
        // Group by AI model
        stats.storiesByAIModel = Dictionary(grouping: stories, by: { $0.aiModel ?? "unknown" })
            .mapValues { $0.count }
        
        // Group by age group
        stats.storiesByAgeGroup = Dictionary(grouping: stories, by: { $0.ageGroup ?? "unknown" })
            .mapValues { $0.count }
        
        // Find most used story length
        let lengthCounts = Dictionary(grouping: stories, by: { $0.storyLength ?? "medium" })
            .mapValues { $0.count }
        stats.mostUsedStoryLength = lengthCounts.max(by: { $0.value < $1.value })?.key ?? "medium"
        
        // Format dates
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let lastStory = stories.first {
            stats.lastStoryDate = dateFormatter.string(from: lastStory.createdDate ?? Date())
        }
        
        if let userProfile = userProfiles.first {
            stats.accountCreationDate = dateFormatter.string(from: userProfile.createdDate ?? Date())
        } else {
            stats.accountCreationDate = dateFormatter.string(from: Date())
        }
        
        return stats
    }
}

/// Simple statistics card component
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

/// Statistics breakdown row with progress bar
struct StatBreakdownRow: View {
    let title: String
    let count: Int
    let total: Int
    let color: Color
    
    private var percentage: Double {
        total > 0 ? Double(count) / Double(total) : 0
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.subheadline)
                Spacer()
                Text("\(count)")
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: color))
                .scaleEffect(y: 0.8)
        }
    }
}

/// Enhanced statistics data model with real data
struct UserStatisticsData {
    var totalStories: Int = 0
    var favoriteStories: Int = 0
    var totalImagesGenerated: Int = 0
    var averageWordsPerStory: Int = 0
    var storiesByLanguage: [String: Int] = [:]
    var storiesByAIModel: [String: Int] = [:]
    var storiesByAgeGroup: [String: Int] = [:]
    var mostUsedStoryLength: String = ""
    var accountCreationDate: String = ""
    var lastStoryDate: String = ""
}

#Preview {
    NavigationView {
        UserStatisticsView()
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 