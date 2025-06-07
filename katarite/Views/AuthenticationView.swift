//
//  AuthenticationView.swift
//  katarite
//
//  Created by Felipe Basurto on 2025-06-06.
//

import SwiftUI
import AuthenticationServices

struct AuthenticationView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // App Logo and Title
            VStack(spacing: 20) {
                Image(systemName: "book.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("Katarite")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Personalized bedtime stories for your child")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Development mode indicator
                Text("Mode: \(authManager.authenticationMode)")
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(8)
            }
            
            Spacer()
            
            // Sign In Section
            VStack(spacing: 20) {
                Text("Welcome to Katarite")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Sign in to create magical bedtime stories tailored just for your child")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Apple Sign-In Button
                SignInWithAppleButton(
                    onRequest: { request in
                        request.requestedScopes = [.fullName, .email]
                    },
                    onCompletion: { result in
                        Task {
                            await authManager.signInWithApple()
                        }
                    }
                )
                .signInWithAppleButtonStyle(.black)
                .frame(height: 50)
                .padding(.horizontal, 40)
                .disabled(authManager.isLoading)
                
                if authManager.isLoading {
                    ProgressView()
                        .scaleEffect(1.2)
                        .padding(.top, 10)
                }
                
                if let errorMessage = authManager.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.caption)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
            
            Spacer()
            
            // Privacy Notice
            VStack(spacing: 8) {
                Text("Privacy First")
                    .font(.headline)
                    .foregroundColor(.blue)
                
                Text("All your stories are stored locally on your device. We don't collect or store any personal data.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            .padding(.bottom, 30)
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
}

#Preview {
    AuthenticationView()
        .environmentObject(AuthenticationManager())
} 