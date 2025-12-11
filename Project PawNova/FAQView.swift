//
//  FAQView.swift
//  Project PawNova
//
//  Frequently Asked Questions and Help Center
//

import SwiftUI

struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
    let category: FAQCategory
}

enum FAQCategory: String, CaseIterable {
    case credits = "Credits"
    case subscription = "Subscription"
    case videos = "Videos"
    case account = "Account"
    case troubleshooting = "Troubleshooting"

    var icon: String {
        switch self {
        case .credits: return "sparkles"
        case .subscription: return "crown"
        case .videos: return "film"
        case .account: return "person.circle"
        case .troubleshooting: return "wrench.and.screwdriver"
        }
    }
}

struct FAQView: View {
    @State private var searchText = ""
    @State private var expandedItems: Set<UUID> = []
    @State private var selectedCategory: FAQCategory?

    private let faqs: [FAQItem] = [
        // Credits
        FAQItem(
            question: "How do credits work?",
            answer: "Credits are used to generate videos. Each AI model costs a different amount of credits. Veo 3 Fast uses 1,000 credits, while premium models like Kling 2.5 use 3,000 credits. Your credit balance is shown at the top of the Create screen.",
            category: .credits
        ),
        FAQItem(
            question: "How do I get more credits?",
            answer: "You can purchase credit packs from the Store tab, or subscribe to PawNova Pro which includes 5,000 credits monthly plus unlimited generations at reduced rates.",
            category: .credits
        ),
        FAQItem(
            question: "Do credits expire?",
            answer: "Purchased credit packs never expire. Monthly subscription credits refresh each billing cycle - unused credits don't roll over.",
            category: .credits
        ),
        FAQItem(
            question: "What happens if generation fails?",
            answer: "If a video fails to generate, your credits are automatically refunded to your account. You'll see the refund immediately in your balance.",
            category: .credits
        ),

        // Subscription
        FAQItem(
            question: "What's included in PawNova Pro?",
            answer: "PawNova Pro includes: 5,000 monthly credits, access to all AI models (Veo 3, Kling 2.5, Hailuo), HD video export, priority processing, and cloud sync across devices.",
            category: .subscription
        ),
        FAQItem(
            question: "Can I cancel my subscription?",
            answer: "Yes, you can cancel anytime. Go to Settings > Manage Subscription, or cancel directly in the App Store. You'll keep access until the end of your billing period.",
            category: .subscription
        ),
        FAQItem(
            question: "What's the difference between monthly and yearly?",
            answer: "The yearly plan saves you 33% compared to monthly. You pay once per year and get the same features as monthly subscribers.",
            category: .subscription
        ),
        FAQItem(
            question: "How do I restore my purchase?",
            answer: "Go to the Store tab and tap 'Restore Purchases'. Make sure you're signed in with the same Apple ID you used to purchase.",
            category: .subscription
        ),

        // Videos
        FAQItem(
            question: "How long does video generation take?",
            answer: "Most videos generate in 30-60 seconds. Complex scenes or high-demand periods may take up to 2 minutes. You can close the app - we'll notify you when it's ready.",
            category: .videos
        ),
        FAQItem(
            question: "What video quality can I expect?",
            answer: "Videos are generated in HD quality (1080p). The aspect ratio depends on your selection: 16:9 for YouTube, 9:16 for TikTok, or 1:1 for Instagram.",
            category: .videos
        ),
        FAQItem(
            question: "Can I use generated videos commercially?",
            answer: "Yes! Videos you generate are yours to use. You can post them on social media, use them in projects, or share them however you like.",
            category: .videos
        ),
        FAQItem(
            question: "How do I save videos to my Photos?",
            answer: "Open the video from your Library, tap the share button, and select 'Save Video'. The video will be saved to your Camera Roll.",
            category: .videos
        ),
        FAQItem(
            question: "What makes a good prompt?",
            answer: "Be specific! Include your pet type, the action, setting, and mood. Example: 'Golden retriever puppy playing in autumn leaves at sunset, cinematic lighting' works better than just 'dog playing'.",
            category: .videos
        ),

        // Account
        FAQItem(
            question: "How do I sign in?",
            answer: "Tap the account section in Settings and use Sign in with Apple. This syncs your videos and purchases across all your devices.",
            category: .account
        ),
        FAQItem(
            question: "How do I delete my account?",
            answer: "Go to Settings > Danger Zone > Delete Account & Data. This permanently removes all your videos, settings, and account information. This action cannot be undone.",
            category: .account
        ),
        FAQItem(
            question: "Is my data private?",
            answer: "Yes. Your prompts and videos are processed securely and not shared with third parties. We don't use your content to train AI models. See our Privacy Policy for details.",
            category: .account
        ),

        // Troubleshooting
        FAQItem(
            question: "Video generation keeps failing",
            answer: "Try these steps: 1) Check your internet connection, 2) Simplify your prompt, 3) Avoid restricted content, 4) Restart the app. If issues persist, contact support.",
            category: .troubleshooting
        ),
        FAQItem(
            question: "App is running slowly",
            answer: "Try closing other apps, restarting the app, or restarting your device. Make sure you have enough storage space and are on a stable internet connection.",
            category: .troubleshooting
        ),
        FAQItem(
            question: "Videos won't play",
            answer: "Ensure you have a stable internet connection as videos stream from the cloud. Try refreshing the Library or restarting the app.",
            category: .troubleshooting
        ),
        FAQItem(
            question: "I didn't receive my credits",
            answer: "First, try restoring purchases in the Store tab. If credits still don't appear, contact support with your purchase receipt from Apple.",
            category: .troubleshooting
        ),
    ]

