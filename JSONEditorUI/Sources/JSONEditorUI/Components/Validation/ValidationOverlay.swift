import SwiftUI
import JSONEditorCore

// MARK: - Validation Overlay

/// Generic floating overlay container for validation status (bottom-right positioning)
/// Supports 3 states: loading, collapsed, expanded
public struct ValidationOverlay: View {
    let isLoading: Bool
    let validationResult: JSONSchemaValidationResult?
    @Binding var isExpanded: Bool
    let onErrorTap: (ValidationError) -> Void

    public init(
        isLoading: Bool,
        validationResult: JSONSchemaValidationResult?,
        isExpanded: Binding<Bool>,
        onErrorTap: @escaping (ValidationError) -> Void
    ) {
        self.isLoading = isLoading
        self.validationResult = validationResult
        self._isExpanded = isExpanded
        self.onErrorTap = onErrorTap
    }

    public var body: some View {
        Group {
            if isLoading {
                // Loading state: show spinner
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: Circle())
                    .overlay {
                        Circle()
                            .strokeBorder(Color.blue.opacity(0.3), lineWidth: 1)
                    }
                    .shadow(color: Color.blue.opacity(0.15), radius: 8, x: 0, y: 2)
                    .padding(16)
                    .transition(.opacity)
            } else if let result = validationResult {
                // Validation result available: show collapsed or expanded
                if isExpanded {
                    ValidationPanel(
                        result: result,
                        onCollapse: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isExpanded = false
                            }
                        },
                        onErrorTap: onErrorTap
                    )
                } else {
                    ValidationStatusBubble(result: result) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isExpanded = true
                        }
                    }
                }
            }
        }
    }
}
