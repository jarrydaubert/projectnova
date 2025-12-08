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

### 2. API & Backend
- [ ] fal.ai API key stored securely (NOT in code)
- [ ] Production API endpoints configured
- [ ] Error handling for all API calls
- [ ] Rate limiting considered
- [ ] Backend proxy set up (recommended - hide API key from client)

### 3. App Store Configuration

#### In Xcode:
- [ ] Bundle ID finalized (e.g., `com.pawnova.app`)
- [ ] Version number set (1.0.0)
- [ ] Build number incremented
- [ ] App icon added (all sizes: 1024x1024 for App Store, 180x180 for iPhone, etc.)
- [ ] Launch screen configured
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

### 4. In-App Purchases

#### Subscriptions:
- [ ] `pawnova.pro.monthly` - $9.99/month
- [ ] `pawnova.pro.yearly` - $79.99/year
- [ ] Subscription group created
- [ ] Free trial configured (optional: 7-day trial)
- [ ] Subscription descriptions added

#### Consumables (Credit Packs):
- [ ] `pawnova.credits.500` - 500 credits
- [ ] `pawnova.credits.2000` - 2,000 credits
- [ ] `pawnova.credits.5000` - 5,000 credits

#### StoreKit:
- [ ] Products tested in Sandbox environment
- [ ] Restore purchases working
- [ ] Receipt validation (optional for extra security)

### 5. Privacy & Permissions

#### Info.plist Keys:
- [ ] `NSPhotoLibraryAddUsageDescription` - "PawNova needs access to save videos to your Photos"
- [ ] `NSCameraUsageDescription` - "PawNova needs camera access to capture pet photos" (if using camera)
- [ ] `NSUserTrackingUsageDescription` - Only if using ATT

#### App Privacy (App Store Connect):
- [ ] Data types collected declared
- [ ] Third-party SDKs disclosed (fal.ai)
- [ ] Privacy nutrition label completed

### 6. Legal
- [ ] Terms of Service accessible in app ✅
- [ ] Privacy Policy accessible in app ✅
- [ ] EULA configured in App Store Connect
- [ ] Copyright notices updated

### 7. Testing

#### Functional Testing:
- [ ] Onboarding flow complete
- [ ] Video generation works (real API)
- [ ] All payment flows tested
- [ ] Sign in with Apple working
- [ ] Notifications working
- [ ] All navigation paths tested
- [ ] Error states handled gracefully

#### Device Testing:
- [ ] iPhone 15 Pro / 16 Pro
- [ ] iPhone 15 / 16 (standard)
- [ ] iPhone SE (if supporting smaller screens)
- [ ] iPad (if universal app)

#### Edge Cases:
- [ ] No internet connection handling
- [ ] Low storage handling
- [ ] Background/foreground transitions
- [ ] Memory warnings

### 8. Analytics & Monitoring (Optional)
- [ ] Crash reporting (Firebase Crashlytics / Sentry)
- [ ] Analytics (Mixpanel / Amplitude)
- [ ] Error logging for production debugging

### 9. Marketing Assets
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

| Version | Date | Notes |
|---------|------|-------|
| 0.1.0 | Dec 2024 | Initial development build |
| 1.0.0 | TBD | App Store release |
