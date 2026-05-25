# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

River is an iOS Pomodoro focus timer app built with SwiftUI and Swift 6.0, targeting iOS 17.0+. It features Live Activities (Dynamic Island integration), WidgetKit support, session history tracking, customizable themes, and sound effects.

## Build System

This project uses **XcodeGen** (`project.yml`) to generate the Xcode project file.

### Key Commands

```bash
# Generate Xcode project from project.yml (required after any project.yml change)
xcodegen generate

# Open project in Xcode
open River.xcodeproj

# Build iOS app
xcodebuild -project River.xcodeproj -scheme River -destination 'platform=iOS Simulator,name=iPhone 15' build

# Build macOS app
xcodebuild -project River.xcodeproj -scheme RiverMac -destination 'platform=macOS' build

# Build watchOS app
xcodebuild -project River.xcodeproj -scheme RiverWatch -destination 'platform=watchOS Simulator,name=Apple Watch Series 9 (45mm)' build
```

**Important**: The Xcode project file (`River.xcodeproj`) is generated from `project.yml`. If you need to modify project settings, targets, or build configurations, edit `project.yml` and regenerate with `xcodegen generate`.

### Tests & Lint

No XCTest targets, no SwiftLint/swift-format config. Verification = `xcodebuild build` for each scheme.

## Architecture

### Core Components

1. **Timer System** (`FocusTimerService`)
   - Singleton service managing Pomodoro timer lifecycle
   - Uses `@Observable` macro for SwiftUI state management
   - Handles work phases, short breaks, and long breaks
   - Persists state to App Group shared storage for widget access

2. **Shared State Management** (`River/Shared/`)
   - `TimerState`: Codable timer state shared between app and widget via App Group
   - `AppGroup`: Centralized App Group configuration (`group.com.george.evolve`)
   - `SharedDataManager`: App↔widget bridge — `getTimerState()` / `saveTimerState(_:)` over App Group `UserDefaults`
   - Darwin notifications (`CFNotificationCenter`) signal state changes cross-process; constant is `NotificationNames.timerStateChanged` (`"com.george.evolve.timerStateChanged"`) in `River/Shared/Constants.swift`

3. **Live Activities** (`LiveActivityService` + `RiverWidget/FocusLiveActivity.swift`)
   - Dynamic Island and Lock Screen timer display
   - Uses ActivityKit with `FocusActivityAttributes` and content state
   - **Interactive buttons** (e.g., pause/resume in Dynamic Island) use `ToggleFocusTimerIntent: LiveActivityIntent` (AppIntents, `River/Shared/FocusTimerIntent.swift`) — runs in-process without opening the app
   - **Tap-to-open** controls use `river://` deep links (`river://pomodoro/start`, `/pause`, `/skip`)

4. **Data Persistence**
   - **SwiftData + CloudKit**: `FocusTask`, `DeletedTask`, `SessionRecord` models. iOS and macOS configure `ModelContainer` with `cloudKitDatabase: .private("iCloud.com.george.river")` and fall back to local-only storage on error ([River/RiverApp.swift:9-29](River/RiverApp.swift), [RiverMac/RiverMacApp.swift:16-33](RiverMac/RiverMacApp.swift)). CloudKit requires every model property to be optional or have a default.
   - **UserDefaults**: Timer settings (work duration, break duration, etc.)
   - **App Group UserDefaults**: Shared timer state between app and widget
   - **SessionHistoryService**: JSON-encoded session records in UserDefaults

5. **Services Layer**
   - `FocusTimerService`: Timer lifecycle and state management (shared with macOS)
   - `LiveActivityService`: Live Activity integration (iOS only)
   - `SessionHistoryService`: Tracks completed sessions, streaks, and stats (shared with macOS)
   - `CloudSettingsManager`: Syncs settings across devices via `NSUbiquitousKeyValueStore` (shared with macOS)
   - `SoundService`: Plays transition sounds with haptic feedback
   - `PurchaseManager`: StoreKit + Pro tiers. `ProTier` is `.none`/`.devicePro`/`.sync`; `isPro` = any tier, `isSync` = sync only. Per-platform product IDs (`com.george.river.pro` iOS, `com.george.river.mac.pro` macOS, `com.george.river.sync` cross-platform). Debug bypass: `debugTier` at [PurchaseManager.swift:32](River/Services/PurchaseManager.swift).
   - `WatchConnectivityService`: Real-time iPhone↔Watch sync. iPhone pushes `TimerState` on every persist cycle; watch sends control commands (`pause`/`resume`/`skip`/`stop`). Uses `sendMessage` when reachable with `updateApplicationContext` fallback. Two parallel singletons under `River/Services/` and `RiverWatch/Services/`.
   - `AppBlockingService`: Manages Screen Time app blocking using FamilyControls framework
   - `AppBlockingAuthorizationService`: Handles Family Controls authorization requests

6. **Cross-Platform Abstractions** (`River/Shared/Protocols/`)
   - `LiveActivityServiceProtocol`, `AppBlockingServiceProtocol`, `FeedbackServiceProtocol`
   - Each protocol has a `NoOp*Service` implementation (e.g., `NoOpAppBlockingService`) that `FocusTimerService.init` injects on non-iOS targets — add a `NoOp*` when adding a new iOS-only service
   - `PlatformCapabilities`: Compile-time and runtime feature detection; check this before calling platform-specific APIs (e.g., `supportsDarwinNotifications` is false on watchOS)

