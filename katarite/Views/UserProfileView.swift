import SwiftUI
import CoreData

/// User Profile view showing account information and user details
struct UserProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    // Core Data fetch requests
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)],
        animation: .default)
    private var stories: FetchedResults<StoryEntity>
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UserProfileEntity.createdDate, ascending: true)],
        animation: .default)
    private var userProfiles: FetchedResults<UserProfileEntity>
    
    // Computed properties for real data
    private var userName: String {
        authManager.currentUser?.displayName ?? "Child"
    }
    
    private var appleUserID: String {
        authManager.currentUser?.appleUserID ?? "Unknown"
    }
    
    private var totalStories: Int {
        stories.count
    }
    
    private var favoriteStories: Int {
        stories.filter { $0.isFavorite }.count
    }
    
    private var memberSince: String {
        if let profile = userProfiles.first,
           let createdDate = profile.createdDate {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: createdDate)
        } else if authManager.currentUser != nil {
            // If no Core Data profile yet, use current date as fallback
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: Date())
        }
        return "Recently"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Profile Header
                VStack(spacing: 16) {
                    // Avatar
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.purple)
                        .accessibilityHidden(true)
                    
                    // User Info
                    VStack(spacing: 4) {
                        Text(userName)
                            .font(.title2)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(authManager.isAuthenticated ? "Signed in with Apple ID" : "Not signed in")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Status Badge
                    HStack {
                        Image(systemName: authManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(authManager.isAuthenticated ? .green : .red)
                            .accessibilityHidden(true)
                        Text(authManager.isAuthenticated ? "Account Active" : "Account Inactive")
                            .font(.caption)
                            .foregroundColor(authManager.isAuthenticated ? .green : .red)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background((authManager.isAuthenticated ? Color.green : Color.red).opacity(0.1))
                    .cornerRadius(20)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(authManager.isAuthenticated ? "Account is active and authenticated" : "Account is not authenticated")
                }
                .padding(.top, 20)
                
                // Account Information
                VStack(spacing: 0) {
                    ProfileInfoRow(title: "Account Type", value: "Apple ID")
                    Divider().padding(.leading, 16).accessibilityHidden(true)
                    ProfileInfoRow(title: "Member Since", value: memberSince)
                    Divider().padding(.leading, 16).accessibilityHidden(true)
                    ProfileInfoRow(title: "Stories Created", value: "\(totalStories)")
                    Divider().padding(.leading, 16).accessibilityHidden(true)
                    ProfileInfoRow(title: "Favorite Stories", value: "\(favoriteStories)")
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: colorScheme == .dark ? .clear : .gray.opacity(0.1), 
                            radius: 4, 
                            x: 0, 
                            y: 2
                        )
                )
                .padding(.horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Account Information")
                
                // Quick Actions
                VStack(spacing: 0) {
                    ActionRow(title: "Edit Profile", icon: "pencil", action: {
                        showEditProfile()
                    })
                    Divider().padding(.leading, 60).accessibilityHidden(true)
                    ActionRow(title: "Privacy Settings", icon: "hand.raised", action: {
                        showPrivacySettings()
                    })
                    Divider().padding(.leading, 60).accessibilityHidden(true)
                    ActionRow(title: "Data & Storage", icon: "externaldrive", action: {
                        showDataManagement()
                    })
                }
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                        .shadow(
                            color: colorScheme == .dark ? .clear : .gray.opacity(0.1), 
                            radius: 4, 
                            x: 0, 
                            y: 2
                        )
                )
                .padding(.horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Profile Actions")
                
                // Sign Out
                if authManager.isAuthenticated {
                    Button(action: {
                        Task {
                            await authManager.signOut()
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .accessibilityHidden(true)
                            Text("Sign Out")
                        }
                        .foregroundColor(.red)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                    .accessibilityLabel("Sign Out of Apple ID")
                    .accessibilityHint("Signs out of your account and returns to the sign-in screen")
                }
                
                Spacer(minLength: 20)
            }
        }
        .navigationTitle("User Profile")
        .navigationBarTitleDisplayMode(.large)
        .background(Color(.systemGroupedBackground))
        .accessibilityElement(children: .contain)
        .accessibilityLabel("User Profile")
    }
    
    // MARK: - Action Methods
    private func showEditProfile() {
        // TODO: Navigate to edit profile screen
        print("Edit Profile tapped - not yet implemented")
    }
    
    private func showPrivacySettings() {
        // TODO: Navigate to privacy settings screen
        print("Privacy Settings tapped - not yet implemented")
    }
    
    private func showDataManagement() {
        // TODO: Navigate to data management screen
        print("Data & Storage tapped - not yet implemented")
    }
}

/// Reusable row for displaying profile information
struct ProfileInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
                .font(.body)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
                .font(.body)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

/// Reusable row for profile actions
struct ActionRow: View {
    let title: String
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.purple)
                    .frame(width: 30, height: 30)
                    .accessibilityHidden(true)
                
                Text(title)
                    .foregroundColor(.primary)
                    .font(.body)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .accessibilityHidden(true)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityLabel(title)
        .accessibilityHint("Tap to configure \(title.lowercased())")
        .accessibilityAddTraits(.isButton)
    }
}

#Preview {
    NavigationView {
        UserProfileView()
            .environmentObject(AuthenticationManager())
            .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
    }
} 