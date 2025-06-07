import SwiftUI

struct ContentView: View {
    @State private var selectedLanguage: String = "English"
    @State private var selectedAgeGroup: String = "Preschooler"
    @State private var selectedLength: String = "Medium"
    @State private var selectedModel: String = "text"
    @State private var characters: String = ""
    @State private var setting: String = ""
    @State private var moralMessage: String = ""
    @State private var isGenerating: Bool = false
    @State private var showStoryGeneration = false
    
    // Random suggestions in both languages
    private let randomCharacters = [
        "english": [
            "A brave little mouse named Max",
            "Princess Luna and her magical cat",
            "Charlie the curious robot",
            "A friendly dragon named Spark",
            "Emma the adventurous explorer",
            "Captain Whiskers the pirate cat",
            "Oliver the wise owl",
            "Mia and her talking teddy bear",
            "Felix the forest fairy",
            "Ruby the rainbow unicorn"
        ],
        "spanish": [
            "Un ratoncito valiente llamado Max",
            "La Princesa Luna y su gato mágico",
            "Charlie el robot curioso",
            "Un dragón amigable llamado Chispa",
            "Emma la exploradora aventurera",
            "Capitán Bigotes el gato pirata",
            "Oliver el búho sabio",
            "Mía y su osito de peluche parlante",
            "Félix el hada del bosque",
            "Ruby el unicornio arcoíris"
        ]
    ]
    
    private let randomSettings = [
        "english": [
            "A magical forest with talking trees",
            "An underwater kingdom of mermaids",
            "A candy castle in the clouds",
            "A space station among the stars",
            "A cozy village by the sea",
            "An enchanted library with flying books",
            "A colorful garden full of butterflies",
            "A mountain village where it snows marshmallows",
            "A secret island with treasure",
            "A city where animals and humans live together"
        ],
        "spanish": [
            "Un bosque mágico con árboles parlantes",
            "Un reino submarino de sirenas",
            "Un castillo de dulces en las nubes",
            "Una estación espacial entre las estrellas",
            "Un pueblo acogedor junto al mar",
            "Una biblioteca encantada con libros voladores",
            "Un jardín colorido lleno de mariposas",
            "Un pueblo en la montaña donde nieva malvaviscos",
            "Una isla secreta con tesoros",
            "Una ciudad donde animales y humanos viven juntos"
        ]
    ]
    
    private let randomMorals = [
        "english": [
            "Friendship is the greatest treasure",
            "Being kind makes the world brighter",
            "It's okay to be different and unique",
            "Sharing brings joy to everyone",
            "Courage helps us overcome our fears",
            "Honesty builds trust with others",
            "Hard work pays off in the end",
            "Everyone deserves love and respect",
            "Helping others makes us feel good",
            "Believing in yourself is important"
        ],
        "spanish": [
            "La amistad es el tesoro más grande",
            "Ser amable hace el mundo más brillante",
            "Está bien ser diferente y único",
            "Compartir trae alegría a todos",
            "El valor nos ayuda a vencer nuestros miedos",
            "La honestidad construye confianza con otros",
            "El trabajo duro vale la pena al final",
            "Todos merecen amor y respeto",
            "Ayudar a otros nos hace sentir bien",
            "Creer en ti mismo es importante"
        ]
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Create Your Story")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Let's create a magical story together!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Language Selection
                    FormSection(title: "Language", icon: "globe") {
                        HStack(spacing: 12) {
                            SelectionCard(
                                title: "English",
                                subtitle: "🇺🇸",
                                isSelected: selectedLanguage == "English"
                            ) {
                                selectedLanguage = "English"
                            }
                            
                            SelectionCard(
                                title: "Español",
                                subtitle: "🇪🇸",
                                isSelected: selectedLanguage == "Español"
                            ) {
                                selectedLanguage = "Español"
                            }
                        }
                    }
                    
                    // Age Group Selection
                    FormSection(title: "Age Group", icon: "person.2") {
                        VStack(spacing: 12) {
                            SelectionCard(
                                title: "Toddler",
                                subtitle: "Ages 2-4 • Simple words and concepts",
                                isSelected: selectedAgeGroup == "Toddler"
                            ) {
                                selectedAgeGroup = "Toddler"
                            }
                            
                            SelectionCard(
                                title: "Preschooler",
                                subtitle: "Ages 4-6 • Engaging adventures",
                                isSelected: selectedAgeGroup == "Preschooler"
                            ) {
                                selectedAgeGroup = "Preschooler"
                            }
                            
                            SelectionCard(
                                title: "Elementary",
                                subtitle: "Ages 6-10 • Complex stories with lessons",
                                isSelected: selectedAgeGroup == "Elementary"
                            ) {
                                selectedAgeGroup = "Elementary"
                            }
                        }
                    }
                    
                    // Story Length
                    FormSection(title: "Story Length", icon: "book") {
                        HStack(spacing: 12) {
                            SelectionCard(
                                title: "Short",
                                subtitle: "~100 words • 2-3 minutes",
                                isSelected: selectedLength == "Short"
                            ) {
                                selectedLength = "Short"
                            }
                            
                            SelectionCard(
                                title: "Medium",
                                subtitle: "~200 words • 4-5 minutes",
                                isSelected: selectedLength == "Medium"
                            ) {
                                selectedLength = "Medium"
                            }
                            
                            SelectionCard(
                                title: "Long",
                                subtitle: "~300 words • 6-8 minutes",
                                isSelected: selectedLength == "Long"
                            ) {
                                selectedLength = "Long"
                            }
                        }
                    }
                    
                    // Story Type Selection
                    FormSection(title: "Story Type", icon: "sparkles") {
                        HStack(spacing: 12) {
                            SelectionCard(
                                title: "Text",
                                subtitle: "Story with words only",
                                isSelected: selectedModel == "text"
                            ) {
                                selectedModel = "text"
                            }
                            
                            SelectionCard(
                                title: "Text + Illustrations",
                                subtitle: "Story with beautiful pictures",
                                isSelected: selectedModel == "illustrations"
                            ) {
                                selectedModel = "illustrations"
                            }
                        }
                    }
                    
                    // Story Details
                    VStack(spacing: 16) {
                        // Characters Input
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Characters", systemImage: "person.3")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                CustomTextField(
                                    placeholder: selectedLanguage == "English" ? 
                                        "e.g., A brave little mouse named Max" : 
                                        "ej., Un ratoncito valiente llamado Max",
                                    text: $characters
                                )
                                
                                Button(action: {
                                    randomizeCharacters()
                                }) {
                                    Image(systemName: "dice")
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            LinearGradient(
                                                colors: [.purple, .pink],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .accessibilityLabel("Randomize characters")
                            }
                        }
                        
                        // Setting Input
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Setting", systemImage: "location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                CustomTextField(
                                    placeholder: selectedLanguage == "English" ? 
                                        "e.g., A magical forest with talking trees" : 
                                        "ej., Un bosque mágico con árboles parlantes",
                                    text: $setting
                                )
                                
                                Button(action: {
                                    randomizeSetting()
                                }) {
                                    Image(systemName: "dice")
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            LinearGradient(
                                                colors: [.blue, .cyan],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .accessibilityLabel("Randomize setting")
                            }
                        }
                        
                        // Moral Message Input
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Moral Message", systemImage: "heart")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                CustomTextField(
                                    placeholder: selectedLanguage == "English" ? 
                                        "e.g., Friendship is the greatest treasure" : 
                                        "ej., La amistad es el tesoro más grande",
                                    text: $moralMessage
                                )
                                
