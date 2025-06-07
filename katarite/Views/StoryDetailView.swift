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
        ScrollViewReader { proxy in
            ScrollView {
                if isLoading {
                    // Loading state
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.2)
                            .progressViewStyle(CircularProgressViewStyle(tint: .accentColor))
                        
                        Text("Loading story...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.top, 100)
                } else {
                    VStack(alignment: .leading, spacing: 24) {
                        // Story metadata
                        storyMetadataView
                            .opacity(hasAppeared ? 1 : 0)
                            .animation(.easeInOut(duration: 0.5).delay(0.1), value: hasAppeared)
                        
                        // Story title with beautiful styling
                        ZStack {
                            // Background gradient for title
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.purple.opacity(0.8),
                                            Color.pink.opacity(0.6),
                                            Color.blue.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                            
                            VStack(spacing: 8) {
                                Text(story.title ?? "Untitled Story")
                                    .font(.system(size: 28, weight: .heavy, design: .rounded))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.white, .white.opacity(0.9)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .multilineTextAlignment(.center)
                                    .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                                
                                // Decorative elements
                                HStack(spacing: 8) {
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Rectangle()
                                        .frame(width: 40, height: 2)
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Image(systemName: "book.closed")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                    
                                    Rectangle()
                                        .frame(width: 40, height: 2)
                                        .foregroundColor(.white.opacity(0.6))
                                    
                                    Image(systemName: "sparkles")
                                        .font(.caption)
                                        .foregroundColor(.white.opacity(0.8))
                                }
                            }
                            .padding(.vertical, 24)
                            .padding(.horizontal, 20)
                        }
                        .id("story-title")
                        .opacity(hasAppeared ? 1 : 0)
                        .animation(.easeInOut(duration: 0.5).delay(0.2), value: hasAppeared)
                        
                        // Story content
                        Text(story.content ?? "")
                            .font(.system(size: fontSize, weight: .regular, design: .serif))
                            .lineSpacing(fontSize * 0.3)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.bottom, 40)
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
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .background(
                        GeometryReader { scrollGeometry in
                            Color.clear
                                .preference(
                                    key: ScrollOffsetPreferenceKey.self,
                                    value: scrollGeometry.frame(in: .named("scroll")).minY
                                )
                        }
                    )
                }
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                // Throttle scroll updates for better performance
                if !isLoading {
                    updateReadingProgress(scrollOffset: value)
                }
            }
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
    
    private func updateReadingProgress(scrollOffset: CGFloat) {
        guard totalContentHeight > 0 else { return }
        
        let visibleHeight = UIScreen.main.bounds.height - 200 // Account for header and safe areas
        let maxScrollOffset = totalContentHeight - visibleHeight
        
        if maxScrollOffset > 0 {
            let progress = min(max(0, -scrollOffset / maxScrollOffset), 1)
            readingProgress = progress
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