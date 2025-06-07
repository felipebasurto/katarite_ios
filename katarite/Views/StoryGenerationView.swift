import SwiftUI
import CoreData

/// View for displaying real-time story generation with streaming text
struct StoryGenerationView: View {
    let request: StoryGenerationRequest
    @StateObject private var deepSeekService = DeepSeekService.shared
    @StateObject private var geminiService = GeminiService.shared
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var tabSwitcher: TabSwitcher
    
    @State private var showTypingIndicator = true
    @State private var displayedText = ""
    @State private var animationTimer: Timer?
    @State private var showShareSheet = false
    @State private var generatedStory = ""
    
    // Save state management
    @State private var isSaving = false
    @State private var saveError: String?
    @State private var showSaveSuccess = false
    @State private var savedStoryTitle = ""
    
    // Computed properties for unified service handling
    private var isGenerating: Bool {
        if request.selectedModel == "illustrations" {
            return geminiService.isGenerating
        } else {
            return deepSeekService.isGenerating
        }
    }
    
    private var currentError: LocalizedError? {
        if request.selectedModel == "illustrations" {
            return geminiService.error
        } else {
            return deepSeekService.error
        }
    }
    
    private var generatedTextFromService: String {
        if request.selectedModel == "illustrations" {
            return geminiService.generatedText
        } else {
            return deepSeekService.generatedText
        }
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.purple.opacity(0.1),
                    Color.pink.opacity(0.1),
                    Color.blue.opacity(0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Navigation Header
                HStack {
                    Button(action: {
                        if isGenerating {
                            if request.selectedModel == "illustrations" {
                                geminiService.cancelGeneration()
                            } else {
                                deepSeekService.cancelGeneration()
                            }
                        }
                        dismiss()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(.purple)
                        .font(.headline)
                    }
                    
                    Spacer()
                    
                    Text("Story Generation")
                        .font(.headline)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    // Share button (visible when story is complete)
                    if !isGenerating && !displayedText.isEmpty {
                        Button(action: {
                            showShareSheet = true
                        }) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.purple)
                                .font(.headline)
                        }
                    } else {
                        // Invisible spacer to maintain alignment
                        Button(action: {}) {
                            Image(systemName: "square.and.arrow.up")
                                .foregroundColor(.clear)
                                .font(.headline)
                        }
                        .disabled(true)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
                
                Divider()
                    .padding(.top, 8)
                
                // Story Content Area
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Story parameters display
                        StoryParametersCard(request: request)
                        
                        // Story content area
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("Your Story", systemImage: "book.pages")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if isGenerating {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text("Writing...")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            // Story text display
                            VStack(alignment: .leading, spacing: 12) {
                                if displayedText.isEmpty && isGenerating {
                                    // Initial loading state
                                    HStack {
                                        Text("Starting to write your story")
                                            .foregroundColor(.secondary)
                                            .italic()
                                        
                                        if showTypingIndicator {
                                            TypingIndicator()
                                        }
                                    }
                                } else {
                                    // Story text with typing animation
                                    Text(displayedText)
                                        .font(.body)
                                        .lineSpacing(4)
                                        .animation(.easeInOut(duration: 0.3), value: displayedText)
                                    
                                    // Typing indicator at the end of text while generating
                                    if isGenerating && !displayedText.isEmpty {
                                        HStack {
                                            TypingIndicator()
                                            Spacer()
                                        }
                                    }
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(.ultraThinMaterial)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                        }
                        
                        // Error display
                        if let error = currentError {
                            ErrorView(error: error) {
                                startGeneration()
                            }
                        }
                        
                        // Save success message
                        if showSaveSuccess {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Story saved as '\(savedStoryTitle)'")
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.green.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                )
                            }
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: showSaveSuccess)
                        }
                        
                        // Save error message
                        if let error = saveError {
                            VStack(spacing: 8) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.subheadline)
                                        .fontWeight(.medium)
                                        .foregroundColor(.primary)
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(Color.orange.opacity(0.1))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 10)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                )
                                
