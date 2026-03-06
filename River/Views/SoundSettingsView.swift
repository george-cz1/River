import SwiftUI

/// View for configuring transition sounds and haptics
struct SoundSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var soundService = SoundService.shared
    @State private var selectedSound: TransitionSound
    @State private var hapticsEnabled: Bool

    init() {
        let service = SoundService.shared
        _selectedSound = State(initialValue: service.selectedSound)
        _hapticsEnabled = State(initialValue: service.hapticsEnabled)
    }

    var body: some View {
        NavigationStack {
            List {
                descriptionSection
                soundSection
                hapticSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle("Sounds & Haptics")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    DismissToolbarButton()
                }
            }
        }
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                Text("Customize Feedback")
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Text("Choose sounds and haptic feedback for when focus sessions and breaks complete.")
                    .font(AppFonts.caption)
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .listRowBackground(Color.clear)
        }
    }

    // MARK: - Sound Section

    private var soundSection: some View {
        Section {
            ForEach(TransitionSound.allCases, id: \.self) { sound in
                Button {
                    selectedSound = sound
                    soundService.selectedSound = sound
                    soundService.play(sound)
                } label: {
                    HStack {
                        Label {
                            Text(sound.displayName)
                                .font(AppFonts.body)
                                .foregroundStyle(AppColors.textPrimary)
                        } icon: {
                            Image(systemName: sound.icon)
                                .foregroundStyle(AppColors.river)
                        }

                        Spacer()

                        if selectedSound == sound {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                        } else {
                            Button {
                                soundService.play(sound)
                            } label: {
                                Image(systemName: "play.circle")
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        } header: {
            Text("Transition Sound")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        } footer: {
            Text("Tap the play button to preview each sound.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }

    // MARK: - Haptic Section

    private var hapticSection: some View {
        Section {
            Toggle(isOn: Binding(
                get: { hapticsEnabled },
                set: { newValue in
                    hapticsEnabled = newValue
                    soundService.hapticsEnabled = newValue
                    if newValue {
                        soundService.playHaptic()
                    }
                }
            )) {
                Label {
                    Text("Haptic Feedback")
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                } icon: {
                    Image(systemName: "hand.tap.fill")
                        .foregroundStyle(AppColors.river)
                }
            }
            .tint(AppColors.river)
        } header: {
            Text("Physical Feedback")
                .font(AppFonts.caption2)
                .foregroundStyle(AppColors.textSecondary)
                .textCase(nil)
        } footer: {
            Text("Feel a gentle vibration when phases complete.")
                .font(AppFonts.caption)
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}

// MARK: - Preview

#Preview {
    SoundSettingsView()
}
