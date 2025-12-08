//
//  GuidelinesView.swift
//  Project PawNova
//
//  Important guidelines popup for video generation
//

import SwiftUI

struct GuidelinesView: View {
    @Environment(\.dismiss) private var dismiss

    private let guidelines: [(icon: String, title: String, description: String)] = [
        ("globe", "English Prompts", "For best results, write your prompts in English. Other languages may produce inconsistent results."),
        ("clock", "Processing Time", "Video generation typically takes 30-60 seconds. Complex scenes may take longer."),
        ("sparkles", "Be Descriptive", "Include details about setting, lighting, and action. Example: 'Golden retriever running through autumn leaves at sunset'"),
        ("exclamationmark.triangle", "Content Guidelines", "Prompts must be family-friendly. Inappropriate content will be rejected."),
        ("arrow.clockwise", "Credits & Retries", "Credits are deducted when generation starts. If it fails, credits are automatically refunded."),
        ("photo", "Photo Tips", "For photo-to-video, use clear, well-lit images of your pet facing the camera.")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Header illustration
                        ZStack {
                            Circle()
                                .fill(LinearGradient.pawPrimary.opacity(0.2))
                                .frame(width: 80, height: 80)

                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 36))
                                .foregroundStyle(LinearGradient.pawPrimary)
                        }
                        .padding(.top, 8)

                        Text("Tips for Great Videos")
                            .font(.title2.bold())
                            .foregroundColor(.pawTextPrimary)

                        Text("Follow these guidelines for the best results")
                            .font(.subheadline)
                            .foregroundColor(.pawTextSecondary)

                        // Guidelines list
                        VStack(spacing: 12) {
                            ForEach(guidelines, id: \.title) { guideline in
                                GuidelineRow(
                                    icon: guideline.icon,
                                    title: guideline.title,
                                    description: guideline.description
                                )
                            }
                        }
                        .padding(.top, 8)

                        // Got it button
                        Button {
                            Haptic.light()
                            dismiss()
                        } label: {
                            Text("Got It!")
                                .font(.headline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient.pawPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 12)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.pawTextSecondary)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct GuidelineRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.pawSecondary)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundColor(.pawTextPrimary)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    GuidelinesView()
}
