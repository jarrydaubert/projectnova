# Firebase Setup Guide for PawNova

This guide covers setting up Firebase for crash reporting and analytics.

## Step 1: Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Click "Create a project"
3. Name: `pawnova` or `pawnova-prod`
4. Enable Google Analytics (recommended)
5. Select or create an Analytics account

## Step 2: Add iOS App

1. In Firebase Console, click "Add app" → iOS
2. Enter details:
   - **Bundle ID**: `com.pawnova.app` (must match Xcode)
   - **App nickname**: PawNova
   - **App Store ID**: (leave blank for now)
3. Download `GoogleService-Info.plist`
4. **IMPORTANT**: Add to Xcode project root (drag into Project Navigator)
5. Make sure "Copy items if needed" is checked

## Step 3: Add Firebase SDK via Swift Package Manager

1. In Xcode: File → Add Package Dependencies
2. Enter URL: `https://github.com/firebase/firebase-ios-sdk`
3. Select version: Up to Next Major (11.0.0+)
4. Select these packages:
   - ✅ FirebaseAnalytics
   - ✅ FirebaseCrashlytics
   - ✅ FirebasePerformance (optional)

## Step 4: Configure Firebase in App

Update `Project_PawNovaApp.swift`:

```swift
import Firebase

@main
struct Project_PawNovaApp: App {
    init() {
        // ... existing code ...

        // Configure Firebase
        FirebaseApp.configure()
    }
}
```

## Step 5: Enable Crashlytics

### In Firebase Console:
1. Go to Crashlytics in sidebar
2. Click "Enable Crashlytics"

### In Xcode Build Phases:
1. Select your target → Build Phases
2. Click + → New Run Script Phase
3. Name it "Upload Crashlytics Symbols"
4. Add this script:

```bash
"${BUILD_DIR%/Build/*}/SourcePackages/checkouts/firebase-ios-sdk/Crashlytics/run"
```

5. Add input files:
```
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Resources/DWARF/${PRODUCT_NAME}
${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}/Contents/Info.plist
$(TARGET_BUILD_DIR)/$(UNLOCALIZED_RESOURCES_FOLDER_PATH)/GoogleService-Info.plist
$(TARGET_BUILD_DIR)/$(EXECUTABLE_PATH)
```

### Enable dSYM uploads:
1. Target → Build Settings
2. Search "Debug Information Format"
3. Set to "DWARF with dSYM File" for Release

## Step 6: Add Crashlytics Logging

Update `DiagnosticsService.swift` to send errors to Crashlytics:

```swift
import FirebaseCrashlytics

// In log methods, add:
Crashlytics.crashlytics().log(message)

// For errors:
Crashlytics.crashlytics().record(error: error)

// Set user ID for tracking:
Crashlytics.crashlytics().setUserID(userId)

// Custom keys:
Crashlytics.crashlytics().setCustomValue(value, forKey: key)
```

## Step 7: Test Crashlytics

Add a test crash button (DEBUG only):

```swift
#if DEBUG
Button("Test Crash") {
    fatalError("Test crash for Crashlytics")
}
#endif
```

1. Build and run in Release mode
2. Tap the crash button
3. Relaunch app (crash reports send on next launch)
4. Check Firebase Console → Crashlytics

## Step 8: Analytics Events (Optional)

Track custom events:

```swift
import FirebaseAnalytics

// Track video generation
Analytics.logEvent("video_generated", parameters: [
    "model": model.rawValue,
    "credits_used": creditCost,
    "aspect_ratio": aspectRatio
])

// Track subscription
Analytics.logEvent("subscription_started", parameters: [
    "plan": plan.rawValue,
    "price": price
])
```

## Firebase Console Features

Once set up, you get:

| Feature | What You See |
|---------|--------------|
| **Crashlytics** | Real-time crashes, stack traces, affected users |
| **Analytics** | DAU/MAU, sessions, screen views, custom events |
| **Performance** | App start time, network latency, screen rendering |

## Security Notes

- **NEVER commit** `GoogleService-Info.plist` to public repos
- Add to `.gitignore`:
  ```
  GoogleService-Info.plist
  ```
- For CI/CD, use environment variables or secure file storage

## Costs

Firebase has generous free tiers:
- **Crashlytics**: Completely free
- **Analytics**: Free up to 500 events/user/day
- **Performance**: Free for basic monitoring

You likely won't pay anything until millions of users.

## Troubleshooting

### Crashes not appearing?
1. Make sure app was run in Release mode
2. Crash reports send on NEXT app launch
3. Wait 5-10 minutes for processing
4. Check dSYM upload in Console

### "Missing dSYM" warning?
1. Build Settings → "Debug Information Format" = "DWARF with dSYM"
2. Run the upload script manually
3. Use Firebase CLI: `firebase crashlytics:symbols:upload`

### Analytics not tracking?
1. Ensure `FirebaseApp.configure()` is called first
2. Events may take 24 hours to appear in dashboard
3. Use DebugView for real-time testing

## Alternative: Sentry

If you prefer Sentry over Firebase:

```bash
# Add via SPM
https://github.com/getsentry/sentry-cocoa

# Configure
import Sentry

SentrySDK.start { options in
    options.dsn = "YOUR_SENTRY_DSN"
    options.tracesSampleRate = 1.0
}
```

Sentry offers similar features with a different UI. Firebase is more integrated with Google ecosystem.
