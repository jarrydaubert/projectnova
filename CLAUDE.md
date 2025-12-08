# CLAUDE.md

## Project Overview

PawNova is an iOS 17+ app that generates AI pet videos using fal.ai (Google Veo 3, OpenAI Sora 2). Three-tab navigation: Create, Library, Settings. Demo mode enabled by default for free testing.

## Tech Stack

- **SwiftUI** - Declarative UI
- **SwiftData** - Persistence (@Model, @Query)
- **async/await** - Concurrency
- **AVKit** - Video playback
- **os.Logger** - Logging (not print)
- **@Observable** - iOS 17 state management
- Zero third-party dependencies

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
- `FalService.swift` - API client (@MainActor, injectable URLSession)
- `PetVideo.swift` - SwiftData model
- `PersistenceController.swift` - SwiftData container
- `TabRouter.swift` - @Observable tab navigation
- `HapticUtility.swift` - Haptic feedback
- `PawNovaColors.swift` - Aurora color palette
- `OnboardingManager.swift` - @Observable onboarding state
- `Onboarding/` - 4 onboarding views

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

## Constraints

- iOS 17+ required (SwiftData, @Observable)
- Demo mode = true by default
- Use os.Logger, not print()
- @MainActor for services
- Onboarding completes before MainTabView shows
- AuthenticationServices for Sign in with Apple
- Simulator console noise (haptics, audio) is expected
