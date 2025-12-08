//
//  PetNameView.swift
//  Project PawNova
//
//  Collects user's pet name for personalization.
//

import SwiftUI

struct PetNameView: View {
    @Environment(OnboardingManager.self) private var onboarding

    @State private var petName = ""
    @State private var contentOpacity: Double = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            VStack(spacing: 32) {
                // Back button
                HStack {
                    Button {
                        Haptic.light()
                        onboarding.previousStep()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3.bold())
                            .foregroundColor(.pawTextPrimary)
                            .padding(12)
                            .background(Color.pawCard)
                            .clipShape(Circle())
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)

                Spacer()

                // Content
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 12) {
                        Text("What's your pet's name?")
                            .font(.title.bold())
                            .foregroundColor(.pawTextPrimary)

                        Text("We'll use this to personalize your experience")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)
                    }

                    // Input field
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Pet Name")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)

                        HStack {
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.pawPrimary)
                            TextField("Enter your pet's name", text: $petName)
                                .foregroundColor(.white)
                                .focused($isInputFocused)
                                .submitLabel(.continue)
                                .onSubmit {
                                    if !petName.isEmpty {
                                        continueToNext()
                                    }
                                }
                        }
                        .padding()
                        .background(Color.pawCard)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)
                }
                .opacity(contentOpacity)

                Spacer()

                // Continue button
                VStack(spacing: 16) {
                    Button {
                        continueToNext()
                    } label: {
                        Text("Continue")
                            .font(.headline.bold())
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                petName.isEmpty
                                    ? LinearGradient(colors: [.gray], startPoint: .leading, endPoint: .trailing)
                                    : LinearGradient.pawButton
                            )
                            .clipShape(Capsule())
                    }
                    .disabled(petName.isEmpty)

                    // Skip option
                    Button {
                        Haptic.light()
                        onboarding.nextStep()
                    } label: {
                        Text("Skip for now")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 50)
                .opacity(contentOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.5)) {
                contentOpacity = 1
            }
            // Auto-focus input after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isInputFocused = true
            }
        }
    }

    private func continueToNext() {
        guard !petName.isEmpty else { return }
        onboarding.petName = petName
        Haptic.success()
        onboarding.nextStep()
    }
}

#Preview {
    PetNameView()
        .environment(OnboardingManager())
}
