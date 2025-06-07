import SwiftUI
import CoreData

/// View for displaying user's saved stories in a grid layout
struct MyStoriesView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var authManager: AuthenticationManager
    @Binding var selectedTab: Int
    @State private var searchText = ""
    @State private var showingOnlyFavorites = false
    @State private var selectedAgeGroups: Set<String> = []
    @State private var selectedStoryLengths: Set<String> = []
    @State private var selectedLanguages: Set<String> = []
    @State private var selectedAIModels: Set<String> = []
    @State private var sortOption: SortOption = .newest
    @State private var viewMode: ViewMode = .grid
    @State private var selectedStory: StoryEntity?
    @State private var showingStoryDetail = false
    @State private var showingFilterSheet = false
    
    // Core Data fetch request
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)],
        animation: .default
    )
    private var stories: FetchedResults<StoryEntity>
    
    // Create a dynamic fetch request based on current user
    private var userStories: [StoryEntity] {
        guard let currentUserID = authManager.currentUser?.appleUserID else {
            return []
        }
        
        return stories.filter { story in
            story.userProfile?.appleUserID == currentUserID
        }
    }
    
    // Get unique values for filter options
    private var availableAgeGroups: Set<String> {
        Set(userStories.compactMap { $0.ageGroup })
    }
    
    private var availableStoryLengths: Set<String> {
        Set(userStories.compactMap { $0.storyLength })
    }
    
    private var availableLanguages: Set<String> {
        Set(userStories.compactMap { $0.language })
    }
    
    private var availableAIModels: Set<String> {
        Set(userStories.compactMap { $0.aiModel })
    }
    
    // Check if any filters are active
    private var hasActiveFilters: Bool {
        showingOnlyFavorites || 
        !selectedAgeGroups.isEmpty || 
        !selectedStoryLengths.isEmpty || 
        !selectedLanguages.isEmpty || 
        !selectedAIModels.isEmpty ||
        !searchText.isEmpty
    }
    
    // Count of active filter categories
    private var activeFilterCount: Int {
        var count = 0
        if showingOnlyFavorites { count += 1 }
        if !selectedAgeGroups.isEmpty { count += 1 }
        if !selectedStoryLengths.isEmpty { count += 1 }
        if !selectedLanguages.isEmpty { count += 1 }
        if !selectedAIModels.isEmpty { count += 1 }
        if !searchText.isEmpty { count += 1 }
        return count
    }
    
    enum ViewMode: String, CaseIterable {
        case grid = "grid"
        case list = "list"
        
        var icon: String {
            switch self {
            case .grid: return "grid"
            case .list: return "list.bullet"
            }
        }
        
        var label: String {
            switch self {
            case .grid: return "Grid View"
            case .list: return "List View"
            }
        }
    }
    
    enum SortOption: String, CaseIterable {
        case newest = "newest"
        case oldest = "oldest"
        case title = "title"
        case favorites = "favorites"
        
        var label: String {
            switch self {
            case .newest: return "Newest First"
            case .oldest: return "Oldest First"
            case .title: return "Title A-Z"
            case .favorites: return "Favorites First"
            }
        }
    }
    
    // Filter and sort stories
    private var filteredStories: [StoryEntity] {
        var filtered = userStories
        
        // Apply search filter (optimized for scalability - searches metadata only, not content)
        if !searchText.isEmpty {
            filtered = filtered.filter { story in
                story.title?.localizedCaseInsensitiveContains(searchText) == true ||
                story.characters?.localizedCaseInsensitiveContains(searchText) == true ||
                story.setting?.localizedCaseInsensitiveContains(searchText) == true ||
                story.ageGroup?.localizedCaseInsensitiveContains(searchText) == true ||
                story.moralMessage?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply favorites filter
        if showingOnlyFavorites {
            filtered = filtered.filter { $0.isFavorite }
        }
        
        // Apply age group filter
        if !selectedAgeGroups.isEmpty {
            filtered = filtered.filter { story in
                guard let ageGroup = story.ageGroup else { return false }
                return selectedAgeGroups.contains(ageGroup)
            }
        }
        
        // Apply story length filter
        if !selectedStoryLengths.isEmpty {
            filtered = filtered.filter { story in
                guard let storyLength = story.storyLength else { return false }
                return selectedStoryLengths.contains(storyLength)
            }
        }
        
        // Apply language filter
        if !selectedLanguages.isEmpty {
            filtered = filtered.filter { story in
                guard let language = story.language else { return false }
                return selectedLanguages.contains(language)
            }
        }
        
        // Apply AI model filter
        if !selectedAIModels.isEmpty {
            filtered = filtered.filter { story in
                guard let aiModel = story.aiModel else { return false }
                return selectedAIModels.contains(aiModel)
            }
        }
        
        // Apply sorting
        switch sortOption {
        case .newest:
            filtered.sort { ($0.createdDate ?? Date.distantPast) > ($1.createdDate ?? Date.distantPast) }
        case .oldest:
            filtered.sort { ($0.createdDate ?? Date.distantPast) < ($1.createdDate ?? Date.distantPast) }
        case .title:
            filtered.sort { ($0.title ?? "") < ($1.title ?? "") }
        case .favorites:
            filtered.sort { story1, story2 in
                if story1.isFavorite && !story2.isFavorite { return true }
                if !story1.isFavorite && story2.isFavorite { return false }
                return (story1.createdDate ?? Date.distantPast) > (story2.createdDate ?? Date.distantPast)
            }
        }
        
        return filtered
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Search and Filter Section
            searchAndFilterSection
            
            // Active Filters Display
            if hasActiveFilters {
                activeFiltersSection
            }
            
            // Content Section
            contentSection
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
        .sheet(isPresented: $showingStoryDetail) {
            if let selectedStory = selectedStory {
                StoryDetailView(story: selectedStory)
                    .environment(\.managedObjectContext, viewContext)
            }
        }
        .sheet(isPresented: $showingFilterSheet) {
            FilterOptionsSheet(
                selectedAgeGroups: $selectedAgeGroups,
                selectedStoryLengths: $selectedStoryLengths,
                selectedLanguages: $selectedLanguages,
                selectedAIModels: $selectedAIModels,
                availableAgeGroups: availableAgeGroups,
                availableStoryLengths: availableStoryLengths,
                availableLanguages: availableLanguages,
                availableAIModels: availableAIModels
            )
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My Stories")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("\(filteredStories.count) \(filteredStories.count == 1 ? "story" : "stories")")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // View Mode Toggle
                Button(action: {
                    viewMode = viewMode == .grid ? .list : .grid
                }) {
                    Image(systemName: viewMode == .grid ? "list.bullet" : "grid")
                        .font(.title2)
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .accessibilityLabel("Toggle \(viewMode == .grid ? "list" : "grid") view")
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }
    
    // MARK: - Search and Filter Section
    private var searchAndFilterSection: some View {
        VStack(spacing: 12) {
            // Search Bar
            HStack {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                    
                    TextField("Search titles, characters, settings...", text: $searchText)
                        .textFieldStyle(PlainTextFieldStyle())
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.gray.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                if !searchText.isEmpty {
                    Button("Clear") {
                        searchText = ""
                    }
                    .foregroundColor(.blue)
                    .font(.subheadline)
                }
            }
            
            // Quick Filter Options Row
            HStack {
                // Favorites Filter
                Button(action: {
                    showingOnlyFavorites.toggle()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: showingOnlyFavorites ? "heart.fill" : "heart")
                            .font(.caption)
                        Text("Favorites")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(showingOnlyFavorites ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        showingOnlyFavorites ?
                        Color.pink.opacity(0.8) :
                        Color.gray.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
                
                // Advanced Filters Button
                Button(action: {
                    showingFilterSheet = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .font(.caption)
                        Text("Filters")
                            .font(.caption)
                            .fontWeight(.medium)
                        if activeFilterCount > 1 || (activeFilterCount > 0 && !showingOnlyFavorites && searchText.isEmpty) {
                            Text("(\(activeFilterCount))")
                                .font(.caption2)
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(activeFilterCount > 1 || (activeFilterCount > 0 && !showingOnlyFavorites && searchText.isEmpty) ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        activeFilterCount > 1 || (activeFilterCount > 0 && !showingOnlyFavorites && searchText.isEmpty) ?
                        Color.blue.opacity(0.8) :
                        Color.gray.opacity(0.1)
                    )
                    .clipShape(Capsule())
                }
                
                Spacer()
                
                // Sort Menu
                Menu {
                    ForEach(SortOption.allCases, id: \.self) { option in
                        Button(action: {
                            sortOption = option
                        }) {
                            Label(option.label, systemImage: sortOption == option ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.caption)
                        Text(sortOption.label)
                            .font(.caption)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.down")
                            .font(.caption2)
                    }
                    .foregroundColor(.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Active Filters Section
    private var activeFiltersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                // Search filter indicator
                if !searchText.isEmpty {
                    FilterChip(
                        title: "Search: \(searchText)",
                        isActive: true,
                        onRemove: { searchText = "" }
                    )
                }
                
                // Favorites filter indicator
                if showingOnlyFavorites {
                    FilterChip(
                        title: "Favorites",
                        isActive: true,
                        onRemove: { showingOnlyFavorites = false }
                    )
                }
                
                // Age group filters
                ForEach(Array(selectedAgeGroups), id: \.self) { ageGroup in
                    FilterChip(
                        title: ageGroup.capitalized,
                        isActive: true,
                        onRemove: { selectedAgeGroups.remove(ageGroup) }
                    )
                }
                
                // Story length filters
                ForEach(Array(selectedStoryLengths), id: \.self) { length in
                    FilterChip(
                        title: length.capitalized,
                        isActive: true,
                        onRemove: { selectedStoryLengths.remove(length) }
                    )
                }
                
                // Language filters
                ForEach(Array(selectedLanguages), id: \.self) { language in
                    FilterChip(
                        title: language.capitalized,
                        isActive: true,
                        onRemove: { selectedLanguages.remove(language) }
                    )
                }
                
                // AI model filters
                ForEach(Array(selectedAIModels), id: \.self) { model in
                    FilterChip(
                        title: model.capitalized,
                        isActive: true,
                        onRemove: { selectedAIModels.remove(model) }
                    )
                }
                
                // Clear all filters button
                if hasActiveFilters {
                    Button("Clear All") {
                        clearAllFilters()
                    }
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        ScrollView {
            if filteredStories.isEmpty {
                emptyStateView
            } else {
                if viewMode == .grid {
                    gridView
                } else {
                    listView
                }
            }
        }
        .refreshable {
            // Refresh stories when pulled down
            try? viewContext.save()
        }
    }
    
    // MARK: - Grid View
    private var gridView: some View {
        LazyVGrid(
            columns: [
                GridItem(.adaptive(minimum: 160, maximum: 200), spacing: 16)
            ],
            spacing: 16
        ) {
            ForEach(filteredStories, id: \.objectID) { story in
                StoryCard(story: story, viewMode: .grid) {
                    // Handle story tap
                    openStory(story)
                } onFavorite: {
                    toggleFavorite(story)
                } onDelete: {
                    deleteStory(story)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    // MARK: - List View
    private var listView: some View {
        LazyVStack(spacing: 12) {
            ForEach(filteredStories, id: \.objectID) { story in
                StoryCard(story: story, viewMode: .list) {
                    // Handle story tap
                    openStory(story)
                } onFavorite: {
                    toggleFavorite(story)
                } onDelete: {
                    deleteStory(story)
                }
            }
        }
        .padding(.horizontal)
        .padding(.bottom, 32)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.closed")
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.6))
            
            VStack(spacing: 8) {
                Text("No Stories Found")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                Text(searchText.isEmpty && !showingOnlyFavorites ?
                     "Create your first magical story!" :
                     "Try adjusting your search or filters")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if searchText.isEmpty && !showingOnlyFavorites {
                Button("Create New Story") {
                    // Switch to the Create Story tab
                    selectedTab = 0
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    // MARK: - Actions
    private func openStory(_ story: StoryEntity) {
        selectedStory = story
        showingStoryDetail = true
    }
    
    private func toggleFavorite(_ story: StoryEntity) {
        story.isFavorite.toggle()
        
        do {
            try viewContext.save()
        } catch {
            print("Error toggling favorite: \(error)")
        }
    }
    
    private func deleteStory(_ story: StoryEntity) {
        viewContext.delete(story)
        
        do {
            try viewContext.save()
        } catch {
            print("Error deleting story: \(error)")
        }
    }
    
    private func clearAllFilters() {
        showingOnlyFavorites = false
        selectedAgeGroups.removeAll()
        selectedStoryLengths.removeAll()
        selectedLanguages.removeAll()
        selectedAIModels.removeAll()
        searchText = ""
    }
}

// MARK: - FilterChip Component
struct FilterChip: View {
    let title: String
    let isActive: Bool
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
            
            if isActive {
                Button(action: onRemove) {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .fontWeight(.bold)
                }
            }
        }
        .foregroundColor(isActive ? .white : .primary)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            isActive ?
            Color.blue.opacity(0.8) :
            Color.gray.opacity(0.1)
        )
        .clipShape(Capsule())
    }
}

// MARK: - FilterOptionsSheet Component
struct FilterOptionsSheet: View {
    @Binding var selectedAgeGroups: Set<String>
    @Binding var selectedStoryLengths: Set<String>
    @Binding var selectedLanguages: Set<String>
    @Binding var selectedAIModels: Set<String>
    
    let availableAgeGroups: Set<String>
    let availableStoryLengths: Set<String>
    let availableLanguages: Set<String>
    let availableAIModels: Set<String>
    
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Age Groups Section
                    if !availableAgeGroups.isEmpty {
                        FilterSection(
                            title: "Age Groups",
                            icon: "person.3",
                            options: Array(availableAgeGroups).sorted(),
                            selectedOptions: $selectedAgeGroups
                        )
                    }
                    
                    // Story Length Section
                    if !availableStoryLengths.isEmpty {
                        FilterSection(
                            title: "Story Length",
                            icon: "text.alignleft",
                            options: Array(availableStoryLengths).sorted(),
                            selectedOptions: $selectedStoryLengths
                        )
                    }
                    
                    // Language Section
                    if !availableLanguages.isEmpty {
                        FilterSection(
                            title: "Language",
                            icon: "globe",
                            options: Array(availableLanguages).sorted(),
                            selectedOptions: $selectedLanguages
                        )
                    }
                    
                    // AI Model Section
                    if !availableAIModels.isEmpty {
                        FilterSection(
                            title: "AI Model",
                            icon: "brain.head.profile",
                            options: Array(availableAIModels).sorted(),
                            selectedOptions: $selectedAIModels
                        )
                    }
                }
                .padding()
            }
            .navigationTitle("Filter Stories")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Clear All") {
                        selectedAgeGroups.removeAll()
                        selectedStoryLengths.removeAll()
                        selectedLanguages.removeAll()
                        selectedAIModels.removeAll()
                    }
                    .foregroundColor(.red)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }
}

// MARK: - FilterSection Component
struct FilterSection: View {
    let title: String
    let icon: String
    let options: [String]
    @Binding var selectedOptions: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.blue)
                    .font(.title3)
                
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if !selectedOptions.isEmpty {
                    Text("\(selectedOptions.count)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue)
                        .clipShape(Capsule())
                }
            }
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 100), spacing: 8)
            ], spacing: 8) {
                ForEach(options, id: \.self) { option in
                    FilterOptionButton(
                        title: option.capitalized,
                        isSelected: selectedOptions.contains(option)
                    ) {
                        if selectedOptions.contains(option) {
                            selectedOptions.remove(option)
                        } else {
                            selectedOptions.insert(option)
                        }
                    }
                }
            }
        }
    }
}

// MARK: - FilterOptionButton Component
struct FilterOptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.caption)
                        .fontWeight(.bold)
                }
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                isSelected ?
                Color.blue :
                Color.gray.opacity(0.1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview
struct MyStoriesView_Previews: PreviewProvider {
    static var previews: some View {
        MyStoriesView(selectedTab: .constant(1))
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
            .environmentObject(AuthenticationManager())
    }
} 