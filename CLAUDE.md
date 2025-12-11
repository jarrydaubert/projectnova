# CLAUDE.md

## Project Overview

PawNova is an iOS 18+ app that generates AI pet videos using fal.ai. Supports 4 AI models: Veo 3 Fast, Veo 3 Pro (Google), Kling 2.5 (Kuaishou), Hailuo-02 (MiniMax). Three-tab navigation: Projects, Create, Settings. Demo mode enabled by default for free testing.

## Tech Stack

- **SwiftUI** - Declarative UI (iOS 18 features: MeshGradient, floating tab bar)
- **SwiftData** - Persistence (@Model, @Query, #Index, #Unique)
- **StoreKit 2** - Subscriptions & credit packs
- **TipKit** - Contextual tips
- **WidgetKit** - Interactive home screen widgets
- **ActivityKit** - Live Activities for Dynamic Island & Lock Screen
- **Foundation Models** - On-device AI prompt enhancement (iOS 18.1+)
- **async/await** - Concurrency
- **AVKit** - Video playback
- **os.Logger** - Logging (not print)
- **@Observable** - iOS 17+ state management
- Zero third-party dependencies (Firebase optional)

## Brand Colors (Aurora Theme)

```swift
// Primary palette - Purple + Mint
Color.pawPrimary    // #8B5CF6 - Violet
Color.pawSecondary  // #34D399 - Mint
Color.pawAccent     // #A78BFA - Light violet
Color.pawBackground // #0F0F1A - Near black
Color.pawCard       // #1A1A2E - Card background

// Gradients
LinearGradient.pawPrimary  // Purple → Mint
LinearGradient.pawButton   // Mint → Purple (CTAs)
```

## Commands

```bash
# Build
xcodebuild -scheme "Project PawNova" -destination "platform=iOS Simulator,name=iPhone 17 Pro" build

# Test
xcodebuild test -scheme "Project PawNova" -destination "platform=iOS Simulator,name=iPhone 17 Pro"

# Lint
swiftlint lint
swiftlint lint --fix
```

## Architecture

```
Project_PawNovaApp
└── RootView
    ├── OnboardingContainerView (first launch)
    │   └── SplashView (video logo) → WelcomeView → PetNameView → PaywallView
    └── MainTabView (after onboarding)
        ├── ProjectsView (Home/Landing - default tab)
        ├── ContentView (Create video)
        └── SettingsView (Config)
```

**Key Files:**
- `ProjectsView.swift` - Main landing screen (shows projects/videos)
- `ContentView.swift` - Video creation UI
- `FalService.swift` - API client (@MainActor, 4 AI models)
- `PetVideo.swift` - SwiftData model
- `PersistenceController.swift` - SwiftData container
- `TabRouter.swift` - @Observable tab navigation
- `ErrorHandling.swift` - PawNovaError, NetworkMonitor, retry logic
- `SecureStorage.swift` - Keychain storage for credits/subscription
- `GenerationProgress.swift` - AsyncSequence real-time progress
- `DiagnosticsService.swift` - Logging and diagnostic export
- `Tips.swift` - TipKit contextual tips
- `Store/StoreService.swift` - StoreKit 2 purchases
- `Onboarding/SplashView.swift` - Animated video logo (loops from 4s)
- `Onboarding/` - Welcome, PetName, Notifications, Paywall

## Patterns

### FalService
```swift
@MainActor final class FalService {
    static let shared = FalService()
    var demoMode = true  // Default: safe testing
    init(session: URLSession = .shared)  // DI for tests
}
```

### SwiftData
```swift
@Model
final class PetVideo {
    var prompt: String
    var generatedURL: URL?
    var isFavorite: Bool = false
}

// Always use @MainActor for SwiftData in tests
@MainActor func testSomething() throws { }
```

### Tab Navigation
```swift
@Environment(TabRouter.self) private var router
router.goToProjects()  // Go to Projects (home)
router.goToCreate()    // Go to Create tab
router.goToSettings()  // Go to Settings

// Tab order: Projects (default) → Create → Settings
```

### Haptics
```swift
Haptic.success()  // Save completed
Haptic.warning()  // Delete action
Haptic.error()    // Error occurred
```

### Onboarding (Simplified 4-step)
```swift
@Observable final class OnboardingManager {
    var currentStep: OnboardingStep = .splash
    var hasCompletedOnboarding: Bool  // persisted
    func nextStep()
    func completeOnboarding()
}

// Steps: splash → welcome → petName → paywall → complete
// Welcome includes Sign in with Apple + Email auth

@Environment(OnboardingManager.self) private var onboarding
onboarding.nextStep()
```

## API Setup

1. Get key: https://fal.ai/dashboard/keys
2. Xcode: Product → Scheme → Edit Scheme → Run → Environment Variables
3. Add: `FAL_KEY = your-key-here`

**Demo mode** returns Apple sample HLS streams (playable without API key).

## Testing

**81 tests** across 10 test suites:
- `OnboardingTests` - 12 tests (flow state, navigation, reset)
- `FalServiceTests` - 16 tests (AI models, errors, prompt enhancement, demo mode)
- `PetVideoTests` - 11 tests (model logic, SwiftData)
- `PersistenceControllerTests` - 4 tests (container, singleton)
- `Project_PawNovaTests` - 4 tests (integration workflows)
- `SecureStorageTests` - 12 tests (Keychain operations)
- `StoreServiceTests` - 6 tests (StoreKit 2 purchases)
- `ErrorHandlingTests` - 10 tests (error types, network monitor)
- UI Tests - 2 tests (launch, performance)
- UI Launch Tests - 4 tests (screenshot capture)

**Key patterns:**
- Use `PersistenceController(inMemory: true)` for test isolation
- SwiftData tests need `@MainActor`
- Use `FalService.shared` singleton in tests (avoid creating new instances to prevent URLSession deallocation crashes)

## Dev Testing

In DEBUG builds only:
- **WelcomeView**: "Skip (Dev Mode)" link bypasses auth
- **SettingsView**: "Reset Onboarding" in Developer section

## AI Models

| Model | Provider | Duration | Credits | Audio |
|-------|----------|----------|---------|-------|
| Veo 3 Fast | Google | 8s | 800 | Yes |
| Veo 3 Pro | Google | 8s | 2000 | Yes |
| Kling 2.5 | Kuaishou | 5s | 600 | No |
| Hailuo-02 | MiniMax | 6s | 500 | No |

## Security Requirements

### Sensitive Data Storage
```swift
// ✅ CORRECT: Use Keychain for sensitive data
SecureUserData.shared.setCredits(100)
SecureUserData.shared.setSubscribed(true)

// ❌ WRONG: Never store sensitive data in UserDefaults
UserDefaults.standard.set(credits, forKey: "credits")  // INSECURE
```

### API Keys
- Never hardcode API keys in source code
- Use environment variables for development only
- Production: Implement server-side proxy to hide keys from client
- `GoogleService-Info.plist` must be in `.gitignore`

### URL Validation
```swift
// ✅ CORRECT: Guard against invalid URLs
guard let url = URL(string: urlString) else {
    throw FalServiceError.invalidResponse
}

// ❌ WRONG: Force unwrap URLs
let url = URL(string: urlString)!  // CRASH RISK
```

### Network Security
- Check network connectivity before API calls
- Use `NetworkMonitor.shared.checkConnection()` before requests
- Configure URLSession with explicit timeouts

## Error Handling Patterns

### Do-Catch for Persistence
```swift
// ✅ CORRECT: Log persistence errors
do {
    try modelContext.save()
} catch {
    ErrorLogger.shared.log(error, context: "Save")
}

// ❌ WRONG: Silent failure
try? modelContext.save()  // Errors lost
```

### User-Facing Errors
```swift
// Use .errorAlert modifier from ErrorHandling.swift
.errorAlert(error: $error, onRetry: { /* retry */ })
```

## Memory Management

### AVPlayer Cleanup
```swift
// ✅ CORRECT: Clean up AVPlayer
.onDisappear {
    player?.pause()
    player = nil  // Required to release memory
}

// ❌ WRONG: Missing nil assignment
.onDisappear {
    player?.pause()  // Player may leak
}
```

### Closures with Self
```swift
// ✅ CORRECT: Single weak capture
Task.detached { [weak self] in
    guard let self else { return }
    await self.doWork()
}

// ❌ WRONG: Double weak capture
Task.detached { [weak self] in
    await MainActor.run { [weak self] in  // Redundant
        self?.doWork()
    }
}
```

## Performance Guidelines

### View Size
- Extract subviews if file exceeds 200 lines
- Use `LazyVStack`/`LazyVGrid` for long lists
- Memoize expensive computed properties

### Network
- Check connectivity before API calls: `try NetworkMonitor.shared.checkConnection()`
- Configure timeouts on URLSession
- Implement retry with exponential backoff using `withRetry()`

## Constraints

- iOS 18+ required (SwiftData, @Observable, TipKit)
- Demo mode = true by default
- Use os.Logger, not print()
- @MainActor for services
- Onboarding completes before MainTabView shows
- AuthenticationServices for Sign in with Apple
- Simulator console noise (haptics, audio) is expected
- Use Keychain (SecureStorage) for credits, subscription, tokens
- Never force-unwrap URLs from external sources
- Clean up AVPlayer in onDisappear

## iOS 18 Features

### Live Activities (ActivityKit)
```swift
// Start Live Activity when video generation begins
let attributes = VideoGenerationAttributes(prompt: prompt, model: model)
let state = VideoGenerationAttributes.ContentState(progress: 0, stage: "Starting...")
let activity = try Activity.request(attributes: attributes, content: .init(state: state, staleDate: nil))

// Update progress
await activity.update(using: .init(progress: 0.5, stage: "Rendering..."))

// End when complete
await activity.end(using: .init(progress: 1.0, stage: "Complete!"), dismissalPolicy: .after(.now + 5))
```

### Interactive Widgets (WidgetKit)
```swift
// Widget shows recent videos, tap to open app
struct PawNovaWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "RecentVideos", intent: OpenAppIntent.self, provider: Provider()) { entry in
            WidgetView(entry: entry)
        }
    }
}

// App Group for shared data: group.com.pawnova.shared
```

### Foundation Models (iOS 18.1+)
```swift
// On-device prompt enhancement
import FoundationModels

@Generable
struct EnhancedPrompt {
    let cinematicPrompt: String
    let suggestedStyle: String
}

let session = LanguageModelSession()
let enhanced = try await session.generate(EnhancedPrompt.self, from: userPrompt)
```

### SwiftData iOS 18
```swift
@Model
final class PetVideo {
    #Index<PetVideo>([\.prompt], [\.timestamp])
    #Unique<PetVideo>([\.generatedURL])  // Prevent duplicate videos

    var prompt: String
    var timestamp: Date
    var generatedURL: URL?
}
```

### SwiftUI iOS 18
```swift
// MeshGradient for rich backgrounds
MeshGradient(
    width: 3, height: 3,
    points: [...],
    colors: [.pawPrimary, .pawSecondary, .pawAccent, ...]
)

// Floating tab bar with sidebar (iPad)
TabView {
    // tabs
}
.tabViewStyle(.sidebarAdaptable)
```

## Documentation

- `FIREBASE_SETUP.md` - Crashlytics & Analytics setup
- `GO_LIVE_CHECKLIST.md` - App Store submission checklist
- `ROADMAP.md` - Feature roadmap