                                Button("Dismiss") {
                                    saveError = nil
                                }
                                .font(.caption)
                                .foregroundColor(.orange)
                            }
                            .transition(.opacity.combined(with: .scale))
                            .animation(.easeInOut(duration: 0.3), value: saveError != nil)
                        }
                        
                        // Action buttons (when complete)
                        if !isGenerating && !displayedText.isEmpty && currentError == nil {
                            ActionButtonsView(
                                onRegenerate: { startGeneration() },
                                onSave: { saveStory() },
                                onShare: { showShareSheet = true },
                                isSaving: isSaving
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 20)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            startGeneration()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)) { _ in
            // Pause generation when app goes to background
            if isGenerating {
                if request.selectedModel == "illustrations" {
                    geminiService.cancelGeneration()
                } else {
                    deepSeekService.cancelGeneration()
                }
            }
        }
        .onChange(of: generatedTextFromService) { _, newText in
            updateDisplayedText(newText)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: [displayedText])
        }
    }
    
    // MARK: - Private Methods
    
    private func startGeneration() {
        displayedText = ""
        generatedStory = ""
        showTypingIndicator = true
        
        // Start the typing indicator animation
        animationTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { _ in
            showTypingIndicator.toggle()
        }
        
        // Call the appropriate service based on selected model
        if request.selectedModel == "illustrations" {
            // Convert request to GeminiStoryRequest format
            let geminiRequest = GeminiStoryRequest(
                ageGroup: request.ageGroup,
                storyLength: request.storyLength,
                characters: request.characters,
                setting: request.setting,
                moralMessage: request.moralMessage,
                language: request.language == .english ? "english" : "spanish",
                maxTokens: request.maxTokens
            )
            geminiService.generateStoryWithImagesStreaming(geminiRequest)
        } else {
            deepSeekService.generateStoryStreaming(request)
        }
    }
    
    private func updateDisplayedText(_ newText: String) {
        // Stop typing indicator when we start receiving text
        if !newText.isEmpty && animationTimer != nil {
            animationTimer?.invalidate()
            animationTimer = nil
            showTypingIndicator = false
        }
        
        // Simply update displayed text directly - the API streaming provides the natural typing effect
        displayedText = newText
        generatedStory = newText
    }
    
    private func saveStory() {
        guard !displayedText.isEmpty else {
            saveError = "No story content to save"
            return
        }
        
        guard let currentUserPrefs = authManager.currentUser else {
            saveError = "Please sign in to save stories"
            return
        }
        
        Task { @MainActor in
            isSaving = true
            saveError = nil
            
            do {
                // Get or create user profile in Core Data
                let coreDataManager = CoreDataManager.shared
                var userProfile = coreDataManager.fetchUserProfile(appleUserID: currentUserPrefs.appleUserID)
                
                if userProfile == nil {
                    // Create new user profile if it doesn't exist
                    userProfile = coreDataManager.createUserProfile(
                        appleUserID: currentUserPrefs.appleUserID,
                        childName: currentUserPrefs.childName,
                        preferredLanguage: currentUserPrefs.preferredLanguage.rawValue,
                        defaultAgeGroup: currentUserPrefs.defaultAgeGroup.rawValue
                    )
                }
                
                guard let profile = userProfile else {
                    throw NSError(domain: "StoryStorage", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create or find user profile"])
                }
                
                // Check if user can generate more stories (usage limits)
                guard coreDataManager.incrementStoryUsage(for: profile) else {
                    throw NSError(domain: "StoryStorage", code: 2, userInfo: [NSLocalizedDescriptionKey: "Daily story limit reached"])
                }
                
                // Generate a title from the first line or first few words
                let storyTitle = generateStoryTitle(from: displayedText)
                
                // Clean the story content to remove title duplication
                let cleanedContent = cleanStoryContent(from: displayedText, title: storyTitle)
                
                // Create generation parameters string
                let parametersDict: [String: Any] = [
                    "ageGroup": request.ageGroup,
                    "storyLength": request.storyLength,
                    "characters": request.characters,
                    "setting": request.setting,
                    "moralMessage": request.moralMessage,
                    "language": request.language == .english ? "english" : "spanish",
                    "maxTokens": request.maxTokens
                ]
                let parametersJSON = try JSONSerialization.data(withJSONObject: parametersDict, options: [])
                let parametersString = String(data: parametersJSON, encoding: .utf8) ?? ""
                
                // Save the story to Core Data
                let savedStory = coreDataManager.createStory(
                    title: storyTitle,
                    content: cleanedContent,
                    ageGroup: request.ageGroup,
                    language: request.language == .english ? "english" : "spanish",
                    characters: request.characters.joined(separator: ", "),
                    setting: request.setting,
                    moralMessage: request.moralMessage,
                    storyLength: request.storyLength,
                    aiModel: request.selectedModel == "illustrations" ? "gemini" : "deepseek",
                    imageData: nil, // TODO: Handle image data for Gemini stories
                    generationParameters: parametersString,
                    userProfile: profile
                )
                
                // Create analytics for the story
                _ = coreDataManager.createStoryAnalytics(
                    for: savedStory,
                    generationTimeMs: 0, // We could track this in the future
                    modelUsed: request.selectedModel == "illustrations" ? "gemini" : "deepseek",
                    success: true,
                    errorMessage: nil,
                    retryAttempts: 0,
                    parametersUsed: parametersString
                )
                
                // Success feedback
                savedStoryTitle = storyTitle
                showSaveSuccess = true
                
                // Hide success message and navigate to My Stories after a delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showSaveSuccess = false
                    // Navigate to My Stories tab
                    tabSwitcher.switchToMyStories()
                    // Dismiss the story generation view
                    dismiss()
                }
                
            } catch {
                saveError = error.localizedDescription
                print("Error saving story: \(error)")
            }
            
            isSaving = false
        }
    }
    
    /// Generate a meaningful title from story content and clean the content
    private func generateStoryTitle(from content: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        
        // Look for title in ** format first
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") && trimmed.count > 4 {
                // Extract title from **Title** format
                let startIndex = trimmed.index(trimmed.startIndex, offsetBy: 2)
                let endIndex = trimmed.index(trimmed.endIndex, offsetBy: -2)
                return String(trimmed[startIndex..<endIndex])
            }
        }
        
        // Try to use the first substantial non-empty line as fallback
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty && trimmed.count > 10 && !trimmed.hasPrefix("**") {
                // Take first sentence or first 50 characters, whichever is shorter
                if let sentenceEnd = trimmed.firstIndex(of: ".") {
                    let sentence = String(trimmed[..<sentenceEnd])
                    if sentence.count > 10 {
                        return sentence
                    }
                }
                
                // Fallback to first 50 characters
                if trimmed.count > 50 {
                    let index = trimmed.index(trimmed.startIndex, offsetBy: 47)
                    return String(trimmed[..<index]) + "..."
                }
                return trimmed
            }
        }
        
        // Fallback to generic title with timestamp
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return "Story \(formatter.string(from: Date()))"
    }
    
    /// Clean story content by removing title duplication and formatting markers
    private func cleanStoryContent(from content: String, title: String) -> String {
        let lines = content.components(separatedBy: .newlines)
        var cleanedLines: [String] = []
        var foundTitle = false
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip lines with ** title format
            if trimmed.hasPrefix("**") && trimmed.hasSuffix("**") {
                foundTitle = true
                continue
            }
            
            // Skip empty lines immediately after title
            if foundTitle && trimmed.isEmpty {
                continue
            }
            
            // Skip lines that exactly match the title
            if trimmed == title {
                foundTitle = true
                continue
            }
            
            // Skip lines that contain the title repeated at the start
            if trimmed.hasPrefix(title) && trimmed.count > title.count {
                let remainingText = trimmed.dropFirst(title.count).trimmingCharacters(in: .whitespacesAndNewlines)
                if !remainingText.isEmpty {
                    cleanedLines.append(remainingText)
                }
                foundTitle = true
                continue
            }
            
            foundTitle = false
            cleanedLines.append(line)
        }
        
        return cleanedLines.joined(separator: "\n").trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// MARK: - Supporting Views

