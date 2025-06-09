import SwiftUI
import CoreData

/// Subscription view showing current plan, usage, and upgrade options
struct SubscriptionView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var currentPlan: SubscriptionPlan = .free
    @State private var usageData = UsageData()
    @State private var isLoading = true
    
    // Core Data fetch request for stories to calculate monthly usage
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \StoryEntity.createdDate, ascending: false)],
        animation: .default)
    private var stories: FetchedResults<StoryEntity>
    
    // Core Data fetch request for usage limits
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \UsageLimitsEntity.lastResetDate, ascending: false)],
        animation: .default)
    private var usageLimits: FetchedResults<UsageLimitsEntity>
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                if isLoading {
                    ProgressView("Loading usage data...")
                        .frame(maxWidth: .infinity, maxHeight: 200)
                } else {
                    // Current Plan Header
                    VStack(spacing: 16) {
                        Image(systemName: currentPlan.icon)
                            .font(.system(size: 50))
                            .foregroundColor(currentPlan.color)
                        
                        VStack(spacing: 4) {
                            Text(currentPlan.displayName)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text(currentPlan.price)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        // Status Badge
                        HStack {
                            Image(systemName: currentPlan == .free ? "clock" : "checkmark.circle.fill")
                                .foregroundColor(currentPlan == .free ? .orange : .green)
                            Text(currentPlan == .free ? "Free Plan Active" : "Premium Active")
                                .font(.caption)
                                .foregroundColor(currentPlan == .free ? .orange : .green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background((currentPlan == .free ? Color.orange : Color.green).opacity(0.1))
                        .cornerRadius(20)
                    }
                    .padding(.top, 20)
                    
                    // Usage Statistics
                    VStack(spacing: 16) {
                        HStack {
                            Text("Usage This Month")
                                .font(.headline)
                            Spacer()
                            Text(getCurrentMonthText())
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Stories Usage
                        UsageRow(
                            title: "Stories Created",
                            used: usageData.storiesThisMonth,
                            limit: usageData.storiesLimit,
                            icon: "book.fill",
                            color: .blue
                        )
                        
                        // Images Usage
                        UsageRow(
                            title: "Images Generated",
                            used: usageData.imagesThisMonth,
                            limit: usageData.imagesLimit,
                            icon: "photo.fill",
                            color: .green
                        )
                        
                        // Daily Usage (if applicable)
                        if let usageLimit = usageLimits.first {
                            UsageRow(
                                title: "Stories Today",
                                used: Int(usageLimit.dailyStoriesUsed),
                                limit: Int(usageLimit.dailyStoriesLimit),
                                icon: "calendar",
                                color: .orange
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Usage History Summary
                    VStack(spacing: 16) {
                        HStack {
                            Text("Usage Summary")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 8) {
                            SummaryRow(title: "Total Stories Created", value: "\(usageData.totalStories)")
                            SummaryRow(title: "Total Images Generated", value: "\(usageData.totalImages)")
                            SummaryRow(title: "Account Active Since", value: usageData.memberSince)
                            SummaryRow(title: "Average Stories/Month", value: String(format: "%.1f", usageData.averageStoriesPerMonth))
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Plan Features
                    VStack(spacing: 16) {
                        HStack {
                            Text("Current Plan Features")
                                .font(.headline)
                            Spacer()
                        }
                        
                        VStack(spacing: 12) {
                            ForEach(currentPlan.features, id: \.self) { feature in
                                FeatureRow(feature: feature, included: true)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Upgrade Options (if on free plan)
                    if currentPlan == .free {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Upgrade Options")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                PlanCard(plan: .premium, currentPlan: currentPlan) {
                                    // TODO: Implement upgrade
                                    print("Upgrade to Premium tapped")
                                }
                                
                                PlanCard(plan: .pro, currentPlan: currentPlan) {
                                    // TODO: Implement upgrade
                                    print("Upgrade to Pro tapped")
                                }
                            }
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                    
                    // Billing Information (if premium/pro)
                    if currentPlan != .free {
                        VStack(spacing: 16) {
                            HStack {
                                Text("Billing Information")
                                    .font(.headline)
                                Spacer()
                            }
                            
                            VStack(spacing: 12) {
                                BillingRow(title: "Next Billing Date", value: "January 15, 2025")
                                BillingRow(title: "Payment Method", value: "•••• 1234")
                                BillingRow(title: "Amount", value: currentPlan.price)
                            }
                            
                            Button("Manage Subscription") {
                                // TODO: Open subscription management
                            }
                            .foregroundColor(.purple)
                            .padding(.top, 8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
            }
        }
        .navigationTitle("Subscription")
        .navigationBarTitleDisplayMode(.large)
        .refreshable {
            await loadUsageData()
        }
        .onAppear {
            Task {
                await loadUsageData()
            }
        }
        .onChange(of: stories.count) { _, _ in
            Task {
                await loadUsageData()
            }
        }
    }
    
    @MainActor
    private func loadUsageData() async {
        isLoading = true
        
        // Calculate usage data from Core Data
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let storiesArray = Array(stories)
                let usageLimitsArray = Array(usageLimits)
                
                let newUsageData = calculateUsageData(
                    from: storiesArray,
                    usageLimits: usageLimitsArray
                )
                
                DispatchQueue.main.async {
                    self.usageData = newUsageData
                    self.isLoading = false
                    continuation.resume()
                }
            }
        }
    }
    
    private func calculateUsageData(from stories: [StoryEntity], usageLimits: [UsageLimitsEntity]) -> UsageData {
        var data = UsageData()
        
        // Get current month boundaries
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.dateInterval(of: .month, for: now)?.start ?? now
        
        // Calculate monthly usage
        let storiesThisMonth = stories.filter { story in
            guard let createdDate = story.createdDate else { return false }
            return createdDate >= startOfMonth
        }
        
        data.storiesThisMonth = storiesThisMonth.count
        data.imagesThisMonth = storiesThisMonth.filter { $0.hasImage }.count
        
        // Set limits based on current plan
        data.storiesLimit = currentPlan.monthlyStoriesLimit
        data.imagesLimit = currentPlan.monthlyImagesLimit
        
        // Calculate totals
        data.totalStories = stories.count
        data.totalImages = stories.filter { $0.hasImage }.count
        
        // Calculate member since date
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        
        if let oldestStory = stories.last {
            data.memberSince = dateFormatter.string(from: oldestStory.createdDate ?? now)
        } else {
            data.memberSince = dateFormatter.string(from: now)
        }
        
        // Calculate average stories per month
        if let oldestStory = stories.last,
           let oldestDate = oldestStory.createdDate {
            let monthsSinceFirst = calendar.dateComponents([.month], from: oldestDate, to: now).month ?? 1
            let months = max(monthsSinceFirst, 1)
            data.averageStoriesPerMonth = Double(stories.count) / Double(months)
        } else {
            data.averageStoriesPerMonth = 0.0
        }
        
        return data
    }
    
    private func getCurrentMonthText() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
}

/// Enhanced usage data model
struct UsageData {
    var storiesThisMonth: Int = 0
    var storiesLimit: Int = 50
    var imagesThisMonth: Int = 0
    var imagesLimit: Int = 150
    var totalStories: Int = 0
    var totalImages: Int = 0
    var memberSince: String = ""
    var averageStoriesPerMonth: Double = 0.0
}

/// Usage progress row component
struct UsageRow: View {
    let title: String
    let used: Int
    let limit: Int
    let icon: String
    let color: Color
    
    private var percentage: Double {
        limit > 0 ? Double(used) / Double(limit) : 0
    }
    
    private var isNearLimit: Bool {
        percentage >= 0.8
    }
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                Spacer()
                Text("\(used) / \(limit)")
                    .font(.caption)
                    .foregroundColor(isNearLimit ? .orange : .secondary)
                    .fontWeight(isNearLimit ? .medium : .regular)
            }
            
            ProgressView(value: percentage)
                .progressViewStyle(LinearProgressViewStyle(tint: isNearLimit ? .orange : color))
            
            if isNearLimit {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Approaching limit")
                        .font(.caption)
                        .foregroundColor(.orange)
                    Spacer()
                }
            }
        }
    }
}

/// Summary row component for usage history
struct SummaryRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
}

/// Feature row component
struct FeatureRow: View {
    let feature: String
    let included: Bool
    
    var body: some View {
        HStack {
            Image(systemName: included ? "checkmark.circle.fill" : "xmark.circle")
                .foregroundColor(included ? .green : .red)
            Text(feature)
                .font(.subheadline)
            Spacer()
        }
    }
}

/// Plan card component
struct PlanCard: View {
    let plan: SubscriptionPlan
    let currentPlan: SubscriptionPlan
    let onUpgrade: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(plan.displayName)
                        .font(.headline)
                        .foregroundColor(plan.color)
                    Text(plan.price)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Upgrade", action: onUpgrade)
                    .buttonStyle(.borderedProminent)
                    .tint(plan.color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                ForEach(plan.features.prefix(3), id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark")
                            .foregroundColor(plan.color)
                            .font(.caption)
                        Text(feature)
                            .font(.caption)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(plan.color.opacity(0.1))
        .cornerRadius(8)
    }
}

/// Billing information row
struct BillingRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.primary)
            Spacer()
            Text(value)
                .foregroundColor(.secondary)
        }
    }
}

/// Subscription plan model
enum SubscriptionPlan: CaseIterable {
    case free
    case premium
    case pro
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .premium: return "Premium"
        case .pro: return "Pro"
        }
    }
    
    var price: String {
        switch self {
        case .free: return "Free"
        case .premium: return "$4.99/month"
        case .pro: return "$9.99/month"
        }
    }
    
    var icon: String {
        switch self {
        case .free: return "star"
        case .premium: return "star.fill"
        case .pro: return "crown.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .free: return .gray
        case .premium: return .purple
        case .pro: return .orange
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "50 stories per month",
                "150 images per month",
                "Basic story templates",
                "English and Spanish",
                "Standard AI models"
            ]
        case .premium:
            return [
                "Unlimited stories",
                "500 images per month",
                "Premium story templates",
                "Priority AI processing",
                "Export to PDF",
                "Cloud backup"
            ]
        case .pro:
            return [
                "Unlimited everything",
                "Advanced AI models",
                "Custom story templates",
                "Priority support",
                "Early access features",
                "API access"
            ]
        }
    }
    
    var monthlyStoriesLimit: Int {
        switch self {
        case .free: return 50
        case .premium: return 500
        case .pro: return 1000
        }
    }
    
    var monthlyImagesLimit: Int {
        switch self {
        case .free: return 150
        case .premium: return 500
        case .pro: return 1000
        }
    }
}

#Preview {
    NavigationView {
        SubscriptionView()
    }
} 