                                Button(action: {
                                    randomizeMoral()
                                }) {
                                    Image(systemName: "dice")
                                        .foregroundColor(.white)
                                        .frame(width: 44, height: 44)
                                        .background(
                                            LinearGradient(
                                                colors: [.green, .mint],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                .accessibilityLabel("Randomize moral message")
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(.ultraThinMaterial)
                    )
                    
                    // Generate Story Button
                    Button(action: generateStory) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "wand.and.stars")
                            }
                            
                            Text(isGenerating ? "Creating your story..." : "Generate Story")
                                .font(.headline)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [.purple, .pink] : [.gray.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .disabled(!isFormValid || isGenerating)
                    }
                    .padding(.top)
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(
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
            )
            .navigationBarHidden(true)
        }
        .fullScreenCover(isPresented: $showStoryGeneration) {
            StoryGenerationView(
                request: StoryGenerationRequest(
                    ageGroup: selectedAgeGroup,
                    storyLength: selectedLength,
                    characters: [characters],
                    setting: setting,
                    moralMessage: moralMessage,
                    language: selectedLanguage == "English" ? .english : .spanish,
                    maxTokens: 1500,
                    selectedModel: selectedModel
                )
            )
        }
    }
    
    private var isFormValid: Bool {
        !characters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !setting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !moralMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func randomizeCharacters() {
        let languageKey = selectedLanguage == "English" ? "english" : "spanish"
        if let options = randomCharacters[languageKey] {
            characters = options.randomElement() ?? ""
        }
    }
    
    private func randomizeSetting() {
        let languageKey = selectedLanguage == "English" ? "english" : "spanish"
        if let options = randomSettings[languageKey] {
            setting = options.randomElement() ?? ""
        }
    }
    
    private func randomizeMoral() {
        let languageKey = selectedLanguage == "English" ? "english" : "spanish"
        if let options = randomMorals[languageKey] {
            moralMessage = options.randomElement() ?? ""
        }
    }
    
    private func generateStory() {
        showStoryGeneration = true
    }
}

// MARK: - Supporting Views

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    let content: Content
    
    init(title: String, icon: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(title, systemImage: icon)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
        }
    }
}

struct SelectionCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(isSelected ? .white.opacity(0.9) : .secondary)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [.purple, .pink],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            colors: [.gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(
                        isSelected ? Color.clear : Color.gray.opacity(0.3),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    
    var body: some View {
        TextField(placeholder, text: $text, axis: .vertical)
            .lineLimit(2...4)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    ContentView()
} 