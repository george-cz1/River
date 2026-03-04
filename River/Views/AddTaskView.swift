import SwiftUI

struct AddTaskView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var title: String
    let onAdd: () -> Void

    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Task name")
                        .font(AppFonts.caption)
                        .foregroundStyle(AppColors.textSecondary)

                    TextField("What do you need to do?", text: $title)
                        .font(AppFonts.body)
                        .padding(14)
                        .background(Color(UIColor.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .focused($isTextFieldFocused)
                        .submitLabel(.done)
                        .onSubmit {
                            if !title.trimmingCharacters(in: .whitespaces).isEmpty {
                                onAdd()
                                dismiss()
                            }
                        }
                }

                Spacer()
            }
            .padding(20)
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(AppColors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        onAdd()
                        dismiss()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.focusBlue)
                }
            }
            .onAppear {
                isTextFieldFocused = true
            }
        }
        .presentationDetents([.height(220)])
        .presentationDragIndicator(.visible)
    }
}
