//
//  AuthenticationManager.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import Foundation
import AuthenticationServices
import Combine

@MainActor
class AuthenticationManager: NSObject, ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: UserPreferences?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaultsKey = "katarite_user_preferences"
    
    // Development mode flag - set to true when Apple Developer Program is not available
    private let isDevelopmentMode = true // Change to false when you have Apple Developer Program
    
    override init() {
        super.init()
        loadUserFromStorage()
    }
    
    // MARK: - Authentication Methods
    func signInWithApple() async {
        isLoading = true
        errorMessage = nil
        
        if isDevelopmentMode {
            await signInWithMockApple()
        } else {
            await signInWithRealApple()
        }
    }
    
    // MARK: - Mock Apple Sign-In (Development)
    private func signInWithMockApple() async {
        // Simulate network delay
        try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
        
        // Create mock user
        let mockUserID = "mock_apple_user_\(UUID().uuidString.prefix(8))"
        let mockUser = UserPreferences(
            appleUserID: mockUserID,
            childName: "Test Child" // Mock name
        )
        
        currentUser = mockUser
        isAuthenticated = true
        saveUserToStorage()
        isLoading = false
        
        print("🧪 Mock Apple Sign-In successful for development")
    }
    
    // MARK: - Real Apple Sign-In (Production)
    private func signInWithRealApple() async {
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    // MARK: - Sign Out
    func signOut() async {
        isAuthenticated = false
        currentUser = nil
        clearUserFromStorage()
        
        if isDevelopmentMode {
            print("🧪 Mock sign out completed")
        }
    }
    
    // MARK: - Profile Management
    func updateProfile(childName: String?, preferredLanguage: Language, defaultAgeGroup: AgeGroup) async {
        guard let user = currentUser else { return }
        
        let updatedUser = UserPreferences(
            id: user.id,
            appleUserID: user.appleUserID,
            childName: childName,
            preferredLanguage: preferredLanguage,
            defaultAgeGroup: defaultAgeGroup,
            apiKeys: user.apiKeys
        )
        
        currentUser = updatedUser
        saveUserToStorage()
    }
    
    func updateAPIKeys(_ apiKeys: APIKeys) async {
        guard let user = currentUser else { return }
        
        let updatedUser = UserPreferences(
            id: user.id,
            appleUserID: user.appleUserID,
            childName: user.childName,
            preferredLanguage: user.preferredLanguage,
            defaultAgeGroup: user.defaultAgeGroup,
            apiKeys: apiKeys
        )
        
        currentUser = updatedUser
        saveUserToStorage()
    }
    
    // MARK: - Development Helpers
    var authenticationMode: String {
        return isDevelopmentMode ? "Development (Mock)" : "Production (Real Apple Sign-In)"
    }
    
    func switchToDevelopmentMode() {
        // This would be used when transitioning between modes
        // In practice, you'd change the isDevelopmentMode flag and rebuild
        print("⚠️ To switch modes, change isDevelopmentMode flag and rebuild the app")
    }
    
    // MARK: - Local Storage
    private func saveUserToStorage() {
        guard let user = currentUser else { return }
        
        do {
            let data = try JSONEncoder().encode(user)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        } catch {
            print("Failed to save user to storage: \(error)")
        }
    }
    
    private func loadUserFromStorage() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else { return }
        
        do {
            let user = try JSONDecoder().decode(UserPreferences.self, from: data)
            currentUser = user
            isAuthenticated = true
            
            if isDevelopmentMode {
                print("🧪 Loaded mock user from storage: \(user.displayName)")
            }
        } catch {
            print("Failed to load user from storage: \(error)")
            clearUserFromStorage()
        }
    }
    
    private func clearUserFromStorage() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}

// MARK: - ASAuthorizationControllerDelegate (Production Only)
extension AuthenticationManager: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard !isDevelopmentMode else {
            print("⚠️ Real Apple Sign-In called in development mode")
            return
        }
        
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userID = appleIDCredential.user
            
            let user = UserPreferences(
                appleUserID: userID,
                childName: appleIDCredential.fullName?.givenName
            )
            
            currentUser = user
            isAuthenticated = true
            saveUserToStorage()
            
            print("✅ Real Apple Sign-In successful")
        }
        
        isLoading = false
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        guard !isDevelopmentMode else {
            print("⚠️ Real Apple Sign-In error in development mode: \(error)")
            return
        }
        
        errorMessage = "Apple Sign-In failed: \(error.localizedDescription)"
        isLoading = false
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding (Production Only)
extension AuthenticationManager: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
} 