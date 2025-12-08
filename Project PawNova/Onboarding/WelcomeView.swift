//
//  WelcomeView.swift
//  Project PawNova
//
//  Combined welcome + auth screen.
//  Sign in with Apple or continue with email.
//

import SwiftUI
import AuthenticationServices

struct WelcomeView: View {
    @Environment(OnboardingManager.self) private var onboarding
    @Environment(\.colorScheme) private var colorScheme

    @State private var showEmailSignUp = false
    @State private var contentOpacity: Double = 0
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Animated aurora background
            auroraBackground

            VStack(spacing: 0) {
                Spacer()

                // Hero content
                VStack(spacing: 16) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(LinearGradient.pawPrimary)
                            .frame(width: 80, height: 80)

                        Image(systemName: "sparkles")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    Text("Create Magic")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.pawTextPrimary)

                    Text("Turn your pet photos into\nstunning AI videos")
                        .font(.body)
                        .foregroundColor(.pawTextSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 48)

                Spacer()

                // Auth buttons
                VStack(spacing: 16) {
                    // Sign in with Apple
                    SignInWithAppleButton(.continue) { request in
                        request.requestedScopes = [.fullName, .email]
                    } onCompletion: { result in
                        handleAppleSignIn(result)
                    }
                    .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                    .frame(height: 56)
                    .clipShape(Capsule())

                    // Email option
                    Button {
                        Haptic.light()
                        showEmailSignUp = true
                    } label: {
                        HStack {
                            Image(systemName: "envelope.fill")
                            Text("Continue with Email")
                        }
                        .font(.headline)
                        .foregroundColor(.pawTextPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.pawCard)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color.pawTextSecondary.opacity(0.3), lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)

                // Terms
                Text("By continuing, you agree to our Terms & Privacy Policy")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)

                // Dev skip option (DEBUG only)
                #if DEBUG
                Button {
                    Haptic.light()
                    onboarding.userName = "Test User"
                    onboarding.isAuthenticated = true
                    onboarding.nextStep()
                } label: {
                    Text("Skip (Dev Mode)")
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary.opacity(0.5))
                }
                .padding(.top, 8)
                #endif

                Spacer().frame(height: 34)
            }
            .opacity(contentOpacity)
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                animateGradient = true
            }
            withAnimation(.easeOut(duration: 0.5).delay(0.2)) {
                contentOpacity = 1
            }
        }
        .sheet(isPresented: $showEmailSignUp) {
            EmailSignUpView()
        }
    }

    // MARK: - Aurora Background

    private var auroraBackground: some View {
        ZStack {
            Color.pawBackground

            // Animated gradient
            LinearGradient(
                colors: [
                    Color.pawPrimary.opacity(0.3),
                    Color.pawBackground,
                    Color.pawSecondary.opacity(0.2)
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )

            // Top glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.pawPrimary.opacity(0.4), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 300)
                .offset(y: -250)

            // Bottom glow
            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [Color.pawSecondary.opacity(0.3), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 200)
                .offset(x: 80, y: 300)
        }
    }

    // MARK: - Apple Sign In

    private func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                if let fullName = appleIDCredential.fullName {
                    let name = [fullName.givenName, fullName.familyName]
                        .compactMap { $0 }
                        .joined(separator: " ")
                    if !name.isEmpty {
                        onboarding.userName = name
                    }
                }
                onboarding.isAuthenticated = true
                Haptic.success()
                onboarding.nextStep()
            }
        case .failure:
            Haptic.error()
        }
    }
}

// MARK: - Email Sign Up Sheet

struct EmailSignUpView: View {
    @Environment(OnboardingManager.self) private var onboarding
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var name = ""
    @State private var isLoading = false

    private var isValid: Bool {
        !email.isEmpty && email.contains("@") && !name.isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Your name")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)

                        TextField("", text: $name, prompt: Text("Enter name").foregroundColor(.pawTextSecondary.opacity(0.5)))
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(.pawTextPrimary)
                            .padding()
                            .background(Color.pawCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .textContentType(.name)
                            .autocorrectionDisabled()
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Email address")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)

                        TextField("", text: $email, prompt: Text("your@email.com").foregroundColor(.pawTextSecondary.opacity(0.5)))
                            .textFieldStyle(.plain)
                            .font(.body)
                            .foregroundColor(.pawTextPrimary)
                            .padding()
                            .background(Color.pawCard)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .textContentType(.emailAddress)
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                    }

                    Spacer()

                    Button {
                        continueWithEmail()
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.pawBackground)
                            }
                            Text("Continue")
                                .font(.headline.bold())
                        }
                        .foregroundColor(.pawBackground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(isValid ? LinearGradient.pawButton : LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing))
                        .clipShape(Capsule())
                    }
                    .disabled(!isValid || isLoading)
                }
                .padding(24)
            }
            .navigationTitle("Create Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pawTextSecondary)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func continueWithEmail() {
        isLoading = true
        Haptic.light()

        // Simulate account creation
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            onboarding.userName = name
            onboarding.isAuthenticated = true
            isLoading = false
            Haptic.success()
            dismiss()
            onboarding.nextStep()
        }
    }
}

#Preview {
    WelcomeView()
        .environment(OnboardingManager())
}