struct StoryParametersCard: View {
    let request: StoryGenerationRequest
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Story Details", systemImage: "info.circle")
                .font(.headline)
                .foregroundColor(.primary)
            
            VStack(spacing: 8) {
                ParameterRow(title: "Age Group", value: request.ageGroup)
                ParameterRow(title: "Length", value: request.storyLength)
                ParameterRow(title: "Language", value: request.language == .english ? "English" : "Spanish")
                ParameterRow(title: "Characters", value: request.characters.joined(separator: ", "))
                ParameterRow(title: "Setting", value: request.setting)
                ParameterRow(title: "Moral", value: request.moralMessage)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ParameterRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title + ":")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)
            
            Text(value)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(2)
            
            Spacer()
        }
    }
}

struct TypingIndicator: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.purple.opacity(0.6))
                    .frame(width: 6, height: 6)
                    .scaleEffect(isAnimating ? 1.0 : 0.5)
                    .animation(
                        .easeInOut(duration: 0.6)
                        .repeatForever()
                        .delay(Double(index) * 0.2),
                        value: isAnimating
                    )
            }
        }
        .onAppear {
            isAnimating = true
        }
    }
}

struct ErrorView: View {
    let error: LocalizedError
    let onRetry: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .foregroundColor(.orange)
                .font(.largeTitle)
            