    var filteredFAQs: [FAQItem] {
        var items = faqs

        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }

        if !searchText.isEmpty {
            items = items.filter {
                $0.question.localizedCaseInsensitiveContains(searchText) ||
                $0.answer.localizedCaseInsensitiveContains(searchText)
            }
        }

        return items
    }

    var body: some View {
        ZStack {
            Color.pawBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Search bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.pawTextSecondary)
                        TextField("Search help articles...", text: $searchText)
                            .foregroundColor(.pawTextPrimary)
                    }
                    .padding()
                    .background(Color.pawCard)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Category filter
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            CategoryChip(
                                title: "All",
                                icon: "list.bullet",
                                isSelected: selectedCategory == nil
                            ) {
                                withAnimation { selectedCategory = nil }
                            }

                            ForEach(FAQCategory.allCases, id: \.self) { category in
                                CategoryChip(
                                    title: category.rawValue,
                                    icon: category.icon,
                                    isSelected: selectedCategory == category
                                ) {
                                    withAnimation { selectedCategory = category }
                                }
                            }
                        }
                    }

                    // FAQ items
                    if filteredFAQs.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "questionmark.circle")
                                .font(.largeTitle)
                                .foregroundColor(.pawTextSecondary)
                            Text("No results found")
                                .font(.headline)
                                .foregroundColor(.pawTextSecondary)
                            Text("Try a different search term")
                                .font(.caption)
                                .foregroundColor(.pawTextSecondary.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        LazyVStack(spacing: 12) {
                            ForEach(filteredFAQs) { faq in
                                FAQItemView(
                                    item: faq,
                                    isExpanded: expandedItems.contains(faq.id)
                                ) {
                                    withAnimation(.spring(response: 0.3)) {
                                        if expandedItems.contains(faq.id) {
                                            expandedItems.remove(faq.id)
                                        } else {
                                            expandedItems.insert(faq.id)
                                        }
                                    }
                                    Haptic.selection()
                                }
                            }
                        }
                    }

                    // Contact support section
                    VStack(spacing: 12) {
                        Text("Still need help?")
                            .font(.headline)
                            .foregroundColor(.pawTextPrimary)

                        if let supportURL = URL(string: "mailto:support@pawnova.app") {
                            Link(destination: supportURL) {
                                HStack {
                                    Image(systemName: "envelope.fill")
                                    Text("Contact Support")
                                }
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(LinearGradient.pawPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding()
                    .background(Color.pawCard)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                .padding()
            }
        }
        .navigationTitle("Help Center")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption.bold())
            }
            .foregroundColor(isSelected ? .white : .pawTextSecondary)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                isSelected
                    ? AnyShapeStyle(LinearGradient.pawPrimary)
                    : AnyShapeStyle(Color.pawCard)
            )
            .clipShape(Capsule())
        }
    }
}

struct FAQItemView: View {
    let item: FAQItem
    let isExpanded: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onTap) {
                HStack {
                    Image(systemName: item.category.icon)
                        .font(.subheadline)
                        .foregroundColor(.pawSecondary)
                        .frame(width: 24)

                    Text(item.question)
                        .font(.subheadline.bold())
                        .foregroundColor(.pawTextPrimary)
                        .multilineTextAlignment(.leading)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(.pawTextSecondary)
                }
                .padding()
            }

            if isExpanded {
                Text(item.answer)
                    .font(.subheadline)
                    .foregroundColor(.pawTextSecondary)
                    .padding(.horizontal)
                    .padding(.bottom)
                    .padding(.leading, 38)
            }
        }
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    NavigationStack {
        FAQView()
    }
}
