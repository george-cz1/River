# App Store Submission Guide for River

This guide walks you through publishing River as a freemium Pomodoro timer app with Pro IAP ($4.99) on the App Store.

---

## ✅ Part 1: Critical Code Fixes (COMPLETED)

All critical code changes have been implemented:

- ✅ **Debug flag disabled** - `debugUnlockPro = false` in River/Services/PurchaseManager.swift:17
- ✅ **Privacy manifest created** - River/PrivacyInfo.xcprivacy declares UserDefaults usage
- ✅ **Project regenerated** - Xcode project updated with xcodegen

---

## 📱 Part 2: App Store Connect Setup

### 2.1 Create App Record

1. Go to [App Store Connect](https://appstoreconnect.apple.com)
2. Navigate to **My Apps** → Click **"+"** → **New App**
3. Fill in the following:
   - **Platform:** iOS
   - **Name:** River - Pomodoro Timer
   - **Primary Language:** English (U.S.)
   - **Bundle ID:** `com.george.river` (should appear in dropdown)
   - **SKU:** `river-focus-timer-001` (any unique identifier)
   - **User Access:** Full Access

### 2.2 Configure In-App Purchase

1. In App Store Connect: **My Apps** → **River** → **In-App Purchases**
2. Click **"+"** to create a new IAP
3. Select **Non-Consumable**
4. Fill in:
   - **Reference Name:** River Pro
   - **Product ID:** `com.george.river.pro` (MUST match code exactly)
   - **Price:** $4.99 (Tier 5 in most regions)
5. Add **Localizations** (English):
   - **Display Name:** River Pro
   - **Description:** Unlock all Pro features including custom timer durations, session history, themes, and custom sounds.
6. Upload a **screenshot** (can be a simple graphic showing Pro features)
7. Click **Save** then **Submit for Review** (will be reviewed with app)

### 2.3 App Information

Navigate to **App Information** section:

- **Category:** Productivity
- **Subcategory:** (optional - leave blank or choose relevant)
- **Content Rights:** Check "Yes" if you own all content
- **Age Rating:** Click "Edit" and complete questionnaire
  - Answer "No" to violence, gambling, mature themes → Should result in **4+** rating

### 2.4 Pricing & Availability

- **Price:** Free (base app)
- **Availability:** All countries (or select specific territories)
- **Pre-orders:** Not needed for initial release

---

## 📝 Part 3: App Review Preparation

### 3.1 Required Metadata

Navigate to the version you're submitting and fill in:

| Field | Recommended Value | Max Length |
|-------|-------------------|------------|
| **App Name** | River - Pomodoro Timer | 30 chars |
| **Subtitle** | Stay Focused, Get Things Done | 30 chars |
| **Promotional Text** | Stay focused with beautiful Pomodoro sessions and task management | 170 chars |
| **Description** | See suggested description below | 4000 chars |
| **Keywords** | pomodoro,focus,timer,productivity,tasks,work,study,break | 100 chars |
| **Support URL** | Your website or GitHub repo | Required |
| **Privacy Policy URL** | See section 3.3 below | **REQUIRED for IAP** |

#### Suggested App Description

```
River is a beautiful Pomodoro focus timer designed to help you stay productive and maintain deep focus through structured work sessions and breaks.

KEY FEATURES:
• Classic Pomodoro Timer (25 min work, 5 min break)
• Task Management - Track what you're working on
• Live Activities - Monitor your focus time in Dynamic Island and Lock Screen
• App Blocking - Block distracting apps during focus sessions (Pro)
• Session History - Review your productivity stats (Pro)
• Custom Durations - Adjust timer lengths to your workflow (Pro)
• Beautiful Themes - River, Forest, Sunset, Ocean, Stone (Pro)
• Focus Sounds - Customize session transitions (Pro)

WHY RIVER?
River combines the proven Pomodoro Technique with modern iOS features like Dynamic Island, creating a seamless focus experience that stays out of your way while keeping you on track.

Whether you're studying, working on a project, or building a daily focus habit, River helps you break your work into manageable sessions with built-in break reminders.

PERFECT FOR:
• Students preparing for exams
• Developers deep-diving into code
• Writers tackling creative work
• Anyone looking to improve focus and time management

FREE FEATURES:
• Full Pomodoro timer functionality
• Task list with SwiftData persistence
• Live Activities support
• Session tracking

PRO FEATURES ($4.99):
• App blocking during focus sessions (Screen Time integration)
• Custom timer durations
• Complete session history with stats
• Multiple color themes
• Custom sounds and haptics
• One-time purchase, no subscriptions

Download River and start your most focused day yet.
```

### 3.2 Review Notes for Apple

In the **App Review Information** section, add these notes:

```
TESTING INSTRUCTIONS:

Basic Features (Free):
1. Tap "+" to add a task
2. Tap "Start Focus" to begin a 25-minute work session
3. Timer displays in Dynamic Island (iPhone 14 Pro+) and Lock Screen
4. Wait or skip to end session - break timer starts automatically

In-App Purchase Testing:
1. Tap "Settings" tab (bottom right)
2. Scroll down to "Upgrade to Pro" section
3. Tap "Upgrade to Pro" to view feature list
4. Use sandbox account to test purchase flow
5. After purchase, verify Settings shows "Pro Features" expanded

Pro Features to Verify:
- Settings: App Blocking section - select apps to block during focus
- Settings: Request Screen Time authorization when enabling app blocking
- Settings: "Work Duration" and "Break Duration" pickers become editable
- History tab shows session statistics and calendar
- Settings: Theme options (River, Forest, Sunset, Ocean, Stone)
- Settings: Sound effect options

App Blocking Testing (Pro Feature):
1. In Settings, tap "App Blocking" section
2. Tap "Authorize Screen Time Access" and grant permission
3. Select apps to block (e.g., Safari, Instagram, etc.)
4. Start a focus session - selected apps should be blocked with shield overlay
5. End focus session - apps become accessible again

Restore Purchases:
- Tap "Restore Purchases" button in Settings
- Should recognize sandbox purchase and unlock Pro

NO LOGIN REQUIRED - All data stored locally
```

### 3.3 Privacy Policy (REQUIRED)

You **must** provide a privacy policy URL for apps with IAP. Here are your options:

#### Option 1: Free Privacy Policy Generators
- [TermsFeed](https://www.termsfeed.com/privacy-policy-generator/)
- [FreePrivacyPolicy.com](https://www.freeprivacypolicy.com/)
- [Termly](https://termly.io/products/privacy-policy-generator/)

#### Option 2: GitHub Pages (Free Hosting)
1. Create a new file in your GitHub repo: `docs/privacy-policy.md`
2. Enable GitHub Pages in repo settings (Settings → Pages → Source: main/docs)
3. Your URL will be: `https://[username].github.io/[repo]/privacy-policy.html`

#### Option 3: Simple Notion Page
1. Create a Notion page with privacy policy
2. Click "Share" → "Publish to web"
3. Use the public URL

#### What to Include in Privacy Policy

River's privacy practices:

```markdown
# Privacy Policy for River

Last updated: [Current Date]

River ("we", "our", or "the app") is committed to protecting your privacy.

## Data Collection
River does NOT collect, store, or transmit any personal data to external servers. All data remains on your device.

## Data Storage
The following data is stored locally on your device:
- Timer settings (work duration, break duration, etc.)
- Task list and task completion status
- Session history (when using Pro features)
- Theme preferences
- Selected apps for blocking (when using Pro app blocking feature)

This data is stored using:
- UserDefaults for settings
- SwiftData for task management
- App Group storage for widget synchronization and app blocking settings

## In-App Purchases
River offers a one-time Pro upgrade ($4.99) processed through Apple's App Store. We do not have access to your payment information. Purchase records are managed by Apple.

## Data Sharing
River does NOT share any data with third parties. All data remains exclusively on your device.

## Screen Time/Family Controls
River uses Apple's Family Controls framework (Pro feature only) to block selected apps during focus sessions. This permission is requested explicitly from the user and only used to apply app shields during active focus sessions. River does not monitor, track, or report your app usage data.

## Analytics and Tracking
River does NOT use analytics, tracking, or advertising services.

## Children's Privacy
River does not knowingly collect information from children under 13. The app is rated 4+ and safe for all ages.

## Your Rights
You can delete all app data by uninstalling River from your device.

## Changes to Privacy Policy
We may update this policy. Check this page for updates.

## Contact
For questions, contact: [your email]
```

### 3.4 Common Rejection Reasons to Avoid

✅ **ALREADY ADDRESSED:**
- Debug flags disabled ✓
- Privacy manifest added ✓
- IAP product ID matches code ✓

⚠️ **VERIFY BEFORE SUBMISSION:**
- [ ] Restore purchases works correctly
- [ ] Privacy policy URL is valid and loads
- [ ] Support URL is valid and loads
- [ ] All screenshots accurate (no outdated UI)
- [ ] App doesn't crash on launch or during normal use
- [ ] IAP purchase flow completes successfully in sandbox
- [ ] Description doesn't promise features not in app
- [ ] Family Controls entitlement is properly configured in all extension targets
- [ ] App Group entitlement matches across all targets (`group.com.george.evolve`)
- [ ] App blocking feature works correctly after granting Screen Time authorization

---

## 🎨 Part 4: Marketing Assets

### 4.1 App Icon - REDESIGN RECOMMENDED

**Current Status:** Your existing icon may not meet modern App Store standards.

**Recommended Style:** Minimal/Abstract with clean geometric shapes

**Design Direction:**
- Simple circle timer or water droplet shape
- Use River teal accent (`#4A8B9C`) on light background
- Or light/white icon on teal background
- Flat design (no gradients or skeuomorphic effects)
- **NO text in the icon**
- Should work at small sizes (recognize at 40x40)

**Color Palette from River Themes:**
- River Teal: `#4A8B9C` (primary)
- Light Background: `#F4F8F9`
- Dark Background: `#0F1E24`

**Design Tools (Free):**
- **Figma** - Professional, free tier: [figma.com](https://figma.com)
- **Canva** - App icon templates: [canva.com](https://canva.com)
- **IconKitchen** - Generate from shapes: [icon.kitchen](https://icon.kitchen)

**Required Size:** 1024x1024 PNG (Xcode auto-generates smaller sizes)

**File to Replace:** `River/Assets.xcassets/AppIcon.appiconset/icon-1024.png`

### 4.2 Screenshots - REQUIRED

You need screenshots for multiple device sizes:

| Device Class | Size (pixels) | Representative Device |
|--------------|---------------|----------------------|
| 6.9" Display | 1320 x 2868 | iPhone 16 Pro Max |
| 6.5" Display | 1290 x 2796 | iPhone 15 Pro Max |
| iPad 13" | 2064 x 2752 | iPad Pro 13-inch |

**How to Capture:**
1. Run River in iOS Simulator (Xcode → Open Developer Tool → Simulator)
2. Select device: iPhone 16 Pro Max
3. Navigate to screen you want to capture
4. **⌘ + S** (Command + S) to save screenshot
5. Repeat for each required device size

**Recommended Screenshots (5-10 images):**

1. **Timer Running (Hero Shot)**
   - Main focus view with timer at ~15:30
   - Show task name "Deep Work Session"
   - This should be your first/primary screenshot

2. **Dynamic Island Integration**
   - Show Live Activity in Dynamic Island
   - Demonstrates unique iOS integration

3. **Task Management**
   - Task list view with 3-4 tasks
   - Mix of completed and pending tasks

4. **Settings Screen**
   - Show Pro features section
   - Visible: App Blocking, timer durations, themes, sounds

5. **Session History (Pro)**
   - Calendar view with completed sessions
   - Stats showing productivity

**Tips:**
- Use light mode for consistency
- Add text overlays describing key features (optional)
- First 3 screenshots are most important (highest visibility)

### 4.3 App Preview Video (Optional but Recommended)

**Length:** 15-30 seconds
**Format:** Portrait orientation, MP4

**Suggested Storyboard:**
1. Open app → See task list (2s)
2. Tap "Start Focus" → Timer begins (3s)
3. Show Dynamic Island animation (3s)
4. Fast-forward timer completion → Break starts (3s)
5. Show session history with stats (2s)
6. End with app icon and name (2s)

**Tools:**
- **QuickTime Player** (Mac built-in) - Screen recording
- **iMovie** (Mac/iOS) - Simple editing
- **DaVinci Resolve** (free) - Advanced editing

---

## 🚀 Part 5: Build & Submit

### 5.1 Pre-Submission Checklist

Before archiving, verify:

- [ ] `debugUnlockPro = false` in PurchaseManager.swift:17 ✅ (completed)
- [ ] PrivacyInfo.xcprivacy included in project ✅ (completed)
- [ ] App icon updated (1024x1024 PNG)
- [ ] Version number set in project.yml (currently 1.0)
- [ ] All Swift code compiles without errors
- [ ] Test on physical iPhone if possible (for Live Activities)
- [ ] Verify free features work without Pro
- [ ] Verify Pro features are properly locked

### 5.2 Create Sandbox Test Account

1. [App Store Connect](https://appstoreconnect.apple.com) → **Users and Access** → **Sandbox Testers**
2. Click **"+"** to add tester
3. Use a **new email** (not your Apple ID)
4. Choose country/region matching your test needs

**On your test device:**
1. Settings → App Store → Sandbox Account
2. Sign in with sandbox tester email
3. Launch River → Go to Settings → Tap "Upgrade to Pro"
4. Purchase will show **[Sandbox]** - complete purchase
5. Verify Pro features unlock
6. Tap "Restore Purchases" to test restore flow

### 5.3 Build for Release

```bash
# 1. Clean build folder
cd /Users/georgetharian/dev/River
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# 2. Open project in Xcode
open River.xcodeproj

# 3. In Xcode:
#    - Select "Any iOS Device (arm64)" or your connected device
#    - Product → Scheme → Select "River"
#    - Product → Archive

# 4. Wait for archive to complete
#    - Organizer window will open automatically
#    - Select your archive
#    - Click "Distribute App"
```

### 5.4 Upload to App Store Connect

1. In **Organizer** window after archive:
   - Click **"Distribute App"**
   - Select **"App Store Connect"**
   - Click **"Upload"**
   - Select **"Upload Symbols"** (for crash reports)
   - Click **"Next"** through signing (automatic should work)
   - Review build info → **"Upload"**

2. Wait 5-15 minutes for processing

3. Check App Store Connect:
   - Refresh page
   - Build should appear under **"Build"** section
   - If you see warning icon, check for issues

### 5.5 Submit for Review

1. Navigate to your app version in App Store Connect
2. Fill in all metadata (name, description, screenshots, etc.)
3. Add privacy policy URL
4. Add support URL
5. Complete **App Review Information**
6. Select your build (click "+ " next to "Build")
7. Review **Export Compliance**:
   - "Does your app use encryption?" → **No** (River uses standard iOS APIs only)
   - If uncertain, answer Yes and declare exempt → most apps qualify
8. Click **"Save"** (top right)
9. Click **"Submit for Review"**

---

## ⏱️ Part 6: Review Timeline & Next Steps

### Expected Timeline
- **Processing:** 5-15 minutes after upload
- **Waiting for Review:** 1-3 days typically
- **In Review:** Few hours to 1 day
- **Total:** Usually 1-4 days from submission

### Status Meanings
- **Waiting for Review:** In queue
- **In Review:** Apple is testing your app
- **Pending Developer Release:** Approved! You control release
- **Ready for Sale:** Live on App Store
- **Rejected:** Check Resolution Center for details

### If Rejected

1. Read rejection reason carefully in **Resolution Center**
2. Fix the issue
3. Increment build number in project.yml:
   ```yaml
   CURRENT_PROJECT_VERSION: "2"  # was "1"
   ```
4. Archive and upload new build
5. Reply to rejection with explanation
6. Resubmit for review

### After Approval

1. **App Store Release:**
   - Automatic or manual release (your choice during submission)
   - App appears in search within ~24 hours

2. **Monitor:**
   - App Store Connect → **Analytics** (sales, downloads)
   - **Ratings & Reviews** (respond to users)
   - **Crashes** (if symbol upload enabled)

3. **Updates:**
   - Follow same process for version updates
   - Increment `MARKETING_VERSION` for feature updates
   - Increment `CURRENT_PROJECT_VERSION` for bug fixes

---

## 📋 Quick Reference

### Important Files
- `River/Services/PurchaseManager.swift:17` - Debug flag (MUST be false)
- `River/PrivacyInfo.xcprivacy` - Privacy manifest
- `project.yml` - Version numbers and project config
- `River/Assets.xcassets/AppIcon.appiconset/` - App icon
- `River/Services/AppBlockingService.swift` - Screen Time app blocking (Pro feature)
- `RiverDeviceActivityMonitor/` - Device activity monitoring extension
- `RiverShieldConfiguration/` - Custom shield UI extension
- `RiverShieldAction/` - Shield action handling extension

### Important IDs
- **Bundle ID:** `com.george.river`
- **Widget Bundle ID:** `com.george.river.RiverWidget`
- **Device Activity Monitor:** `com.george.river.RiverDeviceActivityMonitor`
- **Shield Configuration:** `com.george.river.RiverShieldConfiguration`
- **Shield Action:** `com.george.river.RiverShieldAction`
- **App Group:** `group.com.george.evolve`
- **IAP Product ID:** `com.george.river.pro`
- **Development Team:** `U4JCMYQA4X`

### Key Commands
```bash
# Regenerate Xcode project
xcodegen generate

# Open project
open River.xcodeproj

# Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*
```

### Useful Links
- [App Store Connect](https://appstoreconnect.apple.com)
- [Apple Developer](https://developer.apple.com/account)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)

---

## ❓ Troubleshooting

### "Product ID not found" during IAP testing
- Verify product ID exactly matches: `com.george.river.pro`
- Wait 2-3 hours after creating IAP in App Store Connect
- Ensure IAP status is "Ready to Submit"
- Sign out and back into sandbox account

### "Archive not showing in Organizer"
- Select "Any iOS Device (arm64)" before archiving
- Check build scheme is set to "Release" configuration
- Verify code signing is configured correctly

### "Missing Compliance" warning
- Go to build in App Store Connect
- Answer export compliance questions
- River doesn't use encryption (use standard Apple APIs)

### "Family Controls permission required" during review
- Ensure all extension targets have Family Controls entitlement
- Verify entitlement files exist:
  - `River/River.entitlements`
  - `RiverDeviceActivityMonitor/RiverDeviceActivityMonitor.entitlements`
  - `RiverShieldConfiguration/RiverShieldConfiguration.entitlements`
  - `RiverShieldAction/RiverShieldAction.entitlements`
- Regenerate project if needed: `xcodegen generate`

### "App blocking not working in TestFlight"
- Screen Time features require explicit authorization
- User must grant permission in Settings flow
- Test on physical device (Screen Time may not work fully in Simulator)

### Build rejected for "Missing Privacy Manifest"
- Verify PrivacyInfo.xcprivacy is in River/ directory ✅
- Regenerate project: `xcodegen generate` ✅
- Check file is included in Xcode project navigator

---

## 🎉 Final Notes

This guide covers everything needed for your first App Store submission. The critical code changes are complete - now it's about preparing marketing materials and completing the App Store Connect setup.

**Priority Order:**
1. Test IAP flow with sandbox account
2. Create/update app icon (if needed)
3. Capture screenshots
4. Write/host privacy policy
5. Complete App Store Connect metadata
6. Archive and upload build
7. Submit for review

Good luck with your submission! River looks like a polished, focused productivity app that solves a real problem. The Pomodoro technique combined with iOS Live Activities is a strong value proposition.

---

*Generated on 2026-03-04 for River v1.0*
