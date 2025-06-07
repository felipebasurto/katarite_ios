import SwiftUI
import CoreData

/// Individual story card component for displaying stories in grid or list format
struct StoryCard: View {
    let story: StoryEntity
    let viewMode: MyStoriesView.ViewMode
    let onTap: () -> Void
    let onFavorite: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    // Format the creation date
    private var formattedDate: String {
        guard let createdAt = story.createdDate else { return "Unknown" }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: createdAt)
    }
    
    // Get age group for display
    private var ageGroupDisplay: String {
        return story.ageGroup ?? "All Ages"
    }
    
    // Get language for display
    private var languageDisplay: String {
        let language = story.language ?? "english"
        return language == "english" ? "🇺🇸" : "🇪🇸"
    }
    
    // Get story length for display
    private var storyLengthDisplay: String {
        return story.storyLength ?? "Medium"
    }
    
    // Get truncated content preview
    private var contentPreview: String {
        let content = story.content ?? "No content available"
        
        let maxLength = viewMode == .grid ? 80 : 120
        if content.count > maxLength {
            return String(content.prefix(maxLength)) + "..."
        }
        return content
    }
    
    var body: some View {
        Button(action: onTap) {
            if viewMode == .grid {
                gridCardView
            } else {
                listCardView
            }
        }
        .buttonStyle(PlainButtonStyle())
        .contextMenu {
            contextMenuItems
        }
        .alert("Delete Story", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Are you sure you want to delete '\(story.title ?? "this story")'? This action cannot be undone.")
        }
    }
    
    // MARK: - Grid Card View
    private var gridCardView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail/Header Section
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.7),
                                Color.pink.opacity(0.7),
                                Color.blue.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 100)
                
                VStack(spacing: 8) {
                    Image(systemName: "book.closed")
                        .font(.title)
                        .foregroundColor(.white)
                    
                    Text(languageDisplay)
                        .font(.title2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, corners: [.topLeft, .topRight]))
            
            // Content Section
            VStack(alignment: .leading, spacing: 8) {
                // Title with enhanced styling
                Text(story.title ?? "Untitled Story")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.primary,
                                Color.primary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                // Content Preview
                Text(contentPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                
                Spacer()
                
                // Tags and Info
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        TagView(text: ageGroupDisplay, color: .blue)
                        TagView(text: storyLengthDisplay, color: .green)
                        Spacer()
                    }
                    
                    // Date and Favorite
                    HStack {
                        Text(formattedDate)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if story.isFavorite {
                            Image(systemName: "heart.fill")
                                .font(.caption)
                                .foregroundColor(.pink)
                        }
                    }
                }
            }
            .padding(12)
        }
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - List Card View
    private var listCardView: some View {
        HStack(spacing: 12) {
            // Thumbnail
            ZStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.purple.opacity(0.7),
                                Color.pink.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                
                VStack(spacing: 2) {
                    Image(systemName: "book.closed")
                        .font(.subheadline)
                        .foregroundColor(.white)
                    
                    Text(languageDisplay)
                        .font(.caption2)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8))
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                // Title and Favorite
                HStack {
                    Text(story.title ?? "Untitled Story")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [
                                    Color.primary,
                                    Color.primary.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if story.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.subheadline)
                            .foregroundColor(.pink)
                    }
                }
                
                // Content preview
                Text(contentPreview)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                // Tags and date
                HStack {
                    TagView(text: ageGroupDisplay, color: .blue)
                    TagView(text: storyLengthDisplay, color: .green)
                    
                    Spacer()
                    
                    Text(formattedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Action buttons for list view
            VStack(spacing: 8) {
                Button(action: onFavorite) {
                    Image(systemName: story.isFavorite ? "heart.fill" : "heart")
                        .font(.subheadline)
                        .foregroundColor(story.isFavorite ? .pink : .secondary)
                }
                
                Button(action: { showingDeleteAlert = true }) {
                    Image(systemName: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                }
            }
            .padding(.trailing, 4)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
    
    // MARK: - Context Menu Items
    private var contextMenuItems: some View {
        Group {
            Button(action: onTap) {
                Label("Open Story", systemImage: "book.open")
            }
            
            Button(action: onFavorite) {
                Label(
                    story.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                    systemImage: story.isFavorite ? "heart.slash" : "heart"
                )
            }
            
            Divider()
            
            Button(action: { showingDeleteAlert = true }) {
                Label("Delete Story", systemImage: "trash")
            }
            .foregroundColor(.red)
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
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundColor(color.opacity(0.8))
            .clipShape(Capsule())
    }
}

// MARK: - Custom Corner Radius
extension RoundedRectangle {
    init(cornerRadius: CGFloat, corners: UIRectCorner) {
        self.init(cornerRadius: cornerRadius)
    }
}

// MARK: - Preview
struct StoryCard_Previews: PreviewProvider {
    static var previews: some View {
        let sampleStory = createSampleStory()
        
        Group {
            // Grid view
            StoryCard(
                story: sampleStory,
                viewMode: .grid,
                onTap: {},
                onFavorite: {},
                onDelete: {}
            )
            .frame(width: 200)
            .previewDisplayName("Grid Card")
            
            // List view
            StoryCard(
                story: sampleStory,
                viewMode: .list,
                onTap: {},
                onFavorite: {},
                onDelete: {}
            )
            .previewDisplayName("List Card")
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
    
    static func createSampleStory() -> StoryEntity {
        let context = PersistenceController.preview.container.viewContext
        let sampleStory = StoryEntity(context: context)
        sampleStory.title = "The Magical Forest Adventure"
        sampleStory.content = "Once upon a time, in a magical forest filled with talking animals and glowing flowers, there lived a brave little rabbit named Luna who discovered that friendship was the greatest treasure of all."
        sampleStory.createdDate = Date()
        sampleStory.ageGroup = "Preschooler"
        sampleStory.language = "english"
        sampleStory.storyLength = "Medium"
        sampleStory.isFavorite = true
        return sampleStory
    }
} 