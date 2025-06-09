import Foundation
import UIKit

/// Direct Gemini API service for text + image generation for iOS
/// Uses gemini-2.0-flash-preview-image-generation model
/// Single call, no retries - if it fails, it fails
@MainActor
class GeminiService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = GeminiService()
    private init() {}
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var error: String?
    @Published var generatedText = ""
    @Published var generatedImages: [StoryImage] = []
    
    // MARK: - Constants
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash-preview-image-generation:generateContent"
    
    // MARK: - Main Generation Method
    
    /// Generate story with text and images together using Gemini API
    /// Returns the story text and any generated images
    func generateStory(request: GeminiStoryRequest) async throws -> StoryResult {
        isGenerating = true
        error = nil
        generatedText = ""
        generatedImages = []
        
        defer {
            isGenerating = false
        }
        
        do {
            // Get API key
            let apiKey = try APIKeyManager.shared.getGeminiAPIKey()
            
            // Build request
            guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
                throw GeminiError.invalidURL
            }
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.timeoutInterval = 120.0
            
            // Create request body
            let requestBody = createRequestBody(from: request)
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🌐 Gemini: Starting generation...")
            
            // Make API call - NO RETRIES
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw GeminiError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                let errorMsg = "HTTP \(httpResponse.statusCode)"
                if let errorData = String(data: data, encoding: .utf8) {
                    print("❌ Gemini API Error: \(errorData)")
                }
                throw GeminiError.httpError(errorMsg)
            }
            
            // Parse response
            let result = try parseResponse(data: data)
            print("✅ Gemini: Generated story (\(result.text.count) chars, \(result.images.count) images)")
            
            // Update published properties
            generatedText = result.text
            generatedImages = result.images
            
            return result
            
        } catch let error as GeminiError {
            self.error = error.message
            throw error
        } catch {
            self.error = "Unexpected error: \(error.localizedDescription)"
            throw GeminiError.unknown(error.localizedDescription)
        }
    }
    
    /// Generate story with streaming text simulation (for UI compatibility)
    func generateStoryWithImagesStreaming(_ request: GeminiStoryRequest) {
        Task {
            do {
                let result = try await generateStory(request: request)
                
                // Simulate streaming by updating text progressively
                await simulateStreaming(text: result.text)
                
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                }
            }
        }
    }
    
    private func simulateStreaming(text: String) async {
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        let wordsPerUpdate = 3
        var currentText = ""
        
        for i in stride(from: 0, to: words.count, by: wordsPerUpdate) {
            let endIndex = min(i + wordsPerUpdate, words.count)
            let newWords = words[i..<endIndex].joined(separator: " ")
            
            if !currentText.isEmpty {
                currentText += " "
            }
            currentText += newWords
            
            await MainActor.run {
                self.generatedText = currentText
            }
            
            // Small delay for streaming effect
            try? await Task.sleep(for: .milliseconds(100))
        }
    }
    
    func cancelGeneration() {
        isGenerating = false
        error = "Generation cancelled"
    }
    
    // MARK: - Request Building
    
    private func createRequestBody(from storyRequest: GeminiStoryRequest) -> [String: Any] {
        let prompt = createPrompt(from: storyRequest)
        
        return [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topP": 0.9,
                "topK": 32,
                "maxOutputTokens": 8192,
                "responseModalities": ["TEXT", "IMAGE"]
            ],
            "safetySettings": [
                [
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", 
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                ],
                [
                    "category": "HARM_CATEGORY_CIVIC_INTEGRITY",
                    "threshold": "BLOCK_NONE"
                ]
            ]
        ]
    }
    
    private func createPrompt(from request: GeminiStoryRequest) -> String {
        // Use LanguageManager for language detection
        let languageManager = LanguageManager.shared
        let currentLanguage = languageManager.currentLanguage
        
        // Determine story length
        let lengthWords: String
        switch request.storyLength.lowercased() {
        case "short": lengthWords = "300-400 words"
        case "medium": lengthWords = "600-700 words"
        case "long": lengthWords = "900-1000 words"
        default: lengthWords = "600-700 words"
        }
        
        // Determine age instructions
        let ageInstructions: String
        switch request.ageGroup.lowercased() {
        case "toddler": ageInstructions = "simple words and short sentences for ages 1-3"
        case "preschooler", "preschool": ageInstructions = "clear language and simple concepts for ages 3-5"
        case "elementary": ageInstructions = "engaging language and age-appropriate concepts for ages 6-10"
        default: ageInstructions = "clear, child-friendly language"
        }
        
        // Language instruction based on LanguageManager
        let languageInstruction = currentLanguage == .english
            ? "Please write the story in English."
            : "Por favor escribe la historia en español."
        
        // Use the same conversational prompt style as the web version
        return """
        Hi! I'd love you to create a wonderful bedtime story for children. \(languageInstruction)

        Here's what I'm hoping for:

        **Story Details:**
        - Main characters: \(request.characters.joined(separator: " and "))
        - Setting: \(request.setting)
        - Theme or lesson: \(request.moralMessage)
        - Age group: \(request.ageGroup) (\(ageInstructions))
        - Length: Around \(lengthWords)

        **Images:**
        I'd also love 3 beautiful, colorful cartoon-style illustrations to go with the story:
        1. A cheerful scene showing \(request.characters.joined(separator: " and ")) in \(request.setting) at the beginning
        2. An exciting moment during their adventure
        3. A happy, heartwarming ending with everyone together

        Please make the images bright, child-friendly, detailed, and full of wonder - no text needed in the images.

        **Format:**
        Start with a catchy title in bold (like **The Amazing Adventure**), then tell the story in a warm, engaging way that children will love.

        Thank you so much! I'm excited to see what magical story you create! ✨
        """
    }
    
    // MARK: - Response Parsing
    
    private func parseResponse(data: Data) throws -> StoryResult {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            print("❌ Failed to parse Gemini response structure")
            throw GeminiError.parseError
        }
        
        var storyParts: [StoryPart] = []
        var images: [StoryImage] = []
        
        // Extract text and images from parts, preserving order
        for (_, part) in parts.enumerated() {
            // Handle text parts
            if let text = part["text"] as? String {
                let cleanedText = cleanStoryText(text)
                if !cleanedText.isEmpty {
                    storyParts.append(.text(cleanedText))
                }
            }
            
            // Handle inline image data
            if let inlineData = part["inlineData"] as? [String: Any],
               let imageDataBase64 = inlineData["data"] as? String,
               let imageData = Data(base64Encoded: imageDataBase64) {
                
                let imageIndex = images.count
                let image = StoryImage(
                    data: imageData,
                    altText: "Story illustration \(imageIndex + 1)",
                    index: imageIndex
                )
                images.append(image)
                storyParts.append(.image(imageIndex: imageIndex, altText: image.altText))
            }
        }
        
        // Check if we need to apply fallback positioning (25%, 50%, 75%)
        let finalParts = applyFallbackPositioning(parts: storyParts, images: images)
        let structuredContent = StructuredStoryContent(parts: finalParts, images: images)
        
        print("✅ Gemini: Generated structured story (\(structuredContent.plainText.count) chars, \(images.count) images)")
        
        return StoryResult(structuredContent: structuredContent)
    }
    
    // MARK: - Fallback Positioning Logic
    
    private func applyFallbackPositioning(parts: [StoryPart], images: [StoryImage]) -> [StoryPart] {
        // If we have no images, return text-only parts
        guard !images.isEmpty else {
            return parts
        }
        
        // Check if images are properly interspersed with text (not all clustered at end)
        let hasProperlyInterspersedImages = areImagesProperlyDistributed(parts: parts)
        
        if hasProperlyInterspersedImages {
            print("📍 Using Gemini's original image positioning - properly distributed")
            return parts
        }
        
        print("📍 Images are clustered - applying smart repositioning")
        
        // Get all text content and combine it
        let allText = parts.compactMap { part in
            if case .text(let text) = part {
                return text
            }
            return nil
        }.joined(separator: "")
        
        // Split text into paragraphs for better positioning
        let paragraphs = allText.components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // For very short stories or single paragraphs, use sentence-based positioning
        if paragraphs.count <= 2 {
            print("📍 Applying sentence-based positioning for short story")
            return applySentenceBasedPositioning(text: allText, images: images)
        }
        
        // For longer stories, use paragraph-based positioning
        print("📍 Applying paragraph-based positioning at strategic positions")
        return applyParagraphBasedPositioning(paragraphs: paragraphs, images: images)
    }
    
    private func areImagesProperlyDistributed(parts: [StoryPart]) -> Bool {
        // Find positions of text and image parts
        var textIndices: [Int] = []
        var imageIndices: [Int] = []
        
        for (index, part) in parts.enumerated() {
            switch part {
            case .text:
                textIndices.append(index)
            case .image:
                imageIndices.append(index)
            }
        }
        
        // If no images, consider it "properly distributed" (no repositioning needed)
        guard !imageIndices.isEmpty else { return true }
        
        // If there's only text or only images, not properly distributed
        guard !textIndices.isEmpty else { return false }
        
        // Check if all images are clustered at the end
        let totalParts = parts.count
        let lastTextIndex = textIndices.last ?? -1
        let firstImageIndex = imageIndices.first ?? totalParts
        
        // If all images come after all text, they're clustered at the end
        if firstImageIndex > lastTextIndex {
            print("🔍 All images detected at end - needs repositioning")
            return false
        }
        
        // Check if images are reasonably distributed throughout the story
        let textPortionWithImages = imageIndices.filter { $0 <= lastTextIndex }.count
        let imageDistributionRatio = Double(textPortionWithImages) / Double(imageIndices.count)
        
        // If less than 50% of images are interspersed with text, consider it poorly distributed
        if imageDistributionRatio < 0.5 {
            print("🔍 Poor image distribution detected (ratio: \(imageDistributionRatio)) - needs repositioning")
            return false
        }
        
        print("🔍 Images appear properly distributed (ratio: \(imageDistributionRatio))")
        return true
    }
    
    private func applyParagraphBasedPositioning(paragraphs: [String], images: [StoryImage]) -> [StoryPart] {
        // Calculate positions for up to 3 images at strategic positions
        let imagesToPlace = min(images.count, 3)
        let positions = calculateImagePositions(paragraphCount: paragraphs.count, imageCount: imagesToPlace)
        
        var result: [StoryPart] = []
        var imageIndex = 0
        
        for (paragraphIndex, paragraph) in paragraphs.enumerated() {
            // Add paragraph
            result.append(.text(paragraph))
            
            // Check if we should insert an image after this paragraph
            if positions.contains(paragraphIndex) && imageIndex < images.count {
                let image = images[imageIndex]
                result.append(.image(imageIndex: imageIndex, altText: image.altText))
                imageIndex += 1
            }
        }
        
        // Add any remaining images at the end
        while imageIndex < images.count {
            let image = images[imageIndex]
            result.append(.image(imageIndex: imageIndex, altText: image.altText))
            imageIndex += 1
        }
        
        return result
    }
    
    private func applySentenceBasedPositioning(text: String, images: [StoryImage]) -> [StoryPart] {
        // Split text into sentences for better distribution
        let sentences = text.components(separatedBy: CharacterSet(charactersIn: ".!?"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // If we have very few sentences, just alternate text and images
        guard sentences.count > images.count else {
            var result: [StoryPart] = []
            for (index, sentence) in sentences.enumerated() {
                result.append(.text(sentence + "."))
                if index < images.count {
                    let image = images[index]
                    result.append(.image(imageIndex: index, altText: image.altText))
                }
            }
            // Add any remaining images
            for remainingIndex in sentences.count..<images.count {
                let image = images[remainingIndex]
                result.append(.image(imageIndex: remainingIndex, altText: image.altText))
            }
            return result
        }
        
        // Calculate sentence positions for image placement
        let imagesToPlace = min(images.count, 3)
        let positions = calculateSentencePositions(sentenceCount: sentences.count, imageCount: imagesToPlace)
        
        var result: [StoryPart] = []
        var imageIndex = 0
        var currentTextGroup: [String] = []
        
        for (sentenceIndex, sentence) in sentences.enumerated() {
            currentTextGroup.append(sentence + ".")
            
            // Check if we should insert an image after this sentence
            if positions.contains(sentenceIndex) && imageIndex < images.count {
                // Add accumulated text
                if !currentTextGroup.isEmpty {
                    result.append(.text(currentTextGroup.joined(separator: " ")))
                    currentTextGroup = []
                }
                
                // Add image
                let image = images[imageIndex]
                result.append(.image(imageIndex: imageIndex, altText: image.altText))
                imageIndex += 1
            }
        }
        
        // Add any remaining text
        if !currentTextGroup.isEmpty {
            result.append(.text(currentTextGroup.joined(separator: " ")))
        }
        
        // Add any remaining images at the end
        while imageIndex < images.count {
            let image = images[imageIndex]
            result.append(.image(imageIndex: imageIndex, altText: image.altText))
            imageIndex += 1
        }
        
        return result
    }
    
    private func calculateSentencePositions(sentenceCount: Int, imageCount: Int) -> [Int] {
        guard sentenceCount > imageCount else {
            return Array(0..<min(sentenceCount - 1, imageCount))
        }
        
        var positions: [Int] = []
        
        switch imageCount {
        case 1:
            // Single image at middle position
            positions.append(Int(Double(sentenceCount) * 0.5))
        case 2:
            // Two images at 33% and 66% positions
            positions.append(Int(Double(sentenceCount) * 0.33))
            positions.append(Int(Double(sentenceCount) * 0.66))
        case 3:
            // Three images at 25%, 50%, 75% positions
            positions.append(Int(Double(sentenceCount) * 0.25))
            positions.append(Int(Double(sentenceCount) * 0.50))
            positions.append(Int(Double(sentenceCount) * 0.75))
        default:
            // For more images, distribute evenly
            let interval = Double(sentenceCount) / Double(imageCount + 1)
            for i in 1...imageCount {
                positions.append(Int(interval * Double(i)))
            }
        }
        
        // Ensure positions are within bounds and unique
        positions = positions.compactMap { pos in
            let clampedPos = max(0, min(pos, sentenceCount - 2)) // Don't place after last sentence
            return clampedPos
        }
        
        return Array(Set(positions)).sorted() // Remove duplicates and sort
    }
    
    private func calculateImagePositions(paragraphCount: Int, imageCount: Int) -> [Int] {
        guard paragraphCount > imageCount else {
            // If we have more images than paragraphs, distribute them evenly
            return Array(0..<min(paragraphCount - 1, imageCount))
        }
        
        var positions: [Int] = []
        
        switch imageCount {
        case 1:
            // Single image at 50% position
            positions.append(Int(Double(paragraphCount) * 0.5))
        case 2:
            // Two images at 33% and 66% positions
            positions.append(Int(Double(paragraphCount) * 0.33))
            positions.append(Int(Double(paragraphCount) * 0.66))
        case 3:
            // Three images at 25%, 50%, 75% positions
            positions.append(Int(Double(paragraphCount) * 0.25))
            positions.append(Int(Double(paragraphCount) * 0.50))
            positions.append(Int(Double(paragraphCount) * 0.75))
        default:
            // For more images, distribute evenly
            let interval = Double(paragraphCount) / Double(imageCount + 1)
            for i in 1...imageCount {
                positions.append(Int(interval * Double(i)))
            }
        }
        
        // Ensure positions are within bounds and unique
        positions = positions.compactMap { pos in
            let clampedPos = max(0, min(pos, paragraphCount - 2)) // Don't place after last paragraph
            return clampedPos
        }
        
        return Array(Set(positions)).sorted() // Remove duplicates and sort
    }
    
    // MARK: - Text Cleaning (same as web version)
    
    private func cleanStoryText(_ rawText: String) -> String {
        print("🧹 Cleaning story text...")
        
        var cleanedText = rawText
        
        // Remove common preambles (Spanish)
        let spanishPreambles = [
            "¡Absolutamente!\\s*Aquí tienes una historia[^.]*\\.",
            "Aquí tienes una historia[^.]*\\.",
            "Te presento una historia[^.]*\\.",
            "Esta es una historia[^.]*\\.",
            "¡Por supuesto!\\s*Aquí tienes[^.]*\\.",
            "¡Claro!\\s*Aquí tienes[^.]*\\.",
            "¡Perfecto!\\s*Aquí tienes[^.]*\\."
        ]
        
        // Remove common preambles (English)
        let englishPreambles = [
            "Absolutely!\\s*Here's a story[^.]*\\.",
            "Here's a wonderful story[^.]*\\.",
            "I'd be happy to create[^.]*\\.",
            "Let me create[^.]*\\.",
            "Here's a bedtime story[^.]*\\.",
            "Of course!\\s*Here's[^.]*\\.",
            "Perfect!\\s*Here's[^.]*\\."
        ]
        
        // Apply cleaning patterns
        let allPatterns = spanishPreambles + englishPreambles
        
        for pattern in allPatterns {
            cleanedText = cleanedText.replacingOccurrences(
                of: pattern,
                with: "",
                options: [.regularExpression, .caseInsensitive]
            )
        }
        
        // Remove extra whitespace and normalize
        cleanedText = cleanedText
            .replacingOccurrences(of: "\\n\\s*\\n\\s*\\n", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("✅ Story text cleaned successfully")
        return cleanedText
    }
}

// MARK: - Request Model

struct GeminiStoryRequest {
    let ageGroup: String
    let storyLength: String
    let characters: [String]
    let setting: String
    let moralMessage: String
    let language: String
    let maxTokens: Int
    
    init(ageGroup: String, storyLength: String, characters: [String], setting: String, moralMessage: String, language: String = "english", maxTokens: Int = 2000) {
        self.ageGroup = ageGroup
        self.storyLength = storyLength
        self.characters = characters
        self.setting = setting
        self.moralMessage = moralMessage
        self.language = language
        self.maxTokens = maxTokens
    }
}

// MARK: - Error Handling

enum GeminiError: Error {
    case invalidURL
    case invalidResponse
    case httpError(String)
    case parseError
    case apiKeyError
    case unknown(String)
    
    var message: String {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .httpError(let details):
            return "Connection error: \(details)"
        case .parseError:
            return "Could not parse Gemini response"
        case .apiKeyError:
            return "API key problem - check settings"
        case .unknown(let details):
            return "Unexpected error: \(details)"
        }
    }
}
