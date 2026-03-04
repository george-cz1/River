# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

River is an iOS Pomodoro focus timer app built with SwiftUI and Swift 6.0, targeting iOS 17.0+. It features Live Activities (Dynamic Island integration), WidgetKit support, session history tracking, customizable themes, and sound effects.

## Build System

This project uses **XcodeGen** (`project.yml`) to generate the Xcode project file.

### Key Commands

```bash
# Generate Xcode project from project.yml
xcodegen generate

# Open project in Xcode
open River.xcodeproj

# Build and run (use Xcode or xcodebuild)
xcodebuild -project River.xcodeproj -scheme River -destination 'platform=iOS Simulator,name=iPhone 15' build
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
   - `FocusTimerService`: Timer lifecycle and state management
   - `LiveActivityService`: Live Activity integration
   - `SessionHistoryService`: Tracks completed sessions, streaks, and stats
   - `SoundService`: Plays transition sounds with haptic feedback
   - `PurchaseManager`: Handles StoreKit purchases for Pro features

### Widget Extension

- **Target**: `RiverWidget` (WidgetKit extension)
- **Sources**: `RiverWidget/` + shared code from `River/Shared/`
- **Capabilities**: App Groups (`group.com.george.evolve`)
- Widget displays current timer state and provides interactive controls

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

- **Bundle ID**: `com.george.river`
- **Widget Bundle ID**: `com.george.river.RiverWidget`
- **App Group**: `group.com.george.evolve`
- **Development Team**: `U4JCMYQA4X`
- **Deployment Target**: iOS 17.0
- **Swift Version**: 6.0
- **Custom Fonts**: Cormorant Garamond (timer), Nunito (UI)

## Important Implementation Details

1. **Timer Persistence**: The timer continues running in the background by storing `phaseEndDate` and calculating `remainingSeconds` from the current time. This allows the timer to survive app backgrounding/termination.

2. **Widget Sync**: Changes to timer state (start/pause/skip) are propagated to the widget via shared UserDefaults and Darwin notifications. Both app and widget read from the same `TimerState` persisted in App Group.

3. **Session Tracking**: Work sessions are automatically saved to history when completed or skipped (see `FocusTimerService.swift:122-127` and `:172-178`).

4. **StoreKit Configuration**: In-app purchases configured in `Configuration.storekit` for Pro features.

5. **Sound Effects**: The app expects sound files in `River/Resources/Sounds/` (see README.md in that directory).
