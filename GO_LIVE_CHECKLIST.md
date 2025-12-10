# PawNova Go-Live Checklist

Complete these items before submitting to the App Store.

## Pre-Submission Checklist

### 1. Code Quality
- [ ] All tests passing (`Cmd+U`)
- [ ] SwiftLint clean (`swiftlint lint`)
- [ ] No compiler warnings
- [ ] Demo mode OFF by default for production
- [ ] Remove all `print()` statements
- [ ] Remove any test/debug code
- [x] No force-unwrapped URLs from external sources ✅ Fixed in FalService, VideoDetailView
- [x] AVPlayer cleanup in all onDisappear blocks ✅ Fixed in GeneratedVideoSheet, VideoDetailView

### 2. Security (CRITICAL)
- [ ] `GoogleService-Info.plist` in `.gitignore` (remove from git history if committed)
- [x] Sensitive data stored in Keychain (SecureStorage), NOT UserDefaults ✅ Migrated
- [x] Credits and subscription status use SecureUserData.shared ✅ All files updated
- [ ] No hardcoded API keys in source code
- [x] URL validation with guard statements (no force unwraps) ✅ FalService fixed
- [x] Network connectivity checked before API calls ✅ Added to FalService
- [x] URLSession configured with explicit timeouts ✅ 30s request, 5min resource

### 3. API & Backend
- [ ] fal.ai API key stored securely (NOT in code)
- [ ] Production API endpoints configured
- [ ] Error handling for all API calls
- [ ] Rate limiting considered
- [ ] Backend proxy set up (recommended - hide API key from client)
- [ ] Receipt validation for purchases (server-side recommended)

### 4. App Store Configuration

#### In Xcode:
- [ ] Bundle ID finalized (e.g., `com.pawnova.app`)
- [ ] Version number set (1.0.0)
- [ ] Build number incremented
- [x] App icon added (all sizes) ✅ Added
- [x] Launch screen configured (animated video logo) ✅ Implemented
- [ ] Supported orientations set (Portrait recommended)
- [ ] Minimum iOS version: 18.0
- [ ] App category: Photo & Video

#### In App Store Connect:
- [ ] App name: "PawNova - AI Pet Videos"
- [ ] Subtitle: "Create magical pet adventures"
- [ ] Description written (see below)
- [ ] Keywords optimized
- [ ] Screenshots for all device sizes (6.7", 6.5", 5.5")
- [ ] App preview video (optional but recommended)
- [ ] Support URL: https://pawnova.app/support
- [ ] Privacy Policy URL: https://pawnova.app/privacy
- [ ] Age rating completed (4+ recommended)

### 5. In-App Purchases

#### Subscriptions (StoreKit 2):
- [ ] `com.pawnova.subscription.monthly` - £7.99/month (5000 credits)
- [ ] `com.pawnova.subscription.annual` - £49.99/year (5000 credits/mo)
- [ ] Subscription group created
- [ ] Free trial configured (optional: 7-day trial)
- [ ] Subscription descriptions added

#### Consumables (Credit Packs):
- [ ] `com.pawnova.credits.starter` - 500 credits
- [ ] `com.pawnova.credits.popular` - 2,000 credits
- [ ] `com.pawnova.credits.pro` - 6,000 credits

#### StoreKit 2 Implementation:
- [x] StoreService.swift implemented ✅
- [ ] Products tested in Sandbox environment
- [x] Restore purchases button in Settings ✅
- [ ] Receipt validation (optional for extra security)

### 6. Privacy & Permissions

#### Info.plist Keys:
- [ ] `NSPhotoLibraryAddUsageDescription` - "PawNova needs access to save videos to your Photos"
- [ ] `NSCameraUsageDescription` - "PawNova needs camera access to capture pet photos" (if using camera)
- [ ] `NSUserTrackingUsageDescription` - Only if using ATT

#### App Privacy (App Store Connect):
- [ ] Data types collected declared
- [ ] Third-party SDKs disclosed (fal.ai)
- [ ] Privacy nutrition label completed

### 7. Legal
- [x] Terms of Service accessible in app ✅ (Settings → Terms)
- [x] Privacy Policy accessible in app ✅ (Settings → Privacy)
- [ ] EULA configured in App Store Connect
- [ ] Copyright notices updated

### 8. Testing

#### Functional Testing:
- [x] Onboarding flow complete ✅ (Splash → Welcome → PetName → Paywall)
- [ ] Video generation works (real API) ⚠️ Demo mode only tested
- [ ] All payment flows tested (StoreKit sandbox)
- [x] Sign in with Apple working ✅
- [x] Notifications permission flow ✅
- [x] All navigation paths tested ✅ (Projects/Create/Settings tabs)
- [x] Error states handled gracefully ✅ (ErrorHandling.swift)

#### Device Testing:
- [ ] iPhone 15 Pro / 16 Pro
- [ ] iPhone 15 / 16 (standard)
- [ ] iPhone SE (if supporting smaller screens)
- [ ] iPad (if universal app)

#### Edge Cases:
- [x] No internet connection handling ✅ (OfflineBanner, NetworkMonitor)
- [ ] Low storage handling
- [ ] Background/foreground transitions
- [ ] Memory warnings

### 9. Analytics & Monitoring
- [x] Crash reporting (Firebase Crashlytics) ✅ Integrated
- [ ] Analytics (Firebase Analytics / Mixpanel)
- [x] Error logging (DiagnosticsService + Crashlytics) ✅ Integrated

### 10. Marketing Assets
- [ ] App Store screenshots (all sizes)
- [ ] App icon variations
- [ ] Press kit (optional)
- [ ] Social media assets

---

## App Store Description Template

```
🐾 PawNova - AI Pet Videos

Transform your pet photos into magical AI-generated videos! Watch your furry friend go on incredible adventures with the power of AI.

✨ FEATURES
• AI Video Generation - Create stunning videos from text prompts
• Photo to Video - Bring your pet photos to life
• Multiple AI Models - Choose from Veo 3, Kling 2.5, and more
• Easy Sharing - Export and share to TikTok, Instagram, YouTube
• Beautiful Library - Organize and favorite your creations

🎬 HOW IT WORKS
1. Describe your pet's adventure or upload a photo
2. Choose an AI model and video format
3. Watch as AI brings your vision to life
4. Save, share, and enjoy!

💎 PAWNOVA PRO
Subscribe for unlimited video generation, premium AI models, and HD exports.

• Monthly: $9.99/month
• Yearly: $79.99/year (Save 33%)

---
Terms: https://pawnova.app/terms
Privacy: https://pawnova.app/privacy
Support: support@pawnova.app
```

---

## Post-Launch Checklist

### Week 1
- [ ] Monitor crash reports
- [ ] Respond to App Store reviews
- [ ] Monitor API usage and costs
- [ ] Check subscription conversion rates

### Ongoing
- [ ] Regular updates (bug fixes, new features)
- [ ] A/B test pricing and messaging
- [ ] Expand to new markets
- [ ] Consider Android version

---

## Emergency Contacts

- **fal.ai Support**: support@fal.ai
- **Apple Developer Support**: https://developer.apple.com/contact/
- **App Store Review**: https://developer.apple.com/app-store/review/

---

## Version History

Track version changes in git tags and releases. Use semantic versioning (MAJOR.MINOR.PATCH).
