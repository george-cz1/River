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
   - `SharedDataManager`: Persists/retrieves `TimerState` using `UserDefaults` in App Group
   - Uses Darwin notifications (`CFNotificationCenter`) for cross-process state sync

3. **Live Activities** (`LiveActivityService` + `RiverWidget/FocusLiveActivity.swift`)
   - Dynamic Island and Lock Screen timer display
   - Uses ActivityKit with `FocusActivityAttributes` and content state
   - Widget controls deep link back to app via `river://` URL scheme

4. **Data Persistence**
   - **SwiftData**: `FocusTask` and `DeletedTask` models for task management
   - **UserDefaults**: Timer settings (work duration, break duration, etc.)
   - **App Group UserDefaults**: Shared timer state between app and widget
   - **SessionHistoryService**: JSON-encoded session records in UserDefaults

5. **Services Layer**
   - `FocusTimerService`: Timer lifecycle and state management (shared with macOS)
   - `LiveActivityService`: Live Activity integration (iOS only)
   - `SessionHistoryService`: Tracks completed sessions, streaks, and stats (shared with macOS)
   - `CloudSettingsManager`: Syncs settings across devices via `NSUbiquitousKeyValueStore` (shared with macOS)
   - `SoundService`: Plays transition sounds with haptic feedback
   - `PurchaseManager`: Handles StoreKit purchases for Pro features
   - `AppBlockingService`: Manages Screen Time app blocking using FamilyControls framework
   - `AppBlockingAuthorizationService`: Handles Family Controls authorization requests

6. **Cross-Platform Abstractions** (`River/Shared/Protocols/`)
   - `LiveActivityServiceProtocol`, `AppBlockingServiceProtocol`, `FeedbackServiceProtocol`
   - `PlatformCapabilities`: Compile-time and runtime feature detection; use this before calling platform-specific APIs (e.g., Darwin notifications are unsupported on watchOS)

### Targets / Extensions

**RiverWidget** (WidgetKit, iOS)
- Sources: `RiverWidget/` + `River/Shared/`

**RiverMac** (macOS 14.0+, menu-bar app)
- Sources: `RiverMac/` + `River/Shared/` + `River/Models/` + selected services (`FocusTimerService`, `SessionHistoryService`, `CloudSettingsManager`, `Theme.swift`)
- Does **not** include iOS-only services: `LiveActivityService`, `AppBlockingService`, `SoundService`, `PurchaseManager`
- Menu bar entry point in `RiverMac/MenuBar/MenuBarView.swift`

**RiverWatch** (watchOS 10.0+)
- Sources: `RiverWatch/` + `River/Shared/`
- Companion app — `WKCompanionAppBundleIdentifier: com.george.river`
- Darwin notifications (`CFNotificationCenter`) are **not** available; use App Group UserDefaults for state

**Screen Time/Family Controls Extensions** (iOS Pro Feature)
- `RiverDeviceActivityMonitor`, `RiverShieldConfiguration`, `RiverShieldAction`
- Require Family Controls entitlement + user authorization
- Use `ManagedSettingsStore` to apply shields during focus sessions

### Theme System

- `ThemeManager`: Singleton managing current theme selection
- `AppTheme` enum: Defines color themes (River, Forest, Sunset, Ocean, Stone)
- `AppColors`: Dynamic colors that adapt to selected theme and dark/light mode
- Theme affects accent colors throughout the app

### Deep Linking

- URL Scheme: `river://`
- Handles Dynamic Island control actions:
  - `river://pomodoro/start`
  - `river://pomodoro/pause`
  - `river://pomodoro/skip`

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

2. **Widget/Cross-Process Sync**: State changes propagate via shared App Group UserDefaults + Darwin notifications (`CFNotificationCenter`). watchOS cannot use Darwin notifications — use App Group UserDefaults polling instead.

3. **iCloud Settings Sync**: `CloudSettingsManager` syncs timer durations, theme, and sound settings across devices via `NSUbiquitousKeyValueStore`. `syncFromCloud()` only overwrites local values when no local value exists; use `forceSyncFromCloud()` to override.

4. **Session Tracking**: Work sessions are automatically saved to history when completed or skipped (see `FocusTimerService.swift:122-127` and `:172-178`).

5. **Swift 6.0 Strict Concurrency**: Services are `@Observable @MainActor`. Shared code compiled into multiple targets must compile cleanly for all target platforms — use `#if os(iOS)` guards for platform-specific APIs.

6. **Pro Features & Debug Mode**: `PurchaseManager` has a `debugUnlockPro` flag (currently `true`) that bypasses StoreKit for local testing. **Set to `false` before App Store submission.**

7. **Sound Effects**: Audio files expected in `River/Resources/Sounds/`. `TransitionSound.swift` (in `River/Shared/`) defines the sound enum used across targets.

## gstack

Use the `/browse` skill from gstack for all web browsing. Never use `mcp__claude-in-chrome__*` tools.

Available gstack skills:
- `/office-hours` — structured thinking and decision-making sessions
- `/plan-ceo-review` — CEO-level plan review
- `/plan-eng-review` — engineering plan review
- `/plan-design-review` — design plan review
- `/design-consultation` — design consultation
- `/design-shotgun` — rapid design exploration
- `/review` — code review
- `/ship` — ship a feature end-to-end
- `/land-and-deploy` — land and deploy changes
- `/canary` — canary deployment
- `/benchmark` — performance benchmarking
- `/browse` — web browsing (use this for ALL web browsing)
- `/connect-chrome` — connect to Chrome browser
- `/qa` — QA testing
- `/qa-only` — QA without implementation
- `/design-review` — design review
- `/setup-browser-cookies` — set up browser cookies
- `/setup-deploy` — set up deployment
- `/retro` — retrospective
- `/investigate` — investigate issues
- `/document-release` — document a release
- `/codex` — Codex integration
- `/cso` — CSO workflow
- `/autoplan` — automatic planning
- `/careful` — careful/cautious mode
- `/freeze` — freeze changes
- `/guard` — guard against regressions
- `/unfreeze` — unfreeze changes
- `/gstack-upgrade` — upgrade gstack to latest
