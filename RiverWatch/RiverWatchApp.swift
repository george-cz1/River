//
//  RiverWatchApp.swift
//  RiverWatch
//
//  watchOS app entry point for River Pomodoro Timer
//

import SwiftUI

@main
struct RiverWatchApp: App {
    @State private var timerService = FocusTimerService.shared
    @State private var cloudSettingsManager = CloudSettingsManager.shared

    var body: some Scene {
        WindowGroup {
            WatchTimerView()
                .environment(timerService)
        }
    }
}
