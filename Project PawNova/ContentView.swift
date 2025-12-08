import SwiftUI
import SwiftData
import PhotosUI
import AVKit

enum InputMode {
    case text
    case photo
}

enum AspectRatio: String, CaseIterable {
    case tiktok = "9:16"
    case youtube = "16:9"
    case instagram = "1:1"

    var displayName: String {
        switch self {
        case .tiktok: return "TikTok"
        case .youtube: return "YouTube"
        case .instagram: return "Instagram"
        }
    }

    var icon: String {
        switch self {
        case .tiktok: return "rectangle.portrait"
        case .youtube: return "rectangle"
        case .instagram: return "square"
        }
    }
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \PetVideo.timestamp, order: .reverse) private var videos: [PetVideo]

    @State private var promptText = ""
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showError = false
    @State private var generatedVideoURL: URL?
    @State private var currentPrompt: String?
    @State private var showGeneratedVideo = false

    // Photo picker states
    @State private var inputMode: InputMode = .text
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoImage: UIImage?
    @State private var showCamera = false

    // Model selection
    @State private var selectedModel: AIModel = .veo3Fast

    // Video settings
    @State private var selectedAspectRatio: AspectRatio = .youtube
    @State private var aiEnhanceEnabled: Bool = true

    // User's credit balance (persisted)
    @AppStorage("userCredits") private var userCredits: Int = 5000

    // Subscription state (from UserDefaults via OnboardingManager pattern)
    @AppStorage("isSubscribed") private var isSubscribed: Bool = false

    // Payment gate states
    @State private var showPaywall = false
    @State private var showInsufficientCredits = false
    @State private var showConfirmGeneration = false

    var body: some View {
        ZStack {
            // Background
            Color.pawBackground.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerView

                    // Input Mode Tabs
                    inputModeTabs

                    // Input Area (Text or Photo)
                    if inputMode == .text {
                        textInputCard
                    } else {
                        photoInputCard
                    }

                    // Adventure Style (Model Selector)
                    modelSelectorCard

                    // Aspect Ratio Picker
                    aspectRatioCard

                    // AI Enhance Prompt Toggle
                    aiEnhanceCard

                    // Generate Button
                    generateButton

                    // Loading indicator
                    if isGenerating {
                        loadingView
                    }

                    // History Section
                    if !videos.isEmpty {
                        historySection
                    }
                }
                .padding()
            }
        }
        .preferredColorScheme(.dark)
        .alert("Oops!", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "Something went wrong")
        }
        // Confirmation before generating
        .alert("Create Video?", isPresented: $showConfirmGeneration) {
            Button("Cancel", role: .cancel) {}
            Button("Create") {
                Task {
                    await generateAdventure()
                }
            }
        } message: {
            Text("This will use \(selectedModel.credits) credits.\n\nYour balance: \(userCredits) credits")
        }
        // Insufficient credits alert
        .alert("Insufficient Credits", isPresented: $showInsufficientCredits) {
            Button("OK", role: .cancel) {}
            Button("Get More") {
                // TODO: Navigate to credits purchase
            }
        } message: {
            Text("You need \(selectedModel.credits) credits but only have \(userCredits).\n\nGet more credits to continue creating.")
        }
        // Paywall sheet for non-subscribers
        .sheet(isPresented: $showPaywall) {
            PaywallSheetView(isSubscribed: $isSubscribed)
        }
        // Full-screen generated video presentation
        .fullScreenCover(isPresented: $showGeneratedVideo) {
            if let videoURL = generatedVideoURL, let prompt = currentPrompt {
                GeneratedVideoSheet(
                    videoURL: videoURL,
                    prompt: prompt,
                    onSave: {
                        saveToHistory()
                    },
                    onDiscard: {
                        discardGeneration()
                    }
                )
            }
        }
    }

    // MARK: - Header View

    private var headerView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "pawprint.fill")
                    .font(.title)
                    .foregroundStyle(LinearGradient.pawPrimary)

                Text("PawNova")
                    .font(.largeTitle.bold())
                    .foregroundStyle(LinearGradient.pawPrimary)

                Spacer()

                // Credits display
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.pawPrimary)
                    Text("\(userCredits)")
                        .font(.headline.bold())
                        .foregroundColor(.pawTextPrimary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.pawCard)
                .clipShape(Capsule())
            }

            Text("Bring your pet's adventure to life")
                .font(.subheadline)
                .foregroundColor(.pawTextSecondary)
        }
    }

    // MARK: - Input Mode Tabs

    private var inputModeTabs: some View {
        HStack(spacing: 12) {
            // Text Tab
            Button {
                withAnimation(.spring(response: 0.3)) {
                    inputMode = .text
                }
            } label: {
                HStack {
                    Image(systemName: "text.bubble.fill")
                    Text("Text Adventure")
                }
                .font(.subheadline.bold())
                .foregroundColor(inputMode == .text ? .white : .pawTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    inputMode == .text
                        ? LinearGradient.pawPrimary
                        : LinearGradient.pawCard
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            // Photo Tab
            Button {
                withAnimation(.spring(response: 0.3)) {
                    inputMode = .photo
                }
            } label: {
                HStack {
                    Image(systemName: "photo.on.rectangle.angled")
                    Text("Photo Adventure")
                }
                .font(.subheadline.bold())
                .foregroundColor(inputMode == .photo ? .white : .pawTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    inputMode == .photo
                        ? LinearGradient.pawPrimary
                        : LinearGradient.pawCard
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Text Input Card

    private var textInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.pawPrimary)
                Text("Describe Your Pet's Adventure")
                    .font(.headline)
                    .foregroundColor(.pawTextPrimary)
            }

            Text("Be creative! Describe the scene, action, and setting.")
                .font(.caption)
                .foregroundColor(.pawTextSecondary)

            TextField("E.g., 'My golden retriever running through a magical forest at sunset'",
                     text: $promptText,
                     axis: .vertical)
                .textFieldStyle(.plain)
                .padding()
                .background(Color.pawBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .foregroundColor(.pawTextPrimary)
                .lineLimit(4, reservesSpace: true)

            Text("\(promptText.count)/500")
                .font(.caption2)
                .foregroundColor(.pawTextSecondary)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Photo Input Card

    private var photoInputCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "photo.fill")
                    .foregroundColor(.pawSecondary)
                Text("Upload Your Pet's Photo")
                    .font(.headline)
                    .foregroundColor(.pawTextPrimary)
            }

            if let image = selectedPhotoImage {
                // Show selected image
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        Button {
                            selectedPhotoImage = nil
                            selectedPhotoItem = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding(8)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    )

                // Prompt for photo
                TextField("What adventure should your pet have?",
                         text: $promptText,
                         axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color.pawBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .foregroundColor(.pawTextPrimary)
            } else {
                // Photo picker buttons
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhotoItem,
                                matching: .images) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Choose from Library")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(LinearGradient.pawSuccess)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Button {
                        showCamera = true
                    } label: {
                        HStack {
                            Image(systemName: "camera.fill")
                            Text("Take Photo")
                        }
                        .font(.subheadline.bold())
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.pawAccent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.vertical)
            }
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: selectedPhotoItem) { _, newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    selectedPhotoImage = image
                }
            }
        }
    }

    // MARK: - Model Selector Card

    private var modelSelectorCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .foregroundColor(.pawAccent)
                Text("Adventure Style")
                    .font(.headline)
                    .foregroundColor(.pawTextPrimary)
            }

            // Model options
            ForEach(AIModel.allCases, id: \.self) { model in
                Button {
                    selectedModel = model
                } label: {
                    HStack(spacing: 12) {
                        // Selection indicator
                        Image(systemName: selectedModel == model ? "checkmark.circle.fill" : "circle")
                            .foregroundColor(selectedModel == model ? .pawPrimary : .pawTextSecondary)

                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(modelDisplayName(model))
                                    .font(.subheadline.bold())
                                    .foregroundColor(.pawTextPrimary)

                                if model == .veo3Fast {
                                    Text("Popular")
                                        .font(.caption2.bold())
                                        .foregroundColor(.pawSuccess)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.pawSuccess.opacity(0.2))
                                        .clipShape(Capsule())
                                } else if model == .hailuo02 {
                                    Text("Best Value")
                                        .font(.caption2.bold())
                                        .foregroundColor(.pawSecondary)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.pawSecondary.opacity(0.2))
                                        .clipShape(Capsule())
                                }
                            }

                            Text(model.description)
                                .font(.caption)
                                .foregroundColor(.pawTextSecondary)

                            Text("\(model.duration) • \(model.provider)")
                                .font(.caption2)
                                .foregroundColor(.pawTextSecondary.opacity(0.7))
                        }

                        Spacer()

                        // Credit cost
                        HStack(spacing: 4) {
                            Image(systemName: "leaf.fill")
                                .font(.caption)
                            Text("\(model.credits)")
                                .font(.caption.bold())
                        }
                        .foregroundColor(.pawSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.pawSecondary.opacity(0.2))
                        .clipShape(Capsule())
                    }
                    .padding()
                    .background(
                        selectedModel == model
                            ? Color.pawPrimary.opacity(0.1)
                            : Color.pawBackground
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                selectedModel == model ? Color.pawPrimary : Color.clear,
                                lineWidth: 2
                            )
                    )
                }
            }
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Aspect Ratio Card

    private var aspectRatioCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "viewfinder")
                    .foregroundColor(.pawAccent)
                Text("Video Format")
                    .font(.headline)
                    .foregroundColor(.pawTextPrimary)
            }

            HStack(spacing: 12) {
                ForEach(AspectRatio.allCases, id: \.self) { ratio in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedAspectRatio = ratio
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: ratio.icon)
                                .font(.title2)
                                .foregroundColor(selectedAspectRatio == ratio ? .white : .pawTextSecondary)

                            VStack(spacing: 2) {
                                Text(ratio.displayName)
                                    .font(.caption.bold())
                                Text(ratio.rawValue)
                                    .font(.caption2)
                            }
                            .foregroundColor(selectedAspectRatio == ratio ? .white : .pawTextSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            selectedAspectRatio == ratio
                                ? AnyShapeStyle(LinearGradient.pawPrimary)
                                : AnyShapeStyle(Color.pawBackground)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedAspectRatio == ratio ? Color.pawPrimary : Color.pawTextSecondary.opacity(0.3),
                                    lineWidth: selectedAspectRatio == ratio ? 2 : 1
                                )
                        )
                    }
                }
            }
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - AI Enhance Card

    private var aiEnhanceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Toggle(isOn: $aiEnhanceEnabled) {
                HStack(spacing: 12) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.pawAccent)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Enhance Prompt")
                            .font(.headline)
                            .foregroundColor(.pawTextPrimary)

                        Text("Let AI refine your prompt for better results")
                            .font(.caption)
                            .foregroundColor(.pawTextSecondary)
                    }
                }
            }
            .tint(.pawPrimary)
        }
        .padding()
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Generate Button

    private var generateButton: some View {
        VStack(spacing: 8) {
            // Credit cost indicator
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Cost: \(selectedModel.credits) credits")
                    .font(.caption)
            }
            .foregroundColor(.pawTextSecondary)

            Button {
                handleGeneratePressed()
            } label: {
                HStack {
                    if isGenerating {
                        ProgressView()
                            .tint(.white)
                    }
                    Image(systemName: "sparkles")
                    Text(isGenerating ? "Creating Magic..." : "Create Adventure")
                        .font(.headline.bold())
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isGenerating || !canGenerate
                        ? AnyShapeStyle(Color.gray)
                        : AnyShapeStyle(LinearGradient.pawPrimary)
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .disabled(isGenerating || !canGenerate)
        }
    }

    /// Handle generate button press - check subscription and credits first
    private func handleGeneratePressed() {
        // Check subscription first
        guard isSubscribed else {
            Haptic.medium()
            showPaywall = true
            return
        }

        // Check sufficient credits
        guard userCredits >= selectedModel.credits else {
            Haptic.error()
            showInsufficientCredits = true
            return
        }

        // Show confirmation with cost
        Haptic.light()
        showConfirmGeneration = true
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.pawPrimary)

            VStack(spacing: 8) {
                Text("Creating Your Pet's Adventure")
                    .font(.headline)
                    .foregroundColor(.pawTextPrimary)

                Text("This may take up to 30 seconds")
                    .font(.caption)
                    .foregroundColor(.pawTextSecondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .background(Color.pawCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - History Section

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Pet's Adventures")
                .font(.headline)
                .foregroundColor(.pawTextPrimary)

            ForEach(videos.prefix(5)) { video in
                HStack(spacing: 12) {
                    // Thumbnail placeholder
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.pawCard)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "pawprint.fill")
                                .foregroundColor(.pawPrimary.opacity(0.3))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text(video.prompt)
                            .font(.subheadline)
                            .foregroundColor(.pawTextPrimary)
                            .lineLimit(2)

                        Text(video.timestamp, style: .relative)
                            .font(.caption)
                            .foregroundColor(.pawTextSecondary)
                    }

                    Spacer()
                }
                .padding()
                .background(Color.pawCard.opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }

    // MARK: - Helper Functions

    private var canGenerate: Bool {
        if inputMode == .text {
            return !promptText.isEmpty
        } else {
            return selectedPhotoImage != nil && !promptText.isEmpty
        }
    }

    private func modelDisplayName(_ model: AIModel) -> String {
        switch model {
        case .veo3Fast: return "Fast Paws"
        case .veo3Standard: return "Premium Paws"
        case .kling25: return "Action Paws"
        case .hailuo02: return "Portrait Paws"
        }
    }

    private func generateAdventure() async {
        guard canGenerate else { return }

        // Deduct credits upfront
        let creditCost = selectedModel.credits
        userCredits -= creditCost

        isGenerating = true
        errorMessage = nil

        do {
            // TODO: Upload photo if in photo mode
            let imageUrl: String? = nil

            // Enhance prompt if AI enhancement is enabled
            let finalPrompt = aiEnhanceEnabled
                ? FalService.shared.enhancePrompt(promptText)
                : promptText

            // Convert aspect ratio to API format
            let aspectRatioString = selectedAspectRatio.rawValue

            let videoUrl = try await FalService.shared.generateVideo(
                prompt: finalPrompt,
                model: selectedModel,
                aspectRatio: aspectRatioString,
                imageUrl: imageUrl
            )

            await MainActor.run {
                generatedVideoURL = URL(string: videoUrl)
                currentPrompt = finalPrompt  // Save enhanced prompt
                isGenerating = false
                Haptic.success()
                // Present full-screen video sheet
                showGeneratedVideo = true
            }
        } catch {
            await MainActor.run {
                // Refund credits on failure
                userCredits += creditCost
                errorMessage = error.localizedDescription
                showError = true
                isGenerating = false
            }
        }
    }

    private func saveToHistory() {
        guard let videoURL = generatedVideoURL,
              let prompt = currentPrompt else { return }

        let video = PetVideo(prompt: prompt, generatedURL: videoURL)
        modelContext.insert(video)
        try? modelContext.save()

        // Clear after saving
        clearGenerationState()
    }

    private func discardGeneration() {
        // Clear without saving
        clearGenerationState()
    }

    private func clearGenerationState() {
        generatedVideoURL = nil
        currentPrompt = nil
        promptText = ""
        selectedPhotoImage = nil
    }
}

#Preview {
    ContentView()
        .modelContainer(PersistenceController.preview.container)
}

