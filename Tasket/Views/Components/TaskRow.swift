import SwiftUI

struct TaskRow: View {
    let title: String
    let subtitle: String?
    let isCompleted: Bool
    let isPinned: Bool

    let showCircle: Bool
    let accent: Color
    let onToggleComplete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            if showCircle {
                Button(action: onToggleComplete) {
                    Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                        .imageScale(.large)
                        .foregroundStyle(isCompleted ? accent : Color.secondary)
                }
                .buttonStyle(.plain)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .strikethrough(isCompleted)
                        .foregroundStyle(isCompleted ? .secondary : .primary)

                    if isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .contentShape(Rectangle())
    }
}
