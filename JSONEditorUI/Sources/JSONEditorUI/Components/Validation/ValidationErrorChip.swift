import SwiftUI
import JSONEditorCore

// MARK: - Validation Error Chip

/// A compact chip displaying a validation error or warning
public struct ValidationErrorChip: View {
    let error: ValidationError
    let onTap: () -> Void

    public init(error: ValidationError, onTap: @escaping () -> Void) {
        self.error = error
        self.onTap = onTap
    }

    public var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: error.severity == .error ? "xmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(error.severity == .error ? .red : .orange)

                VStack(alignment: .leading, spacing: 2) {
                    Text(error.pathString)
                        .font(.caption.monospaced())
                        .foregroundStyle(.primary)

                    Text(error.message)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder((error.severity == .error ? Color.red : Color.orange).opacity(0.2), lineWidth: 0.5)
            }
        }
        .buttonStyle(.plain)
        .help("Click to navigate to this error")
    }
}
