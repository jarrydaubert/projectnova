# CLAUDE.md

## Project Overview

PawNova is an iOS 18+ app that generates AI pet videos using fal.ai. Supports 4 AI models: Veo 3 Fast, Veo 3 Pro (Google), Kling 2.5 (Kuaishou), Hailuo-02 (MiniMax). Three-tab navigation: Create, Library, Settings. Demo mode enabled by default for free testing.

## Tech Stack

- **SwiftUI** - Declarative UI
- **SwiftData** - Persistence (@Model, @Query)
- **StoreKit 2** - Subscriptions & credit packs
- **TipKit** - Contextual tips
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
    │   └── SplashView → WelcomeView → PetNameView → PaywallView
    └── MainTabView (after onboarding)
        ├── ContentView (Create)
        ├── LibraryView (Browse)
        └── SettingsView (Config)
```

**Key Files:**
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
- `Onboarding/` - Splash, Welcome, PetName, Notifications, Paywall

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
router.goToCreate()  // Switch tabs
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

**44 tests** across 6 test suites:
- `OnboardingTests` - 9 tests (flow state, navigation, reset)
- `FalServiceTests` - 10 tests (AI models, errors, prompt enhancement)
- `PetVideoTests` - 11 tests (model logic, SwiftData)
- `PersistenceControllerTests` - 4 tests (container, singleton)
- `Project_PawNovaTests` - 4 tests (integration workflows)
- UI Tests - 6 tests (launch, performance)

**Key patterns:**
- Use `PersistenceController(inMemory: true)` for test isolation
- SwiftData tests need `@MainActor`
- `FalService.shared` for prompt enhancement tests

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

## Constraints

- iOS 18+ required (SwiftData, @Observable, TipKit)
- Demo mode = true by default
- Use os.Logger, not print()
- @MainActor for services
- Onboarding completes before MainTabView shows
- AuthenticationServices for Sign in with Apple
- Simulator console noise (haptics, audio) is expected

## Documentation

- `FIREBASE_SETUP.md` - Crashlytics & Analytics setup
- `GO_LIVE_CHECKLIST.md` - App Store submission checklist
- `ROADMAP.md` - Feature roadmap
