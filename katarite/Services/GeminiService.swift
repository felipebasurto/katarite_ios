import Foundation
import Combine
import UIKit

/// Service for interacting with the Gemini API
/// Uses Gemini 2.0 Flash for combined text and image generation
class GeminiService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = GeminiService()
    private init() {}
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generatedText = ""
    @Published var generatedImages: [StoryImage] = []
    @Published var error: GeminiError?
    @Published var progress: StoryGenerationProgress = .idle
    
    // MARK: - Private Properties
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta"
    private let primaryModelName = "gemini-2.0-flash-exp" // Primary model for image generation
    private let fallbackModelNames = [
        "gemini-2.0-flash-preview-image-generation", // Preview model (may not be available in all regions)
        "gemini-1.5-flash", // Fallback to text-only if image generation unavailable
        "gemini-1.5-pro"   // Final fallback
    ]
    private var currentTask: URLSessionDataTask?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Generates a story with images using the Gemini API
    /// - Parameter request: The story generation request
    /// - Returns: A publisher that emits the final result
    func generateStoryWithImages(_ request: GeminiStoryRequest) -> AnyPublisher<StoryGenerationResult, GeminiError> {
        return Future<StoryGenerationResult, GeminiError> { [weak self] promise in
            self?.performStoryGeneration(request, completion: promise)
        }
        .eraseToAnyPublisher()
    }
    
    /// Generates a story with images with real-time updates to published properties
    func generateStoryWithImagesStreaming(_ request: GeminiStoryRequest) {
        // Reset state
        generatedText = ""
        generatedImages = []
        error = nil
        isGenerating = true
        progress = .generatingText
        
        // Cancel any existing request
        currentTask?.cancel()
        
        // Perform the generation
        performStoryGeneration(request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                switch result {
                case .success(let storyResult):
                    self?.generatedText = storyResult.text
                    self?.generatedImages = storyResult.images
                    self?.progress = .completed
                case .failure(let error):
                    self?.error = error
                    self?.progress = .failed
                }
            }
        }
    }
    
    /// Generates only text using the Gemini API (uses same model but text-only response)
    func generateTextOnly(_ request: GeminiStoryRequest) -> AnyPublisher<String, GeminiError> {
        return Future<String, GeminiError> { [weak self] promise in
            self?.performTextOnlyGeneration(request, completion: promise)
        }
        .eraseToAnyPublisher()
    }
    
    /// Cancels the current generation
    func cancelGeneration() {
        currentTask?.cancel()
        isGenerating = false
        progress = .idle
    }
    
    // MARK: - Async Methods with Storage Integration
    
    /// Generate a story with images and save them to local storage
    func generateStoryWithImagesAndStorage(request: GeminiStoryRequest, storyId: UUID) async throws -> StoryGenerationResult {
        await MainActor.run {
            self.isGenerating = true
            self.error = nil
            self.generatedText = ""
            self.generatedImages = []
            self.progress = .generatingText
        }
        
        do {
            // Single call to generate both text and images
            let result = try await withCheckedThrowingContinuation { continuation in
                performStoryGeneration(request) { result in
                    continuation.resume(with: result)
                }
            }
            
            await MainActor.run {
                self.generatedText = result.text
                self.generatedImages = result.images
            }
            
            // Save images to local storage if any were generated
            if !result.images.isEmpty {
                await MainActor.run {
                    self.progress = .generatingImages
                }
                let savedPaths = try await ImageStorageManager.shared.saveImages(result.images, forStory: storyId)
                print("✅ GeminiService: Saved \(savedPaths.count) images to local storage")
            }
            
            await MainActor.run {
                self.progress = .completed
                self.isGenerating = false
            }
            
            return result
            
        } catch {
            await MainActor.run {
                self.error = error as? GeminiError ?? .unknownError
                self.isGenerating = false
                self.progress = .failed
            }
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func performStoryGeneration(_ request: GeminiStoryRequest, completion: @escaping (Result<StoryGenerationResult, GeminiError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/models/\(primaryModelName):generateContent") else {
            completion(.failure(.invalidURL))
            return
        }
        
        do {
            let apiKey = try APIKeyManager.shared.getGeminiAPIKey()
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            urlRequest.timeoutInterval = 120.0 // 2 minutes timeout for combined generation
            
            let requestBody = createCombinedGenerationRequestBody(from: request)
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🌐 Gemini: Starting combined text and image generation...")
            
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest) { [weak self] data, response, error in
                if let error = error {
                    if (error as NSError).code == NSURLErrorCancelled {
                        // User cancelled, don't report as error
                        return
                    }
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    print("❌ Gemini API error: HTTP \(httpResponse.statusCode)")
                    if let data = data,
                       let errorString = String(data: data, encoding: .utf8) {
                        print("Error details: \(errorString)")
                    }
                    completion(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                self?.parseGenerationResponse(data: data, completion: completion)
            }
            
            currentTask = task
            task.resume()
            
        } catch {
            completion(.failure(.apiKeyError))
        }
    }
    
    private func performTextOnlyGeneration(_ request: GeminiStoryRequest, completion: @escaping (Result<String, GeminiError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/models/\(primaryModelName):generateContent") else {
            completion(.failure(.invalidURL))
            return
        }
        
        do {
            let apiKey = try APIKeyManager.shared.getGeminiAPIKey()
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue(apiKey, forHTTPHeaderField: "x-goog-api-key")
            urlRequest.timeoutInterval = 60.0
            
            let requestBody = createTextOnlyRequestBody(from: request)
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            print("🌐 Gemini: Starting text-only generation...")
            
            let session = URLSession.shared
            let task = session.dataTask(with: urlRequest) { data, response, error in
                if let error = error {
                    if (error as NSError).code == NSURLErrorCancelled {
                        return
                    }
                    completion(.failure(.networkError(error)))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
                    completion(.failure(.noData))
                    return
                }
                
                // Parse text-only response
                do {
                    if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let candidates = jsonResponse["candidates"] as? [[String: Any]],
                       let firstCandidate = candidates.first,
                       let content = firstCandidate["content"] as? [String: Any],
                       let parts = content["parts"] as? [[String: Any]] {
                        
                        // Extract text from parts
                        var storyText = ""
                        for part in parts {
                            if let text = part["text"] as? String {
                                storyText += text
                            }
                        }
                        
                        if !storyText.isEmpty {
                            print("✅ Gemini text generation completed (\(storyText.count) characters)")
                            completion(.success(storyText))
                        } else {
                            completion(.failure(.noData))
                        }
                    } else {
                        completion(.failure(.jsonParsingError))
                    }
                } catch {
                    completion(.failure(.jsonParsingError))
                }
            }
            
            currentTask = task
            task.resume()
            
        } catch {
            completion(.failure(.apiKeyError))
        }
    }
    
    private func parseGenerationResponse(data: Data, completion: @escaping (Result<StoryGenerationResult, GeminiError>) -> Void) {
        do {
            if let jsonResponse = try JSONSerialization.jsonObject(with: data) as? [String: Any],
               let candidates = jsonResponse["candidates"] as? [[String: Any]],
               let firstCandidate = candidates.first,
               let content = firstCandidate["content"] as? [String: Any],
               let parts = content["parts"] as? [[String: Any]] {
                
                var storyText = ""
                var images: [StoryImage] = []
                var imageIndex = 0
                
                // Process each part - could be text or image
                for part in parts {
                    // Check for text content
                    if let text = part["text"] as? String {
                        storyText += text
                    }
                    
                    // Check for image content
                    if let inlineData = part["inlineData"] as? [String: Any],
                       let imageBase64 = inlineData["data"] as? String,
                       let mimeType = inlineData["mimeType"] as? String,
                       mimeType.hasPrefix("image/"),
                       let imageData = Data(base64Encoded: imageBase64) {
                        
                        // Extract alt text from the surrounding text context
                        let altText = extractAltTextForImage(at: imageIndex, from: storyText)
                        
                        let storyImage = StoryImage(
                            id: UUID(),
                            data: imageData,
                            base64Data: imageBase64,
                            altText: altText,
                            index: imageIndex
                        )
                        
                        images.append(storyImage)
                        imageIndex += 1
                        
                        print("✅ Found image \(imageIndex) in response (\(imageData.count) bytes)")
                    }
                }
                
                print("✅ Gemini generation completed: \(storyText.count) characters, \(images.count) images")
                
                let result = StoryGenerationResult(text: storyText, images: images)
                completion(.success(result))
                
            } else {
                completion(.failure(.jsonParsingError))
            }
        } catch {
            print("❌ JSON parsing error: \(error)")
            completion(.failure(.jsonParsingError))
        }
    }
    
    private func extractAltTextForImage(at index: Int, from storyText: String) -> String {
        // Try to extract image description from nearby text
        // Look for patterns like [Image: ...] or similar markers
        let imageMarkerRegex = try? NSRegularExpression(pattern: "\\[Image:([^\\]]+)\\]", options: .caseInsensitive)
        if let regex = imageMarkerRegex {
            let matches = regex.matches(in: storyText, options: [], range: NSRange(location: 0, length: storyText.count))
            if index < matches.count {
                let match = matches[index]
                if let range = Range(match.range(at: 1), in: storyText) {
                    return String(storyText[range]).trimmingCharacters(in: .whitespaces)
                }
            }
        }
        
        // Fallback alt text
        return "Story illustration \(index + 1)"
    }
    
    private func createCombinedGenerationRequestBody(from request: GeminiStoryRequest) -> [String: Any] {
        let systemPrompt = createSystemPromptForCombinedGeneration(from: request)
        
        return [
            "contents": [
                [
                    "parts": [
                        [
                            "text": systemPrompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.9,
                "maxOutputTokens": request.maxTokens,
                "responseMimeType": "text/plain",
                "responseModalities": ["TEXT", "IMAGE"]  // Request both text and images
            ]
        ]
    }
    
    private func createTextOnlyRequestBody(from request: GeminiStoryRequest) -> [String: Any] {
        let systemPrompt = createSystemPromptForTextOnly(from: request)
        
        return [
            "contents": [
                [
                    "parts": [
                        [
                            "text": systemPrompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.8,
                "topK": 40,
                "topP": 0.9,
                "maxOutputTokens": request.maxTokens,
                "responseMimeType": "text/plain",
                "responseModalities": ["TEXT"]  // Request only text
            ]
        ]
    }
    
    private func createSystemPromptForCombinedGeneration(from request: GeminiStoryRequest) -> String {
        let lengthWords: String
        switch request.storyLength.lowercased() {
        case "short":
            lengthWords = "300-400 words"
        case "medium":
            lengthWords = "600-700 words"
        case "long":
            lengthWords = "900-1000 words"
        default:
            lengthWords = "600-700 words"
        }

        let ageInstructions: String
        switch request.ageGroup.lowercased() {
        case "toddler":
            ageInstructions = "Use simple words and short sentences suitable for ages 1-3"
        case "preschooler", "preschool":
            ageInstructions = "Use clear language and simple concepts suitable for ages 3-5"
        case "elementary":
            ageInstructions = "Use engaging language and more complex concepts suitable for ages 6-10"
        default:
            ageInstructions = "Use clear language suitable for young children"
        }
        
        let languageInstruction = request.language == "english" 
            ? "CRITICAL REQUIREMENT: Write the ENTIRE story in ENGLISH ONLY. Do not use any other language." 
            : "REQUISITO CRÍTICO: Escribe TODA la historia en ESPAÑOL SOLAMENTE. No uses ningún otro idioma. Esto es absolutamente obligatorio."

        let mainCharacterDescription = request.characters.first ?? "a child"

        return """
        \(languageInstruction)

        You are an exceptional children's bedtime story writer. Create a captivating story with beautiful illustrations.

        STORY REQUIREMENTS:
          - Main character(s): \(request.characters.joined(separator: ", ")) - The first character '\(mainCharacterDescription)' MUST be the story protagonist
          - Setting: \(request.setting) - Create a vivid, immersive world
          - Theme/Message: \(request.moralMessage) - Weave naturally throughout
          - Age group: \(ageInstructions)
          - Length: \(lengthWords)
          - Language: \(languageInstruction)
          
        GENERATION INSTRUCTIONS:
          1. Write the complete story first
          2. At 2-3 key moments in your story, generate beautiful, colorful illustrations
          3. Place each illustration at the most impactful point
          4. Mark image locations with [Image: brief description]
          
        CREATIVE REQUIREMENTS:
          - Include surprising plot twists
          - Create unique challenges requiring creative solutions
          - Use vivid imagery and age-appropriate metaphors
          - Develop memorable secondary characters
          - Incorporate magical or unexpected elements
          
        FORMAT:
          1. Title surrounded by ** (e.g., **The Magic Forest**)
          2. Blank line after title
          3. Story paragraphs separated by blank lines
          4. Images will be generated inline at marked points
          5. End with "The End." on its own line
          
        Generate a complete, engaging story with illustrations now.
        """
    }
    
    private func createSystemPromptForTextOnly(from request: GeminiStoryRequest) -> String {
        // Similar to combined but without image instructions
        let lengthWords: String
        switch request.storyLength.lowercased() {
        case "short":
            lengthWords = "300-400 words"
        case "medium":
            lengthWords = "600-700 words"
        case "long":
            lengthWords = "900-1000 words"
        default:
            lengthWords = "600-700 words"
        }

        let ageInstructions: String
        switch request.ageGroup.lowercased() {
        case "toddler":
            ageInstructions = "Use simple words and short sentences suitable for ages 1-3"
        case "preschooler", "preschool":
            ageInstructions = "Use clear language and simple concepts suitable for ages 3-5"
        case "elementary":
            ageInstructions = "Use engaging language and more complex concepts suitable for ages 6-10"
        default:
            ageInstructions = "Use clear language suitable for young children"
        }
        
        let languageInstruction = request.language == "english" 
            ? "CRITICAL REQUIREMENT: Write the ENTIRE story in ENGLISH ONLY. Do not use any other language." 
            : "REQUISITO CRÍTICO: Escribe TODA la historia en ESPAÑOL SOLAMENTE. No uses ningún otro idioma."

        return """
        \(languageInstruction)

        Create an exceptional children's bedtime story with these requirements:

        - Main character(s): \(request.characters.joined(separator: ", "))
        - Setting: \(request.setting)
        - Theme: \(request.moralMessage)
        - Age group: \(ageInstructions)
        - Length: \(lengthWords)
        
        Include creative plot twists, vivid descriptions, and memorable characters.
        
        FORMAT:
        1. **Title**
        2. Blank line
        3. Story paragraphs
        4. "The End."
        
        Write only the story, no explanations.
        """
    }
}

// MARK: - Data Models

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

struct StoryGenerationResult {
    let text: String
    let images: [StoryImage]
}

struct StoryImage: Identifiable, Codable {
    let id: UUID
    let data: Data
    let base64Data: String
    let altText: String
    let index: Int
    
    init(id: UUID = UUID(), data: Data, base64Data: String, altText: String, index: Int) {
        self.id = id
        self.data = data
        self.base64Data = base64Data
        self.altText = altText
        self.index = index
    }
}

enum StoryGenerationProgress {
    case idle
    case generatingText
    case generatingImages
    case completed
    case failed
    
    var description: String {
        switch self {
        case .idle:
            return "Ready"
        case .generatingText:
            return "Creating your story..."
        case .generatingImages:
            return "Generating illustrations..."
        case .completed:
            return "Story complete!"
        case .failed:
            return "Generation failed"
        }
    }
}

// MARK: - Error Types

enum GeminiError: Error, LocalizedError {
    case invalidURL
    case apiKeyError
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case noData
    case jsonParsingError
    case imageGenerationFailed
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Unable to connect to Gemini AI service. Please try again."
        case .apiKeyError:
            return "Gemini API key is missing or invalid. Please check your settings."
        case .networkError(let error):
            return "Connection failed: \(error.localizedDescription). Please check your internet connection and try again."
        case .invalidResponse:
            return "Received an unexpected response from Gemini AI. Please try again."
        case .httpError(let statusCode):
            switch statusCode {
            case 401:
                return "Authentication failed. Please check your Gemini API key."
            case 403:
                return "Access denied. Your API key may not have permission for this operation."
            case 429:
                return "Rate limit exceeded. Please wait a moment and try again."
            case 500...599:
                return "Gemini AI service is temporarily unavailable. Please try again later."
            default:
                return "Service error (\(statusCode)). Please try again."
            }
        case .noData:
            return "No response received from Gemini AI. Please try again."
        case .jsonParsingError:
            return "Unable to process the response from Gemini AI. Please try again."
        case .imageGenerationFailed:
            return "Failed to generate images. Please try again."
        case .unknownError:
            return "An unexpected error occurred. Please try again."
        }
    }
} 