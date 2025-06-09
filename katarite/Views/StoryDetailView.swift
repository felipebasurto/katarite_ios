import SwiftUI
import CoreData

struct StoryDetailView: View {
    let story: StoryEntity
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.dismiss) private var dismiss
    @State private var fontSize: CGFloat = 18
    @State private var showingShareSheet = false
    @State private var readingProgress: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var totalContentHeight: CGFloat = 0
    @State private var isLoading = true
    @State private var hasAppeared = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Header with progress
                    headerView
                    
                    // Story content
                    storyContentView
                }
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [story.title ?? "Story", story.content ?? ""])
        }
        .onAppear {
            if !hasAppeared {
                hasAppeared = true
                // Small delay to ensure smooth transition
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isLoading = false
                    }
                }
            }
        }
    }
    
    // MARK: - Header View
    private var headerView: some View {
        VStack(spacing: 12) {
            // Navigation and actions
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.title2)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Action buttons
                HStack(spacing: 12) {
                    // Font size button
                    Menu {
                        Button("Small (14pt)") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontSize = 14
                            }
                        }
                        
                        Button("Medium (16pt)") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontSize = 16
                            }
                        }
                        
                        Button("Large (18pt)") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontSize = 18
                            }
                        }
                        
                        Button("Extra Large (20pt)") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontSize = 20
                            }
                        }
                        
                        Button("Huge (22pt)") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontSize = 22
                            }
                        }
                        
                        Button("Maximum (24pt)") {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                fontSize = 24
                            }
                        }
                    } label: {
                        Image(systemName: "textformat.size")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    
                    // Favorite button
                    Button(action: toggleFavorite) {
                        Image(systemName: story.isFavorite ? "heart.fill" : "heart")
                            .font(.title2)
                            .foregroundColor(story.isFavorite ? .pink : .primary)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                    
                    // Share button
                    Button(action: { showingShareSheet = true }) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.title2)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .clipShape(Circle())
                    }
                }
            }
            .padding(.horizontal)
            
            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color(.systemGray5))
                        .frame(height: 3)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: geometry.size.width * readingProgress, height: 3)
                }
            }
            .frame(height: 3)
            .padding(.horizontal)
        }
        .padding(.top, 8)
        .background(Color(.systemBackground).opacity(0.95))
    }
    
    // MARK: - Story Content View
    private var storyContentView: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Story content with structured layout
                    if let structuredContent = CoreDataManager.shared.getStructuredContent(from: story) {
                        StructuredStoryContentView(
                            structuredContent: structuredContent.structuredContent,
                            fontSize: fontSize
                        )
                    } else {
                        // Fallback to legacy content display
                        LegacyStoryContentView(
                            content: story.content ?? "",
                            fontSize: fontSize
                        )
                    }
                }
                .opacity(hasAppeared ? 1 : 0)
                .animation(.easeInOut(duration: 0.5).delay(0.3), value: hasAppeared)
                .background(
                    GeometryReader { contentGeometry in
                        Color.clear
                            .onAppear {
                                // Debounce content height updates
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    totalContentHeight = contentGeometry.size.height
                                }
                            }
                            .onChange(of: fontSize) { oldValue, newValue in
                                // Update height when font size changes
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    totalContentHeight = contentGeometry.size.height
                                }
                            }
                    }
                )
            }
            .background(Color.clear)
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
                
                // Calculate reading progress
                let maxOffset = max(0, totalContentHeight - geometry.size.height)
                if maxOffset > 0 {
                    readingProgress = min(1.0, max(0, -value / maxOffset))
                }
            }
            .overlay(
                // Invisible scroll tracking view
                GeometryReader { proxy in
                    Color.clear
                        .preference(
                            key: ScrollOffsetPreferenceKey.self,
                            value: proxy.frame(in: .named("scroll")).minY
                        )
                }
            )
            .coordinateSpace(name: "scroll")
        }
    }
    
    // MARK: - Story Metadata View
    private var storyMetadataView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date and reading info
            HStack {
                Text(formattedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text(estimatedReadingTime)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Tags
            HStack(spacing: 8) {
                if let ageGroup = story.ageGroup {
                    TagView(text: ageGroup, color: .blue)
                }
                
                if let storyLength = story.storyLength {
                    TagView(text: storyLength, color: .green)
                }
                
                if let language = story.language {
                    TagView(text: language.capitalized, color: .purple)
                }
                
                Spacer()
            }
        }
    }
    
    // MARK: - Computed Properties
    private var formattedDate: String {
        guard let date = story.createdDate else { return "Unknown date" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private var estimatedReadingTime: String {
        guard let content = story.content else { return "0 min read" }
        let wordCount = content.split(separator: " ").count
        let readingTime = max(1, wordCount / 200) // Average reading speed: 200 words per minute
        return "\(readingTime) min read"
    }
    
    // MARK: - Actions
    private func toggleFavorite() {
        withAnimation(.easeInOut(duration: 0.2)) {
            story.isFavorite.toggle()
        }
        
        do {
            try viewContext.save()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
}

// MARK: - Tag View Component
private struct TagView: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color.opacity(0.8))
            .clipShape(Capsule())
    }
}

// MARK: - Scroll Offset Preference Key
struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

// MARK: - Preview
struct StoryDetailView_Previews: PreviewProvider {
    static var previews: some View {
        let context = PersistenceController.preview.container.viewContext
        let sampleStory = StoryEntity(context: context)
        sampleStory.title = "The Magical Forest Adventure"
        sampleStory.content = """
        Once upon a time, in a magical forest filled with talking animals and glowing flowers, there lived a brave little rabbit named Luna. Luna had the most beautiful silver fur that shimmered in the moonlight, and eyes that sparkled like stars.
        
        Every day, Luna would hop through the forest, making friends with all the creatures she met. There was Oliver the wise old owl, who knew stories about every tree in the forest. There was Bella the butterfly, whose wings were painted with all the colors of the rainbow. And there was Max the friendly bear, who was always ready to help anyone in need.
        
        One day, Luna discovered something wonderful. When she helped others, her fur would glow even brighter, and she felt a warm happiness spreading through her heart. She learned that the greatest magic of all was kindness, and that friendship was the most precious treasure in the entire forest.
        
        From that day forward, Luna made sure to spread kindness wherever she went, and the forest became an even more magical place because of her caring heart.
        """
        sampleStory.createdDate = Date()
        sampleStory.ageGroup = "Preschooler"
        sampleStory.language = "english"
        sampleStory.storyLength = "Medium"
        sampleStory.isFavorite = false
        
        return StoryDetailView(story: sampleStory)
            .environment(\.managedObjectContext, context)
    }
} 