import SwiftUI
import JSONEditorCore

// MARK: - Validation Panel

/// Expanded validation panel showing full details with error chips
public struct ValidationPanel: View {
    let result: JSONSchemaValidationResult
    let onCollapse: () -> Void
    let onErrorTap: (ValidationError) -> Void

    public init(
        result: JSONSchemaValidationResult,
        onCollapse: @escaping () -> Void,
        onErrorTap: @escaping (ValidationError) -> Void
    ) {
        self.result = result
        self.onCollapse = onCollapse
        self.onErrorTap = onErrorTap
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: result.errorCount > 0 ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundStyle(result.errorCount > 0 ? .red : .green)
                    .imageScale(.medium)

                if result.errorCount > 0 {
                    Text("\(result.errorCount) error\(result.errorCount == 1 ? "" : "s")\(result.warningCount > 0 ? ", \(result.warningCount) warning\(result.warningCount == 1 ? "" : "s")" : "")")
                        .font(.headline)
                } else {
                    Text("Validation passed")
                        .font(.headline)
                        .foregroundStyle(.green)
                }

                Spacer()

                Button {
                    onCollapse()
                } label: {
                    Image(systemName: "chevron.down.circle.fill")
                        .foregroundStyle(.secondary)
                        .imageScale(.large)
                }
                .buttonStyle(.plain)
            }

            if result.errorCount > 0 {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(result.errors) { error in
                            ValidationErrorChip(error: error) {
                                onErrorTap(error)
                            }
                        }
                    }
                }
            } else {
                Text("All schema validations passed successfully")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: 500)
        .padding(16)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder((result.errorCount > 0 ? Color.red : Color.green).opacity(0.3), lineWidth: 1)
        }
        .shadow(color: (result.errorCount > 0 ? Color.red : Color.green).opacity(0.2), radius: 12, x: 0, y: 4)
        .padding(16)
        .transition(.asymmetric(
            insertion: .scale(scale: 0.8, anchor: .bottomTrailing).combined(with: .opacity),
            removal: .scale(scale: 0.8, anchor: .bottomTrailing).combined(with: .opacity)
        ))
    }
}
