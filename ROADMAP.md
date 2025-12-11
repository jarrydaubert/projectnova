# PawNova Production Roadmap

## Phase 1: Core Infrastructure (Week 1-2)

### 1.1 Backend Setup (Supabase)
- [ ] Create Supabase project
- [ ] Design database schema:
  ```sql
  -- users (extends Supabase auth.users)
  create table profiles (
    id uuid references auth.users primary key,
    display_name text,
    pet_name text,
    avatar_url text,
    credits integer default 0,
    created_at timestamptz default now()
  );

  -- video generations
  create table generations (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references profiles(id),
    prompt text not null,
    model text not null,
    video_url text,
    credits_used integer,
    status text default 'pending',
    created_at timestamptz default now()
  );

  -- credit transactions
  create table credit_transactions (
    id uuid primary key default gen_random_uuid(),
    user_id uuid references profiles(id),
    amount integer not null,
    type text not null, -- 'purchase', 'usage', 'bonus'
    description text,
    created_at timestamptz default now()
  );
  ```
- [ ] Create Edge Function for video generation (hides fal.ai API key)
- [ ] Set up Row Level Security (RLS) policies

### 1.2 Authentication
- [ ] Implement Sign in with Apple (AuthenticationServices)
- [ ] Implement Email/Password auth
- [ ] Add Face ID/Touch ID for returning users (LocalAuthentication)
- [ ] Create AuthManager service in app

### 1.3 RevenueCat Setup
- [ ] Create RevenueCat project
- [ ] Configure products in App Store Connect:
  - Weekly: £9.99/week (1000 credits)
  - Yearly: £79.99/year (unlimited)
- [ ] Integrate RevenueCat SDK
- [ ] Create PaywallView

## Phase 2: Onboarding Flow (Week 2-3)

### 2.1 Splash Screen
- [ ] Create animated paw logo (Lottie or SwiftUI)
- [ ] Auto-advance after 2 seconds

### 2.2 Welcome Screen
- [ ] Full-screen looping video background (pet-themed)
- [ ] "Join thousands of pet lovers" headline
- [ ] "Get Started" button → Auth

### 2.3 Auth Screens
- [ ] "Your adventure starts here" + logo
- [ ] "Continue with Apple" button (primary)
- [ ] "Continue with Email" button (secondary)
- [ ] Email signup form (if chosen)
- [ ] "Already have account? Sign In" link

### 2.4 Personalization
- [ ] "What's your pet's name?" screen
- [ ] "What adventures do you want to create?"
  - [ ] TikTok/Reels content
  - [ ] Personal memories
  - [ ] Funny moments
  - [ ] Special occasions

### 2.5 Feature Carousel (4 screens with animated backgrounds)
- [ ] "Welcome to PawNova! 🐾"
- [ ] "Magical Adventures" - Transform your pet into a movie star
- [ ] "Share the Joy" - Create viral pet content
- [ ] "Premium Quality" - Hollywood-grade AI video

### 2.6 Permissions & Paywall
- [ ] Notifications permission screen
- [ ] Paywall screen (soft gate - can skip with limited credits)

## Phase 3: Main App Improvements (Week 3-4)

### 3.1 Simplified Create Screen (like FlashLoop)
- [ ] Remove header clutter
- [ ] Text to Video / Image to Video tabs (segmented control)
- [ ] Single prompt text area
- [ ] Aspect Ratio: 9:16 | 16:9 (simple toggle)
- [ ] AI Enhance toggle
- [ ] Model dropdown (not cards)
- [ ] Credits cost display
- [ ] "Create Video" button
- [ ] "Need more credits? Upgrade" link

### 3.2 Projects/Library View
- [ ] Grid of generated videos with thumbnails
- [ ] Empty state: "Ready to create amazing videos?"
- [ ] Pull-to-refresh
- [ ] Swipe to delete

### 3.3 Profile/Settings
- [ ] User avatar + name
- [ ] Credits balance (tap to see sheet)
- [ ] "PawNova Pro" subscription status
- [ ] Standard settings (notifications, privacy, etc.)

## Phase 4: Polish & Production (Week 4-5)

### 4.1 Video Generation Flow
- [ ] Upload photo to Supabase Storage (if image-to-video)
- [ ] Call Edge Function (not fal.ai directly)
- [ ] Show progress with animation
- [ ] Push notification when complete
- [ ] Save to local SwiftData + sync to Supabase

### 4.2 Credits System
- [ ] Display balance in header
- [ ] Deduct on generation
- [ ] "Insufficient credits" modal
- [ ] Purchase flow via RevenueCat