// MARK: - Paywall Sheet View

/// Sheet version of paywall for in-app subscription prompt
struct PaywallSheetView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var isSubscribed: Bool

    @State private var selectedPlan: SubscriptionPlan = .yearly
    @State private var isLoading = false

    private let features = [
        ("wand.and.stars", "Unlimited AI video generation"),
        ("film.stack", "Access Veo 3 & Sora 2 models"),
        ("square.and.arrow.up", "Export in Full HD"),
        ("sparkles", "5,000 credits monthly")
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.pawBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(LinearGradient.pawPrimary)
                                    .frame(width: 70, height: 70)

                                Image(systemName: "crown.fill")
                                    .font(.system(size: 30, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            Text("Unlock PawNova Pro")
                                .font(.title2.bold())
                                .foregroundColor(.pawTextPrimary)

                            Text("Subscribe to create unlimited pet videos")
                                .font(.subheadline)
                                .foregroundColor(.pawTextSecondary)
                        }
                        .padding(.top)

                        // Features
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(features, id: \.0) { icon, text in
                                HStack(spacing: 12) {
                                    Image(systemName: icon)
                                        .font(.body.bold())
                                        .foregroundColor(.pawSecondary)
                                        .frame(width: 24)

                                    Text(text)
                                        .font(.subheadline)
                                        .foregroundColor(.pawTextPrimary)
                                }
                            }
                        }
                        .padding()
                        .background(Color.pawCard)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Plan selection
                        VStack(spacing: 12) {
                            ForEach(SubscriptionPlan.allCases) { plan in
                                Button {
                                    Haptic.selection()
                                    selectedPlan = plan
                                } label: {
                                    HStack {
                                        Circle()
                                            .strokeBorder(selectedPlan == plan ? Color.pawSecondary : Color.pawTextSecondary.opacity(0.3), lineWidth: 2)
                                            .background(
                                                Circle()
                                                    .fill(selectedPlan == plan ? Color.pawSecondary : Color.clear)
                                                    .padding(4)
                                            )
                                            .frame(width: 24, height: 24)

                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 8) {
                                                Text(plan.title)
                                                    .font(.headline)
                                                    .foregroundColor(.pawTextPrimary)

                                                if let savings = plan.savings {
                                                    Text(savings)
                                                        .font(.caption2.bold())
                                                        .foregroundColor(.pawBackground)
                                                        .padding(.horizontal, 8)
                                                        .padding(.vertical, 3)
                                                        .background(Color.pawSecondary)
                                                        .clipShape(Capsule())
                                                }
                                            }

                                            Text(plan.perMonth)
                                                .font(.caption)
                                                .foregroundColor(.pawTextSecondary)
                                        }

                                        Spacer()

                                        Text(plan.price)
                                            .font(.title3.bold())
                                            .foregroundColor(.pawTextPrimary)
                                    }
                                    .padding(16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.pawCard)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(
                                                        selectedPlan == plan ? Color.pawSecondary : Color.clear,
                                                        lineWidth: 2
                                                    )
                                            )
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        // Subscribe button
                        Button {
                            subscribe()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView()
                                        .tint(.pawBackground)
                                }
                                Text("Subscribe Now")
                                    .font(.headline.bold())
                            }
                            .foregroundColor(.pawBackground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(LinearGradient.pawButton)
                            .clipShape(Capsule())
                        }
                        .disabled(isLoading)

                        // Footer
                        Text("Cancel anytime in App Store settings")
                            .font(.caption)
                            .foregroundColor(.pawTextSecondary)
                    }
                    .padding()
                }
            }
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
    }

    private func subscribe() {
        isLoading = true
        Haptic.medium()

        // Simulate subscription (demo mode processes this instantly, real mode would call RevenueCat)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isLoading = false
            isSubscribed = true
            Haptic.success()
            dismiss()
        }
    }
}