### Targets / Extensions

**RiverWidget** (WidgetKit, iOS)
- Sources: `RiverWidget/` + `River/Shared/`

**RiverMac** (macOS 14.0+, menu-bar app)
- Sources: `RiverMac/` + `River/Shared/` + `River/Models/` + selected services (`FocusTimerService`, `SessionHistoryService`, `CloudSettingsManager`, `Theme.swift`)
- Does **not** include iOS-only services: `LiveActivityService`, `AppBlockingService`, `SoundService`, `PurchaseManager`
- Menu bar entry point in `RiverMac/MenuBar/MenuBarView.swift`

**RiverWatch** (watchOS 10.0+)
- Sources: `RiverWatch/` + `River/Shared/` (excludes `Components/**`)
- Companion app — `WKCompanionAppBundleIdentifier: com.george.river`
- Syncs with iPhone via WatchConnectivity (not Darwin notifications, which aren't available on watchOS). No local CloudKit container — relies on `WatchConnectivityService` for live state.

**Screen Time/Family Controls Extensions** (iOS Pro Feature)
- `RiverDeviceActivityMonitor`, `RiverShieldConfiguration`, `RiverShieldAction`
- Require Family Controls entitlement + user authorization
- Use `ManagedSettingsStore` to apply shields during focus sessions

### Theme System

- `ThemeManager`: Singleton managing current theme selection
- `AppTheme` enum: Defines color themes (River, Forest, Sunset, Ocean, Stone)
- `AppColors`: Dynamic colors that adapt to selected theme and dark/light mode
- Theme affects accent colors throughout the app

## Project Structure

```
River/
├── Models/               # SwiftData models (FocusTask, DeletedTask, etc.)
├── Views/                # SwiftUI views (TaskListView, FocusView, SettingsView, etc.)
├── Services/             # Business logic services (FocusTimerService, SessionHistoryService, etc.)
├── Shared/               # Code shared with widget (TimerState, AppGroup, etc.)
├── Resources/            # Assets, fonts, sounds
├── Theme.swift           # App-wide theming and styling
├── ContentView.swift     # Root tab view
└── RiverApp.swift        # App entry point with SwiftData container

RiverWidget/
├── FocusLiveActivity.swift    # Live Activity implementation
└── RiverWidgetBundle.swift    # Widget bundle
```

## Key Configuration

| Target | Bundle ID | Platform |
|--------|-----------|----------|
| River (iOS) | `com.george.river` | iOS 17.0+ |
| RiverWidget | `com.george.river.RiverWidget` | iOS 17.0+ |
| RiverMac | `com.george.river.mac` | macOS 14.0+ |
| RiverWatch | `com.george.river.watchkitapp` | watchOS 10.0+ |

- **App Group**: `group.com.george.evolve` (all targets share this)
- **iCloud Container**: `iCloud.com.george.river` (iOS, macOS, watchOS)
- **Development Team**: `U4JCMYQA4X`
- **Swift Version**: 6.0 (strict concurrency)
- **Custom Fonts**: Cormorant Garamond (timer display), Nunito (UI)

## Important Implementation Details

1. **Timer Persistence**: Timer survives backgrounding/termination by storing `phaseEndDate` and computing `remainingSeconds` from current time on resume.

2. **Cross-Process Sync**: iOS app ↔ widget uses App Group `UserDefaults` + Darwin notifications (`CFNotificationCenter`). iPhone ↔ Watch uses WatchConnectivity (`sendMessage` when reachable, `updateApplicationContext` as fallback). watchOS does not support Darwin notifications.

3. **iCloud Settings Sync**: `CloudSettingsManager` syncs timer durations, theme, and sound settings across devices via `NSUbiquitousKeyValueStore`. `syncFromCloud()` only overwrites local values when no local value exists; use `forceSyncFromCloud()` to override.

4. **Session Tracking**: Work sessions are automatically saved to history when completed or skipped (see `FocusTimerService.swift:122-127` and `:172-178`).

5. **Swift 6.0 Strict Concurrency**: Services are `@Observable @MainActor`. Shared code compiled into multiple targets must compile cleanly for all target platforms — use `#if os(iOS)` guards for platform-specific APIs.

6. **Pro Features & Debug Mode**: `PurchaseManager.debugTier` ([PurchaseManager.swift:32](River/Services/PurchaseManager.swift)) bypasses StoreKit for local testing (currently `.devicePro`). **Set to `.none` before App Store submission.** Two-tier model: device-Pro per platform vs. Sync (cross-platform). See `ProTier` enum for entitlement checks.

7. **Sound Effects**: Audio files expected in `River/Resources/Sounds/`. `TransitionSound.swift` (in `River/Shared/`) defines the sound enum used across targets.

8. **Release version bump**: To submit a new build, increment `CURRENT_PROJECT_VERSION` in `project.yml`, then run `xcodegen generate`. Increment `MARKETING_VERSION` for feature releases.
