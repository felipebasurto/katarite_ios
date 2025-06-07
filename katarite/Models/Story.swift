//
//  Story.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation

struct Story: Identifiable, Codable {
    let id: UUID
    let title: String
    let content: String
    let ageGroup: String
    let language: String
    let isFavorite: Bool
    let createdDate: Date
    let modifiedDate: Date
    let aiModel: String
    let parameters: StoryParameters
    let imageData: Data?
    
    init(
        id: UUID = UUID(),
        title: String,
        content: String,
        ageGroup: String,
        language: String,
        isFavorite: Bool = false,
        createdDate: Date = Date(),
        modifiedDate: Date = Date(),
        aiModel: String,
        parameters: StoryParameters,
        imageData: Data? = nil
    ) {
        self.id = id
        self.title = title
        self.content = content
        self.ageGroup = ageGroup
        self.language = language
        self.isFavorite = isFavorite
        self.createdDate = createdDate
        self.modifiedDate = modifiedDate
        self.aiModel = aiModel
        self.parameters = parameters
        self.imageData = imageData
    }
}

// MARK: - Story Extensions
extension Story {
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: createdDate)
    }
    
    var ageGroupDisplayName: String {
        switch ageGroup {
        case "toddler":
            return "Toddler (2-3 years)"
        case "preschooler":
            return "Preschooler (4-5 years)"
        case "elementary":
            return "Elementary (6-8 years)"
        default:
            return ageGroup.capitalized
        }
    }
    
    var hasImage: Bool {
        return imageData != nil
    }
} 