            Text("Oops! Something went wrong")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(error.localizedDescription)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again", action: onRetry)
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: [.purple, .pink],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
        )
    }
}

struct ActionButtonsView: View {
    let onRegenerate: () -> Void
    let onSave: () -> Void
    let onShare: () -> Void
    let isSaving: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                ActionButton(
                    title: "Regenerate",
                    icon: "arrow.clockwise",
                    colors: [.orange, .red],
                    action: onRegenerate,
                    isDisabled: isSaving
                )
                
                ActionButton(
                    title: isSaving ? "Saving..." : "Save Story",
                    icon: isSaving ? "clock" : "heart",
                    colors: [.green, .mint],
                    action: onSave,
                    isDisabled: isSaving,
                    isLoading: isSaving
                )
            }
            
            ActionButton(
                title: "Share Story",
                icon: "square.and.arrow.up",
                colors: [.blue, .cyan],
                action: onShare,
                isDisabled: isSaving
            )
        }
    }
}

struct ActionButton: View {
    let title: String
    let icon: String
    let colors: [Color]
    let action: () -> Void
    let isDisabled: Bool
    let isLoading: Bool
    
    init(title: String, icon: String, colors: [Color], action: @escaping () -> Void, isDisabled: Bool = false, isLoading: Bool = false) {
        self.title = title
        self.icon = icon
        self.colors = colors
        self.action = action
        self.isDisabled = isDisabled
        self.isLoading = isLoading
    }
    
    var body: some View {
        Button(action: isDisabled ? {} : action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Image(systemName: icon)
                }
                Text(title)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                LinearGradient(
                    colors: isDisabled ? [Color.gray, Color.gray.opacity(0.8)] : colors,
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .opacity(isDisabled ? 0.6 : 1.0)
        }
        .disabled(isDisabled)
    }
}

// MARK: - ShareSheet for iOS

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    StoryGenerationView(
        request: StoryGenerationRequest(
            ageGroup: "Preschooler",
            storyLength: "Medium",
            characters: ["A brave little mouse named Max"],
            setting: "A magical forest with talking trees",
            moralMessage: "Friendship is the greatest treasure",
            language: .english
        )
    )
} 