//
//  UserPreferences.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation

struct UserPreferences: Codable {
    let id: UUID
    let appleUserID: String
    let childName: String?
    let preferredLanguage: Language
    let defaultAgeGroup: AgeGroup
    let apiKeys: APIKeys
    
    init(
        id: UUID = UUID(),
        appleUserID: String,
        childName: String? = nil,
        preferredLanguage: Language = .english,
        defaultAgeGroup: AgeGroup = .preschooler,
        apiKeys: APIKeys = APIKeys()
    ) {
        self.id = id
        self.appleUserID = appleUserID
        self.childName = childName
        self.preferredLanguage = preferredLanguage
        self.defaultAgeGroup = defaultAgeGroup
        self.apiKeys = apiKeys
    }
}

// MARK: - API Keys Management
struct APIKeys: Codable {
    var deepseekKey: String?
    var geminiKey: String?
    var openaiKey: String?
    
    init(
        deepseekKey: String? = nil,
        geminiKey: String? = nil,
        openaiKey: String? = nil
    ) {
        self.deepseekKey = deepseekKey
        self.geminiKey = geminiKey
        self.openaiKey = openaiKey
    }
    
    func hasKey(for model: AIModel) -> Bool {
        switch model {
        case .deepseek:
            return deepseekKey != nil && !deepseekKey!.isEmpty
        case .gemini:
            return geminiKey != nil && !geminiKey!.isEmpty
        }
    }
    
    func getKey(for model: AIModel) -> String? {
        switch model {
        case .deepseek:
            return deepseekKey
        case .gemini:
            return geminiKey
        }
    }
}

// MARK: - UserPreferences Extensions
extension UserPreferences {
    var displayName: String {
        return childName ?? "Child"
    }
    
    var hasValidAPIKeys: Bool {
        return apiKeys.deepseekKey != nil || apiKeys.geminiKey != nil
    }
    
    var availableModels: [AIModel] {
        return AIModel.allCases.filter { apiKeys.hasKey(for: $0) }
    }
} 