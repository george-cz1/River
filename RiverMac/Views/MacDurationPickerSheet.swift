import SwiftUI

struct MacDurationPickerSheet: View {
    let label: String
    let iconName: String
    let iconColor: Color
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let presets: [Int]

    @Environment(\.dismiss) private var dismiss
    @State private var selectedMinutes: Int

    init(
        label: String,
        iconName: String,
        iconColor: Color,
        value: Binding<Int>,
        range: ClosedRange<Int>,
        unit: String,
        presets: [Int]
    ) {
        self.label = label
        self.iconName = iconName
        self.iconColor = iconColor
        self._value = value
        self.range = range
        self.unit = unit
        self.presets = presets
        self._selectedMinutes = State(initialValue: value.wrappedValue / 60)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Button("Cancel") { dismiss() }
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                    .buttonStyle(.plain)

                Spacer()

                Text(label)
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Button("Done") {
                    value = selectedMinutes * 60
                    dismiss()
                }
                .font(AppFonts.headline)
                .foregroundStyle(AppColors.sage)
                .buttonStyle(.plain)
            }
            .padding(16)

            Divider()

            ScrollView {
                VStack(spacing: 24) {
                    // Icon + current value
                    VStack(spacing: 12) {
                        Image(systemName: iconName)
                            .font(.system(size: 48))
                            .foregroundStyle(iconColor)

                        Text("\(selectedMinutes) \(unit)")
                            .font(AppFonts.title)
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .padding(.top, 20)

                    // Quick select presets
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Quick Select")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
                            spacing: 12
                        ) {
                            ForEach(presets, id: \.self) { preset in
                                Button {
                                    selectedMinutes = preset
                                } label: {
                                    Text("\(preset)")
                                        .font(AppFonts.body)
                                        .foregroundStyle(
                                            selectedMinutes == preset ? AppColors.background : AppColors.textPrimary
                                        )
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(selectedMinutes == preset ? iconColor : AppColors.surface)
                                        )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Precise stepper
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Or choose precisely")
                            .font(AppFonts.caption)
                            .foregroundStyle(AppColors.textSecondary)

                        HStack {
                            Button {
                                if selectedMinutes > range.lowerBound {
                                    selectedMinutes -= 1
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppColors.textSecondary)
                            }
                            .buttonStyle(.plain)

                            Spacer()

                            Text("\(selectedMinutes) \(unit)")
                                .font(AppFonts.title)
                                .foregroundStyle(AppColors.textPrimary)
                                .frame(minWidth: 80)
                                .multilineTextAlignment(.center)

                            Spacer()

                            Button {
                                if selectedMinutes < range.upperBound {
                                    selectedMinutes += 1
                                }
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(AppColors.sage)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(16)
                        .background(AppColors.surface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    Spacer(minLength: 20)
                }
                .padding(24)
            }
        }
        .background(AppColors.background)
        .frame(width: 400, height: 480)
    }
}

// MARK: - Mac Duration Row (reusable in MacSettingsView)

struct MacDurationRow: View {
    let label: String
    let iconName: String
    let iconColor: Color
    @Binding var value: Int
    let range: ClosedRange<Int>
    let unit: String
    let presets: [Int]

    @State private var showingPicker = false

    private var minutes: Int { value / 60 }

    var body: some View {
        Button {
            showingPicker = true
        } label: {
            HStack {
                Label {
                    Text(label)
                        .font(AppFonts.body)
                        .foregroundStyle(AppColors.textPrimary)
                } icon: {
                    Image(systemName: iconName)
                        .foregroundStyle(iconColor)
                }

                Spacer()

                Text("\(minutes) \(unit)")
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textPrimary)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingPicker) {
            MacDurationPickerSheet(
                label: label,
                iconName: iconName,
                iconColor: iconColor,
                value: $value,
                range: range,
                unit: unit,
                presets: presets
            )
        }
    }
}
