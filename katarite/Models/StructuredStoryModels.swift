import Foundation
import UIKit

// MARK: - Structured Content Models

struct StructuredStoryContent: Codable {
    let parts: [StoryPart]
    let images: [StoryImage]
    
    // Extract just the text for backward compatibility
    var plainText: String {
        return parts.compactMap { part in
            if case .text(let text) = part {
                return text
            }
            return nil
        }.joined(separator: "")
    }
    
    // Get first image for legacy imageData compatibility
    var firstImageData: Data? {
        return images.first?.data
    }
}

enum StoryPart: Codable {
    case text(String)
    case image(imageIndex: Int, altText: String)
    
    private enum CodingKeys: String, CodingKey {
        case type, content, imageIndex, altText
    }
    
    enum PartType: String, Codable {
        case text, image
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(PartType.self, forKey: .type)
        
        switch type {
        case .text:
            let content = try container.decode(String.self, forKey: .content)
            self = .text(content)
        case .image:
            let imageIndex = try container.decode(Int.self, forKey: .imageIndex)
            let altText = try container.decode(String.self, forKey: .altText)
            self = .image(imageIndex: imageIndex, altText: altText)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .text(let content):
            try container.encode(PartType.text, forKey: .type)
            try container.encode(content, forKey: .content)
        case .image(let imageIndex, let altText):
            try container.encode(PartType.image, forKey: .type)
            try container.encode(imageIndex, forKey: .imageIndex)
            try container.encode(altText, forKey: .altText)
        }
    }
}

struct StoryResult {
    let structuredContent: StructuredStoryContent
    
    // Backward compatibility properties
    var text: String {
        return structuredContent.plainText
    }
    
    var images: [StoryImage] {
        return structuredContent.images
    }
    
    // Serialize to JSON for Core Data storage
    func toJSON() -> String? {
        do {
            let data = try JSONEncoder().encode(structuredContent)
            return String(data: data, encoding: .utf8)
        } catch {
            print("❌ Failed to serialize structured content: \(error)")
            return nil
        }
    }
    
    // Create from JSON
    static func fromJSON(_ json: String) -> StoryResult? {
        guard let data = json.data(using: .utf8) else { return nil }
        
        do {
            let structuredContent = try JSONDecoder().decode(StructuredStoryContent.self, from: data)
            return StoryResult(structuredContent: structuredContent)
        } catch {
            print("❌ Failed to deserialize structured content: \(error)")
            return nil
        }
    }
}

struct StoryImage: Identifiable, Codable {
    let id: UUID
    let data: Data
    let altText: String
    let index: Int
    
    init(id: UUID = UUID(), data: Data, altText: String, index: Int) {
        self.id = id
        self.data = data
        self.altText = altText
        self.index = index
    }
} 