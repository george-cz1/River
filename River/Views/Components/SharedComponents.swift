import SwiftUI

// MARK: - DismissToolbarButton

/// Reusable dismiss button for toolbars
struct DismissToolbarButton: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.textSecondary)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
