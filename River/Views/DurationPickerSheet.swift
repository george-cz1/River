import SwiftUI

struct DurationPickerSheet: View {
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
        NavigationStack {
            VStack(spacing: 24) {
                // Header with icon and current value
                VStack(spacing: 12) {
                    Image(systemName: iconName)
                        .font(.system(size: 48))
                        .foregroundStyle(iconColor)

                    Text("\(selectedMinutes) \(unit)")
                        .font(AppFonts.title)
                        .foregroundStyle(AppColors.textPrimary)
                }
                .padding(.top, 20)

                // Preset buttons
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Select")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, 4)

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
                        ForEach(presets, id: \.self) { preset in
                            Button {
                                selectedMinutes = preset
                                let generator = UIImpactFeedbackGenerator(style: .light)
                                generator.impactOccurred()
                            } label: {
                                Text("\(preset)")
                                    .font(AppFonts.body)
                                    .foregroundStyle(selectedMinutes == preset ? AppColors.background : AppColors.textPrimary)
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
                .padding(.horizontal, 20)

                // Wheel picker
                VStack(alignment: .leading, spacing: 12) {
                    Text("Or choose precisely")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.horizontal, 4)

                    Picker("Duration", selection: $selectedMinutes) {
                        ForEach(Array(range), id: \.self) { minute in
                            Text("\(minute) \(unit)")
                                .font(AppFonts.body)
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 150)
                    .onChange(of: selectedMinutes) { oldValue, newValue in
                        let generator = UISelectionFeedbackGenerator()
                        generator.selectionChanged()
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(AppColors.background)
            .navigationTitle(label)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .font(AppFonts.body)
                    .foregroundStyle(AppColors.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        value = selectedMinutes * 60
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        dismiss()
                    }
                    .font(AppFonts.headline)
                    .foregroundStyle(AppColors.sage)
                }
            }
        }
        .presentationDetents([.medium])
    }
}
