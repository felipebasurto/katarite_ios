import Foundation
import Combine

/// Service for interacting with the DeepSeek API
/// Supports streaming text generation for real-time story creation
class DeepSeekService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = DeepSeekService()
    private init() {}
    
    // MARK: - Published Properties
    @Published var isGenerating = false
    @Published var generatedText = ""
    @Published var error: DeepSeekError?
    
    // MARK: - Private Properties
    private let baseURL = "https://api.deepseek.com"
    private var currentTask: URLSessionDataTask?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Public Methods
    
    /// Generates a story using the DeepSeek API with streaming
    /// - Parameter request: The story generation request
    /// - Returns: A publisher that emits streaming text chunks
    func generateStory(_ request: StoryGenerationRequest) -> AnyPublisher<String, DeepSeekError> {
        return Future<String, DeepSeekError> { [weak self] promise in
            self?.performStreamingRequest(request, completion: promise)
        }
        .eraseToAnyPublisher()
    }
    
    /// Generates a story with real-time updates to published properties
    func generateStoryStreaming(_ request: StoryGenerationRequest) {
        // Reset state
        generatedText = ""
        error = nil
        isGenerating = true
        
        // Cancel any existing request
        currentTask?.cancel()
        
        // Perform the streaming request
        performStreamingRequest(request) { [weak self] result in
            DispatchQueue.main.async {
                self?.isGenerating = false
                switch result {
                case .success(let finalText):
                    self?.generatedText = finalText
                case .failure(let error):
                    self?.error = error
                }
            }
        }
    }
    
    /// Cancels the current story generation
    func cancelGeneration() {
        currentTask?.cancel()
        isGenerating = false
    }
    
    // MARK: - Private Methods
    
    private func createSystemPrompt(from request: StoryGenerationRequest) -> String {
        // Use LanguageManager for language detection
        let languageManager = LanguageManager.shared
        let currentLanguage = languageManager.currentLanguage
        
        // Define specific word counts for better consistency
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

        // Define age-specific instructions
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
        
        let languageInstruction = currentLanguage == .english 
            ? "CRITICAL REQUIREMENT: Write the ENTIRE story in ENGLISH ONLY. Do not use any other language." 
            : "REQUISITO CRÍTICO: Escribe TODA la historia en ESPAÑOL SOLAMENTE. No uses ningún otro idioma. Esto es absolutamente obligatorio."

        let mainCharacterDescription = request.characters.first ?? "a child"

        // Create language-specific prompt
        let prompt = createLanguageSpecificPrompt(
            languageInstruction: languageInstruction,
            characters: request.characters,
            mainCharacterDescription: mainCharacterDescription,
            setting: request.setting,
            moralMessage: request.moralMessage,
            ageInstructions: ageInstructions,
            lengthWords: lengthWords,
            language: currentLanguage
        )
        
        return prompt
    }
    
    private func createLanguageSpecificPrompt(
        languageInstruction: String,
        characters: [String],
        mainCharacterDescription: String,
        setting: String,
        moralMessage: String,
        ageInstructions: String,
        lengthWords: String,
        language: LanguageManager.AppLanguage
    ) -> String {
        
        if language == .spanish {
            return """
            \(languageInstruction)

            Eres un escritor excepcional de cuentos infantiles para la hora de dormir, conocido por tu creatividad y originalidad. Crea una historia cautivadora y apropiada para la edad que se destaque de los cuentos infantiles típicos.

            REQUISITOS DE LA HISTORIA:
              - Personaje(s) principal(es): \(characters.joined(separator: ", ")) - El primer personaje de la lista, '\(mainCharacterDescription)', DEBE ser central en la historia con rasgos de personalidad distintivos, deseos y desafíos. Desarrolla completamente este personaje.
              - Escenario: \(setting) - Crea un escenario vívido e inmersivo con detalles sensoriales (vistas, sonidos, olores). El escenario debe sentirse único e influir en los eventos de la historia.
              - Tema/Mensaje: \(moralMessage) - Entreteje este tema o mensaje a lo largo de la historia de maneras inesperadas.
              - Grupo de edad: \(ageInstructions) - Usa vocabulario y conceptos apropiados para esta edad.
              - Longitud: \(lengthWords) - Asegúrate de que la historia tenga el ritmo y desarrollo adecuados para este conteo exacto de palabras.
              - Idioma: \(languageInstruction)
              
            ELEMENTOS CREATIVOS (REQUERIDOS):
              - Incluye al menos un giro argumental sorprendente que cambie la dirección de la historia
              - Crea un desafío u obstáculo único que requiera resolución creativa de problemas
              - Incluye imágenes vívidas y metáforas que los niños puedan entender
              - Desarrolla personajes secundarios con personalidades distintivas (si aplica)
              - Incorpora un elemento inesperado o aspecto mágico que deleite y sorprenda
              - Evita argumentos clichés y finales predecibles
              
            REQUISITOS ESTRUCTURALES:
              - Inicio bien definido (preparación), medio (conflicto/desafío) y final (resolución)
              - Crecimiento claro del personaje o lección aprendida
              - Diálogo atractivo que revele las personalidades de los personajes
              - Una conclusión satisfactoria que una todos los elementos de la historia
              
            REQUISITOS DE FORMATO (MUY IMPORTANTE):
              1. Comienza con el título en su propia línea, rodeado por ** (ej., **El Bosque Mágico**)
              2. Agrega una línea en blanco después del título
              3. Formatea la historia con párrafos apropiados, con cada párrafo separado por una línea en blanco
              4. Usa espaciado e indentación apropiados para legibilidad
              5. Para diálogos, usa comillas y atribución apropiada (ej., "Hola," dijo Sam.)
              6. Termina la historia con "Fin." en su propia línea
              
            La historia debe ser imaginativa, original y adecuada para la lectura antes de dormir. Hazla visualmente atractiva cuando se muestre en una página web.
              
            No incluyas ninguna advertencia, nota o explicación antes o después de la historia. Solo proporciona la historia en sí, comenzando con el título y terminando con "Fin."
            """
        } else {
            return """
            \(languageInstruction)

            You are an exceptional children's bedtime story writer known for your creativity and originality. Create a captivating, age-appropriate story that stands out from typical children's tales.

            STORY REQUIREMENTS:
              - Main character(s): \(characters.joined(separator: ", ")) - The first character on the list, '\(mainCharacterDescription)', MUST be central to the story with distinct personality traits, desires, and challenges. Develop this character fully.
              - Setting: \(setting) - Create a vivid, immersive setting with sensory details (sights, sounds, smells). The setting should feel unique and influence the story's events.
              - Theme/Message: \(moralMessage) - Weave this theme or message throughout the story in unexpected ways.
              - Age group: \(ageInstructions) - Use vocabulary and concepts appropriate for this age.
              - Length: \(lengthWords) - Ensure the story has proper pacing and development for this exact word count.
              - Language: \(languageInstruction)
              
            CREATIVE ELEMENTS (REQUIRED):
              - Include at least one surprising plot twist that changes the direction of the story
              - Create a unique challenge or obstacle that requires creative problem-solving
              - Include vivid imagery and metaphors that children can understand
              - Develop secondary characters with distinct personalities (if applicable)
              - Incorporate an unexpected element or magical aspect that delights and surprises
              - Avoid clichéd storylines and predictable endings
              
            STRUCTURAL REQUIREMENTS:
              - Well-defined beginning (setup), middle (conflict/challenge), and end (resolution)
              - Clear character growth or lesson learned
              - Engaging dialogue that reveals character personalities
              - A satisfying conclusion that ties together the story elements
              
            FORMAT REQUIREMENTS (VERY IMPORTANT):
              1. Start with the title on its own line, surrounded by ** (e.g., **The Magic Forest**)
              2. Add a blank line after the title
              3. Format the story with proper paragraphs, with each paragraph separated by a blank line
              4. Use proper spacing and indentation for readability
              5. For dialog, use quotation marks and proper attribution (e.g., "Hello," said Sam.)
              6. End the story with "The End." on its own line
              
            The story should be imaginative, original, and suitable for bedtime reading. Make it visually appealing when displayed on a webpage.
              
            Do not include any disclaimers, notes, or explanations before or after the story. Just provide the story itself, starting with the title and ending with "The End."
            """
        }
    }
    
    private func performStreamingRequest(_ request: StoryGenerationRequest, completion: @escaping (Result<String, DeepSeekError>) -> Void) {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            completion(.failure(.invalidURL))
            return
        }
        
        do {
            let apiKey = try APIKeyManager.shared.getDeepSeekAPIKey()
            
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            urlRequest.setValue("text/event-stream", forHTTPHeaderField: "Accept")
            urlRequest.setValue("keep-alive", forHTTPHeaderField: "Connection")
            urlRequest.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
            
            let requestBody = createRequestBody(from: request)
            urlRequest.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
            
            // API Request logging (simplified)
            print("🌐 DeepSeek: Starting story generation...")
            
            // Use URLSessionDataTask with delegate for streaming
            let session = URLSession(configuration: .default, delegate: StreamingDelegate(service: self, completion: completion), delegateQueue: nil)
            let task = session.dataTask(with: urlRequest)
            
            currentTask = task
            task.resume()
            
        } catch {
            completion(.failure(.apiKeyError))
        }
    }
    

    
    private func createRequestBody(from request: StoryGenerationRequest) -> [String: Any] {
        let systemPrompt = createSystemPrompt(from: request)
        
        return [
            "model": "deepseek-chat",
            "messages": [
                [
                    "role": "system",
                    "content": systemPrompt
                ],
                [
                    "role": "user",
                    "content": "Please create a story based on the parameters provided."
                ]
            ],
            "stream": true,
            "max_tokens": request.maxTokens,
            "temperature": 0.7
        ]
    }
}

