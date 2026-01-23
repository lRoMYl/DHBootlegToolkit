import SwiftUI
import JSONEditorCore

// MARK: - Validation Status Bubble

/// Collapsed circular bubble showing validation status
public struct ValidationStatusBubble: View {
    let result: JSONSchemaValidationResult
    let onTap: () -> Void

    public init(result: JSONSchemaValidationResult, onTap: @escaping () -> Void) {
        self.result = result
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            ZStack {
                if result.errorCount > 0 {
                    // Error state: show icon with number badge
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(result.errorCount > 0 ? .red : .orange)
                        .font(.title3)

                    // Number badge in top-right
                    Text("\(result.errorCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .padding(4)
                        .background(result.errorCount > 0 ? Color.red : Color.orange, in: Circle())
                        .offset(x: 12, y: -12)
                } else {
                    // Success state: show checkmark
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.title3)
                }
            }
            .frame(width: 44, height: 44)
            .background(.ultraThinMaterial, in: Circle())
            .overlay {
                Circle()
                    .strokeBorder(
                        result.errorCount > 0
                            ? (result.errorCount > 0 ? Color.red : Color.orange).opacity(0.3)
                            : Color.green.opacity(0.3),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: result.errorCount > 0
                    ? (result.errorCount > 0 ? Color.red : Color.orange).opacity(0.2)
                    : Color.green.opacity(0.2),
                radius: 8,
                x: 0,
                y: 2
            )
        }
        .buttonStyle(.plain)
        .padding(16)
        .transition(.opacity)
    }
}