### 4.3 Offline Support
- [ ] Cache videos locally (FileManager)
- [ ] Queue generations when offline
- [ ] Sync on reconnect

### 4.4 Analytics
- [ ] Firebase Analytics or Mixpanel
- [ ] Track: signups, generations, model_used, conversion, churn

### 4.5 Production Checklist
- [ ] App Store screenshots (6.7", 6.5", 5.5")
- [ ] App Store description + keywords
- [ ] Privacy Policy URL
- [ ] Terms of Service URL
- [ ] PrivacyInfo.xcprivacy manifest
- [ ] TestFlight beta
- [ ] App Store submission

## Phase 5: iOS 18 Cutting-Edge Features

### 5.1 SwiftData iOS 18 Enhancements
- [x] `#Index` macro for faster queries (already implemented)
- [x] `#Unique` compound constraints on PetVideo (prevent duplicate URLs) ✅
- [ ] History API exploration for future sync capabilities

### 5.2 SwiftUI iOS 18 Features
- [x] `MeshGradient` for richer visual backgrounds (PawNovaMeshGradient in SplashView) ✅
- [x] Floating tab bar → sidebar transition (iPad support via .sidebarAdaptable) ✅
- [ ] `onScrollGeometryChange` for scroll-aware UI effects
- [ ] Metal shader pre-compilation for smoother animations

### 5.3 Live Activities (ActivityKit)
- [x] Create `VideoGenerationAttributes` for Live Activity data ✅
- [x] Dynamic Island compact/expanded views showing generation progress ✅
- [x] Lock Screen live updates during video creation ✅
- [x] Integration with `GenerationProgressManager` ✅
- [x] End activity with video thumbnail on completion ✅
- [x] Widget Extension target created with Live Activity support ✅

### 5.4 Interactive Widgets (WidgetKit)
- [x] Widget extension code created (PawNova/) ✅
- [x] Small widget: Recent video + video count ✅
- [x] Medium widget: Recent videos list + Create button ✅
- [x] SharedDataManager for App Group communication ✅
- [x] Widget timeline provider ✅
- [x] Widget Extension target added (PawNovaExtension) ✅
- [x] App Group capability added: `group.com.pawnova.shared` ✅

### 5.5 Apple Intelligence / Foundation Models (iOS 18.1+)
- [x] On-device prompt enhancement via `FoundationModelService` ✅
- [ ] `@Generable` struct for structured AI outputs (future enhancement)
- [x] Smart suggestions based on pet name and history ✅
- [x] Graceful fallback for devices without Apple Intelligence ✅
- [x] `FoundationModelService.swift` created with `LanguageModelSession` integration ✅

---

## Tech Stack Summary

| Layer | Technology |
|-------|------------|
| Frontend | SwiftUI (iOS 18), SwiftData, AVKit |
| iOS 18 | WidgetKit, ActivityKit, Foundation Models |
| Auth | Supabase Auth + Sign in with Apple |
| Database | Supabase (PostgreSQL) |
| Storage | Supabase Storage (photos/videos) |
| API | Supabase Edge Functions (Deno) |
| AI | fal.ai (via Edge Function) |
| Payments | RevenueCat + StoreKit 2 |
| Analytics | Firebase Analytics |
| Push | Firebase Cloud Messaging |
| Crash Reporting | Firebase Crashlytics |

## Dependencies to Add

```swift
// Package.swift or SPM
dependencies: [
    .package(url: "https://github.com/supabase/supabase-swift", from: "2.0.0"),
    .package(url: "https://github.com/RevenueCat/purchases-ios", from: "4.0.0"),
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0"),
    .package(url: "https://github.com/airbnb/lottie-ios", from: "4.0.0"), // animations
]
```

## Estimated Timeline

| Phase | Duration | Deliverable |
|-------|----------|-------------|
| Phase 1 | 2 weeks | Backend + Auth working |
| Phase 2 | 1 week | Onboarding complete |
| Phase 3 | 1 week | Main app polished |
| Phase 4 | 1 week | Production ready |
| **Total** | **5 weeks** | App Store submission |

## Immediate Next Steps

1. **Create Supabase account** → supabase.com
2. **Create RevenueCat account** → revenuecat.com
3. **Set up App Store Connect** → Products for IAP
4. **Start Phase 1.2** → Auth implementation

---

*This roadmap targets feature parity with FlashLoop while adding pet-specific UX. Adjust timeline based on your availability.*
