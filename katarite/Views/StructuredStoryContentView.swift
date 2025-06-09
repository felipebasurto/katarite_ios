import SwiftUI

/// SwiftUI view that renders structured story content with properly positioned images
struct StructuredStoryContentView: View {
    let structuredContent: StructuredStoryContent
    let fontSize: CGFloat
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 20) {
            ForEach(0..<structuredContent.parts.count, id: \.self) { index in
                let part = structuredContent.parts[index]
                
                switch part {
                case .text(let text):
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        Text(text)
                            .font(.system(size: fontSize, weight: .regular, design: .serif))
                            .lineSpacing(fontSize * 0.3)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                    }
                    
                case .image(let imageIndex, let altText):
                    if imageIndex < structuredContent.images.count {
                        let storyImage = structuredContent.images[imageIndex]
                        
                        VStack(spacing: 12) {
                            if let uiImage = UIImage(data: storyImage.data) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(maxHeight: 300)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                                    .padding(.horizontal, 20)
                                    .accessibilityLabel(altText)
                            } else {
                                // Fallback for corrupted image data
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(height: 200)
                                    .overlay(
                                        VStack {
                                            Image(systemName: "photo")
                                                .font(.largeTitle)
                                                .foregroundColor(.gray)
                                            Text("Image unavailable")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                    )
                                    .padding(.horizontal, 20)
                            }
                            
                            // Image caption - removed generic captions for cleaner look
                            // Images are now contextually positioned within the story flow
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

/// Legacy story content view for backward compatibility
struct LegacyStoryContentView: View {
    let content: String
    let fontSize: CGFloat
    
    var body: some View {
        Text(content)
            .font(.system(size: fontSize, weight: .regular, design: .serif))
            .lineSpacing(fontSize * 0.3)
            .foregroundColor(.primary)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
    }
}

#Preview {
    let sampleImages = [
        StoryImage(data: Data(), altText: "A magical forest scene", index: 0),
        StoryImage(data: Data(), altText: "The great discovery", index: 1),
        StoryImage(data: Data(), altText: "A happy ending", index: 2)
    ]
    
    let sampleParts: [StoryPart] = [
        .text("**The Magical Forest Adventure**\n\nOnce upon a time, in a magical forest filled with talking animals and glowing flowers, there lived a brave little rabbit named Luna."),
        .image(imageIndex: 0, altText: "A magical forest scene"),
        .text("Luna had the most beautiful silver fur that shimmered in the moonlight, and eyes that sparkled like stars. Every day, Luna would hop through the forest, making friends with all the creatures she met."),
        .image(imageIndex: 1, altText: "The great discovery"),
        .text("One day, Luna discovered something wonderful. When she helped others, her fur would glow even brighter, and she felt a warm happiness spreading through her heart. She learned that the greatest magic of all was kindness."),
        .image(imageIndex: 2, altText: "A happy ending"),
        .text("From that day forward, Luna made sure to spread kindness wherever she went, and the forest became an even more magical place because of her caring heart.")
    ]
    
    let structuredContent = StructuredStoryContent(parts: sampleParts, images: sampleImages)
    
    return ScrollView {
        StructuredStoryContentView(structuredContent: structuredContent, fontSize: 18)
    }
    .background(Color(.systemBackground))
} 