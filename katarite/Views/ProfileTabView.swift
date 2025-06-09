import SwiftUI

/// Main Profile tab view that contains user profile, settings, statistics, and subscription sections
struct ProfileTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.managedObjectContext) private var viewContext
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.purple)
                            .accessibilityHidden(true)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Profile")
                                .font(.title2)
                                .fontWeight(.bold)
                                .accessibilityAddTraits(.isHeader)
                            
                            Text("Manage your account and preferences")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    
                    // Profile Menu Options
                    VStack(spacing: 0) {
                        NavigationLink(destination: UserProfileView()) {
                            ProfileMenuRowView(
                                title: "User Profile", 
                                subtitle: "Account information and settings",
                                icon: "person.circle"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("User Profile. Account information and settings")
                        .accessibilityHint("Navigate to user profile page")
                        
                        Divider()
                            .padding(.leading, 60)
                            .accessibilityHidden(true)
                        
                        NavigationLink(destination: AppSettingsView()) {
                            ProfileMenuRowView(
                                title: "Settings", 
                                subtitle: "App preferences and defaults",
                                icon: "gearshape"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Settings. App preferences and defaults")
                        .accessibilityHint("Navigate to app settings page")
                        
                        Divider()
                            .padding(.leading, 60)
                            .accessibilityHidden(true)
                        
                        NavigationLink(destination: UserStatisticsView()) {
                            ProfileMenuRowView(
                                title: "Statistics", 
                                subtitle: "Your story creation analytics",
                                icon: "chart.bar"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Statistics. Your story creation analytics")
                        .accessibilityHint("Navigate to statistics page")
                        
                        Divider()
                            .padding(.leading, 60)
                            .accessibilityHidden(true)
                        
                        NavigationLink(destination: SubscriptionView()) {
                            ProfileMenuRowView(
                                title: "Subscription", 
                                subtitle: "Billing and plan management",
                                icon: "crown"
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel("Subscription. Billing and plan management")
                        .accessibilityHint("Navigate to subscription page")
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
                    
                    Spacer(minLength: 20)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemGroupedBackground))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Profile section")
    }
}

/// Reusable row component for profile menu options
struct ProfileMenuRowView: View {
    let title: String
    let subtitle: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.purple)
                .frame(width: 30, height: 30)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.leading)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}

#Preview {
    ProfileTabView()
        .environmentObject(AuthenticationManager())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
} 