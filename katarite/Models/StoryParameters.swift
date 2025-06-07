//
//  StoryParameters.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation

struct StoryParameters: Codable {
    let ageGroup: AgeGroup
    let storyLength: StoryLength
    let characters: String
    let setting: String
    let moralMessage: String
    let language: Language
    
    init(
        ageGroup: AgeGroup,
        storyLength: StoryLength,
        characters: String,
        setting: String,
        moralMessage: String,
        language: Language
    ) {
        self.ageGroup = ageGroup
        self.storyLength = storyLength
        self.characters = characters
        self.setting = setting
        self.moralMessage = moralMessage
        self.language = language
    }
}

// MARK: - Supporting Enums
enum AgeGroup: String, CaseIterable, Codable {
    case toddler = "toddler"
    case preschooler = "preschooler"
    case elementary = "elementary"
    
    var displayName: String {
        switch self {
        case .toddler:
            return "Toddler (2-3 years)"
        case .preschooler:
            return "Preschooler (4-5 years)"
        case .elementary:
            return "Elementary (6-8 years)"
        }
    }
    
    var description: String {
        switch self {
        case .toddler:
            return "Simple stories with basic concepts"
        case .preschooler:
            return "Stories with simple lessons and adventures"
        case .elementary:
            return "More complex stories with deeper themes"
        }
    }
}

enum StoryLength: String, CaseIterable, Codable {
    case short = "short"
    case medium = "medium"
    case long = "long"
    
    var displayName: String {
        switch self {
        case .short:
            return "Short (2-3 minutes)"
        case .medium:
            return "Medium (5-7 minutes)"
        case .long:
            return "Long (10-12 minutes)"
        }
    }
    
    var wordCount: Int {
        switch self {
        case .short:
            return 200
        case .medium:
            return 500
        case .long:
            return 800
        }
    }
}

enum Language: String, CaseIterable, Codable {
    case english = "en"
    case spanish = "es"
    
    var displayName: String {
        switch self {
        case .english:
            return "English"
        case .spanish:
            return "Español"
        }
    }
    
    var flag: String {
        switch self {
        case .english:
            return "🇺🇸"
        case .spanish:
            return "🇪🇸"
        }
    }
}

enum AIModel: String, CaseIterable, Codable {
    case deepseek = "deepseek"
    case gemini = "gemini"
    
    var displayName: String {
        switch self {
        case .deepseek:
            return "DeepSeek (Text Only)"
        case .gemini:
            return "Gemini (Text + Images)"
        }
    }
    
    var supportsImages: Bool {
        switch self {
        case .deepseek:
            return false
        case .gemini:
            return true
        }
    }
} 