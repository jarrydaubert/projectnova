//
//  LegalViews.swift
//  Project PawNova
//
//  Terms of Service and Privacy Policy views
//

import SwiftUI

// MARK: - Terms of Service

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)

                Group {
                    LegalSection(
                        title: "1. Acceptance of Terms",
                        content: "By downloading, installing, or using PawNova (\"the App\"), you agree to be bound by these Terms of Service. If you do not agree to these terms, do not use the App."
                    )

                    LegalSection(
                        title: "2. Description of Service",
                        content: "PawNova is an AI-powered video generation service that creates videos based on user-provided text prompts or images. The service uses third-party AI models to generate content."
                    )

                    LegalSection(
                        title: "3. User Accounts",
                        content: "You may be required to create an account to access certain features. You are responsible for:\n• Maintaining the confidentiality of your account\n• All activities that occur under your account\n• Notifying us immediately of any unauthorized use\n\nWe reserve the right to terminate accounts that violate these terms."
                    )

                    LegalSection(
                        title: "4. Credits and Payments",
                        content: "• Credits are used to generate videos and are non-refundable once used\n• Subscription credits refresh each billing cycle and do not roll over\n• Purchased credit packs do not expire\n• Prices are subject to change with notice\n• All purchases are processed through Apple's App Store"
                    )

                    LegalSection(
                        title: "5. Acceptable Use",
                        content: "You agree NOT to use the App to:\n• Generate illegal, harmful, or offensive content\n• Create content depicting violence, hate speech, or explicit material\n• Infringe on intellectual property rights\n• Impersonate others or create misleading content\n• Attempt to reverse engineer the AI models\n• Use automated systems to abuse the service\n\nWe reserve the right to refuse service and terminate accounts for violations."
                    )

                    LegalSection(
                        title: "6. Intellectual Property",
                        content: "• You retain rights to content you create using the App\n• You grant us a license to process your inputs to provide the service\n• The App, including its design and features, is our intellectual property\n• AI-generated content may be subject to limitations based on training data"
                    )

                    LegalSection(
                        title: "7. Disclaimers",
                        content: "THE SERVICE IS PROVIDED \"AS IS\" WITHOUT WARRANTIES OF ANY KIND. WE DO NOT GUARANTEE:\n• Continuous, uninterrupted access to the service\n• That generated content will meet your expectations\n• The accuracy or appropriateness of AI outputs\n• That the service will be error-free"
                    )

                    LegalSection(
                        title: "8. Limitation of Liability",
                        content: "TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, OR CONSEQUENTIAL DAMAGES ARISING FROM YOUR USE OF THE SERVICE."
                    )

                    LegalSection(
                        title: "9. Changes to Terms",
                        content: "We may update these terms at any time. Continued use of the App after changes constitutes acceptance of the new terms. We will notify users of significant changes."
                    )

                    LegalSection(
                        title: "10. Contact",
                        content: "For questions about these Terms, contact us at:\nsupport@pawnova.app"
                    )
                }
            }
            .padding()
        }
        .background(Color.pawBackground)
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Privacy Policy

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Last updated: December 2024")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)

                Group {
                    LegalSection(
                        title: "1. Information We Collect",
                        content: "We collect the following types of information:\n\nAccount Information:\n• Apple ID identifier (when using Sign in with Apple)\n• Display name (if provided)\n\nUsage Data:\n• Video generation prompts and settings\n• App usage statistics and crash reports\n• Purchase history\n\nDevice Information:\n• Device type and iOS version\n• App version"
                    )

                    LegalSection(
                        title: "2. How We Use Your Information",
                        content: "We use collected information to:\n• Provide and improve the video generation service\n• Process payments and manage subscriptions\n• Send service-related notifications\n• Analyze app performance and fix bugs\n• Prevent fraud and abuse"
                    )

                    LegalSection(
                        title: "3. AI Processing",
                        content: "Your prompts and images are processed by third-party AI services (fal.ai) to generate videos. Important notes:\n• Prompts are not used to train AI models\n• Generated videos are stored temporarily for delivery\n• We do not review or moderate individual prompts manually\n• Content filters are applied automatically"
                    )

                    LegalSection(
                        title: "4. Data Storage and Security",
                        content: "• Account data is stored securely using industry-standard encryption\n• Videos are stored in the cloud and on your device\n• We use secure connections (HTTPS) for all data transmission\n• Payment information is handled by Apple and never stored by us"
                    )

                    LegalSection(
                        title: "5. Data Sharing",
                        content: "We may share data with:\n• AI processing partners (fal.ai) to generate videos\n• Analytics services to improve the app\n• Law enforcement when required by law\n\nWe do NOT:\n• Sell your personal information\n• Share data for advertising purposes\n• Allow third parties to use your content"
                    )

                    LegalSection(
                        title: "6. Your Rights",
                        content: "You have the right to:\n• Access your personal data\n• Request deletion of your account and data\n• Export your generated videos\n• Opt out of analytics (via iOS settings)\n\nTo exercise these rights, contact support@pawnova.app"
                    )

                    LegalSection(
                        title: "7. Data Retention",
                        content: "• Account data is retained while your account is active\n• Generated videos are stored until you delete them\n• Deleted accounts and data are purged within 30 days\n• Some data may be retained for legal compliance"
                    )

                    LegalSection(
                        title: "8. Children's Privacy",
                        content: "PawNova is not intended for children under 13. We do not knowingly collect information from children. If you believe a child has provided us with personal information, please contact us."
                    )

                    LegalSection(
                        title: "9. International Users",
                        content: "Data may be processed in the United States and other countries. By using the App, you consent to this transfer. We comply with applicable data protection laws including GDPR for EU users."
                    )

                    LegalSection(
                        title: "10. Changes to This Policy",
                        content: "We may update this Privacy Policy periodically. We will notify you of significant changes through the App or via email."
                    )

                    LegalSection(
                        title: "11. Contact Us",
                        content: "For privacy-related questions or requests:\nEmail: support@pawnova.app\n\nData Protection Officer:\nprivacy@pawnova.app"
                    )
                }
            }
            .padding()
        }
        .background(Color.pawBackground)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
}

// MARK: - Supporting Views

struct LegalSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.pawTextPrimary)

            Text(content)
                .font(.subheadline)
                .foregroundColor(.pawTextSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview("Terms") {
    NavigationStack {
        TermsOfServiceView()
    }
}

#Preview("Privacy") {
    NavigationStack {
        PrivacyPolicyView()
    }
}
