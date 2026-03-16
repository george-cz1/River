import SwiftUI

/// Reusable circular button with icon
struct CircleButton: View {
    let systemName: String
    let size: CGFloat
    let color: Color
    let backgroundColor: Color
    let action: () -> Void

    init(
        systemName: String,
        size: CGFloat = 48,
        color: Color = .primary,
        backgroundColor: Color = .secondary,
        action: @escaping () -> Void
    ) {
        self.systemName = systemName
        self.size = size
        self.color = color
        self.backgroundColor = backgroundColor
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.36, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: size, height: size)
                .background(backgroundColor)
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
