import SwiftUI

struct ContentView: View {
    @StateObject private var languageManager = LanguageManager.shared
    @State private var includeImages: Bool = false
    @State private var selectedAgeGroup: AgeGroup = .preschooler
    @State private var selectedLength: StoryLength = .medium
    @State private var characters: String = ""
    @State private var setting: String = ""
    @State private var moralMessage: String = ""
    @State private var showStoryGeneration = false
    @State private var isGenerating = false
    
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
                        Text(languageManager.isSpanish ? "Crear Nueva Historia" : "Create New Story")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(languageManager.isSpanish ? 
                            "Personaliza tu aventura única" : 
                            "Personalize your unique adventure")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Age Group Selection
                    FormSection(title: languageManager.isSpanish ? "Grupo de Edad" : "Age Group", icon: "person.2") {
                        VStack(spacing: 12) {
                            SelectionCard(
                                title: languageManager.isSpanish ? "Pequeños" : "Toddler",
                                subtitle: languageManager.isSpanish ? "Edades 2-3 • Palabras y conceptos simples" : "Ages 2-3 • Simple words and concepts",
                                isSelected: selectedAgeGroup == .toddler
                            ) {
                                selectedAgeGroup = .toddler
                            }
                            
                            SelectionCard(
                                title: languageManager.isSpanish ? "Preescolar" : "Preschooler",
                                subtitle: languageManager.isSpanish ? "Edades 4-5 • Aventuras emocionantes" : "Ages 4-5 • Engaging adventures",
                                isSelected: selectedAgeGroup == .preschooler
                            ) {
                                selectedAgeGroup = .preschooler
                            }
                            
                            SelectionCard(
                                title: languageManager.isSpanish ? "Primaria" : "Elementary",
                                subtitle: languageManager.isSpanish ? "Edades 6-8 • Historias complejas con lecciones" : "Ages 6-8 • Complex stories with lessons",
                                isSelected: selectedAgeGroup == .elementary
                            ) {
                                selectedAgeGroup = .elementary
                            }
                        }
                    }
                    
                    // Story Length
                    FormSection(title: languageManager.isSpanish ? "Longitud de Historia" : "Story Length", icon: "book") {
                        HStack(spacing: 12) {
                            SelectionCard(
                                title: languageManager.isSpanish ? "Corta" : "Short",
                                subtitle: languageManager.isSpanish ? "~2-3 minutos" : "~2-3 minutes",
                                isSelected: selectedLength == .short
                            ) {
                                selectedLength = .short
                            }
                            
                            SelectionCard(
                                title: languageManager.isSpanish ? "Mediana" : "Medium",
                                subtitle: languageManager.isSpanish ? "~5-7 minutos" : "~5-7 minutes",
                                isSelected: selectedLength == .medium
                            ) {
                                selectedLength = .medium
                            }
                            
                            SelectionCard(
                                title: languageManager.isSpanish ? "Larga" : "Long",
                                subtitle: languageManager.isSpanish ? "~10-12 minutos" : "~10-12 minutes",
                                isSelected: selectedLength == .long
                            ) {
                                selectedLength = .long
                            }
                        }
                    }
                    
                    // Include Images Toggle
                    FormSection(title: languageManager.isSpanish ? "Incluir Imágenes" : "Include Images", icon: "photo") {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(languageManager.isSpanish ? "Agregar ilustraciones" : "Add illustrations")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Text(languageManager.isSpanish ? 
                                    "Las imágenes hacen la historia más visual y atractiva" : 
                                    "Images make the story more visual and engaging")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Toggle("", isOn: $includeImages)
                                .toggleStyle(SwitchToggleStyle(tint: .purple))
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Story Details
                    VStack(spacing: 16) {
                        // Characters Input
                        VStack(alignment: .leading, spacing: 8) {
                            Label(languageManager.isSpanish ? "Personajes" : "Characters", systemImage: "person.3")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                CustomTextField(
                                    placeholder: languageManager.isSpanish ? 
                                        "ej., Un ratoncito valiente llamado Max" : 
                                        "e.g., A brave little mouse named Max",
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
                            Label(languageManager.isSpanish ? "Escenario" : "Setting", systemImage: "location")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                CustomTextField(
                                    placeholder: languageManager.isSpanish ? 
                                        "ej., Un bosque mágico con árboles parlantes" : 
                                        "e.g., A magical forest with talking trees",
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
                            Label(languageManager.isSpanish ? "Mensaje Moral" : "Moral Message", systemImage: "heart")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            HStack {
                                CustomTextField(
                                    placeholder: languageManager.isSpanish ? 
                                        "ej., La amistad es el tesoro más grande" : 
                                        "e.g., Friendship is the greatest treasure",
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
                            
                            Text(isGenerating ? 
                                (languageManager.isSpanish ? "Creando tu historia..." : "Creating your story...") : 
                                (languageManager.isSpanish ? "Generar Historia" : "Generate Story"))
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
                    ageGroup: selectedAgeGroup.rawValue,
                    storyLength: selectedLength.rawValue,
                    characters: [characters],
                    setting: setting,
                    moralMessage: moralMessage,
                    language: languageManager.currentLanguage.toStoryLanguage,
                    maxTokens: 1500,
                    selectedModel: includeImages ? "illustrations" : "text"
                )
            )
        }
    }
    
    private var isFormValid: Bool {
        !characters.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !setting.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !moralMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func generateStory() {
        isGenerating = true
        showStoryGeneration = true
    }
    
    // Random generation methods
    private func randomizeCharacters() {
        let languageKey = languageManager.isSpanish ? "spanish" : "english"
        if let options = randomCharacters[languageKey] {
            characters = options.randomElement() ?? ""
        }
    }
    
    private func randomizeSetting() {
        let languageKey = languageManager.isSpanish ? "spanish" : "english"
        if let options = randomSettings[languageKey] {
            setting = options.randomElement() ?? ""
        }
    }
    
    private func randomizeMoral() {
        let languageKey = languageManager.isSpanish ? "spanish" : "english"
        if let options = randomMorals[languageKey] {
            moralMessage = options.randomElement() ?? ""
        }
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