// MARK: - Streaming Delegate

class StreamingDelegate: NSObject, URLSessionDataDelegate {
    weak var service: DeepSeekService?
    let completion: (Result<String, DeepSeekError>) -> Void
    private var accumulatedText = ""
    private let updateQueue = DispatchQueue(label: "com.katarite.text-update", qos: .userInteractive)
    
    init(service: DeepSeekService, completion: @escaping (Result<String, DeepSeekError>) -> Void) {
        self.service = service
        self.completion = completion
        super.init()
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid HTTP response")
            completion(.failure(.invalidResponse))
            completionHandler(.cancel)
            return
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            print("❌ DeepSeek API Error: \(httpResponse.statusCode)")
            completion(.failure(.httpError(httpResponse.statusCode)))
            completionHandler(.cancel)
            return
        }
        
        print("📖 DeepSeek: Stream starting...")
        completionHandler(.allow)
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { 
            print("❌ Failed to decode data as UTF-8")
            return 
        }
        
        // Reduced debug output - only log when we have meaningful content
        
        let lines = string.components(separatedBy: .newlines)
        
        for line in lines {
            if line.hasPrefix("data: ") {
                let jsonString = String(line.dropFirst(6)) // Remove "data: "
                
                if jsonString.trimmingCharacters(in: .whitespaces) == "[DONE]" {
                    print("✅ Story generation completed (\(accumulatedText.count) characters)")
                    // Make sure final text is displayed
                    DispatchQueue.main.async { [weak self] in
                        self?.service?.generatedText = self?.accumulatedText ?? ""
                    }
                    completion(.success(accumulatedText))
                    return
                }
                
                if let jsonData = jsonString.data(using: .utf8),
                   let streamResponse = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                   let choices = streamResponse["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let delta = firstChoice["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    
                    // Use serial queue to ensure thread-safe updates
                    updateQueue.async { [weak self] in
                        guard let self = self else { return }
                                               
                        // Safely accumulate content on serial queue
                        self.accumulatedText += content
                        
                        // Only update UI every few characters to reduce race conditions
                        // This creates a better typing effect and reduces corruption risk
                        if self.accumulatedText.count % 5 == 0 || content.contains(" ") || content.contains(".") {
                            DispatchQueue.main.async {
                                self.service?.generatedText = self.accumulatedText
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didCompleteWithError error: Error?) {
        if let error = error {
            completion(.failure(.networkError(error)))
        } else {
            completion(.success(accumulatedText))
        }
    }
}

// MARK: - Data Models

struct StoryGenerationRequest {
    let ageGroup: String
    let storyLength: String
    let characters: [String]
    let setting: String
    let moralMessage: String
    let language: StoryLanguage
    let maxTokens: Int
    let selectedModel: String // "text" or "illustrations"
    
    init(ageGroup: String, storyLength: String, characters: [String], setting: String, moralMessage: String, language: StoryLanguage = .english, maxTokens: Int = 1500, selectedModel: String = "text") {
        self.ageGroup = ageGroup
        self.storyLength = storyLength
        self.characters = characters
        self.setting = setting
        self.moralMessage = moralMessage
        self.language = language
        self.maxTokens = maxTokens
        self.selectedModel = selectedModel
    }
}

enum StoryLanguage {
    case english
    case spanish
}

// MARK: - Error Types

enum DeepSeekError: Error, LocalizedError {
    case invalidURL
    case apiKeyError
    case networkError(Error)
    case invalidResponse
    case httpError(Int)
    case noData
    case jsonParsingError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .apiKeyError:
            return "Failed to retrieve API key"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .noData:
            return "No data received from server"
        case .jsonParsingError:
            return "Failed to parse JSON response"
        }
    }
} 