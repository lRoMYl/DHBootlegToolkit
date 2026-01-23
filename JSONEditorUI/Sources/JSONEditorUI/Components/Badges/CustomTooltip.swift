import SwiftUI

// MARK: - Custom Tooltip

/// Fast tooltip using popover with debounce
/// Shows after 0.2 second delay, dismisses immediately when hover ends
struct CustomTooltip: ViewModifier {
    let text: String

    @State private var isHoveringTrigger = false
    @State private var isHoveringTooltip = false
    @State private var showTooltip = false
    @State private var showTask: Task<Void, Never>?
    @State private var dismissTask: Task<Void, Never>?

    func body(content: Content) -> some View {
        content
            .contentShape(Rectangle())
            .onHover { hovering in
                isHoveringTrigger = hovering
                updateTooltipState()
            }
            .popover(isPresented: $showTooltip, arrowEdge: .top) {
                TooltipPopoverContent(text: text) { hovering in
                    isHoveringTooltip = hovering
                    updateTooltipState()
                }
            }
    }

    private func updateTooltipState() {
        showTask?.cancel()
        dismissTask?.cancel()

        if isHoveringTrigger || isHoveringTooltip {
            // Show tooltip after 0.2 second delay
            showTask = Task {
                try? await Task.sleep(for: .milliseconds(200))
                if !Task.isCancelled && (isHoveringTrigger || isHoveringTooltip) {
                    showTooltip = true
                }
            }
        } else {
            // Dismiss immediately when hover ends
            showTooltip = false
        }
    }
}

// MARK: - Tooltip Popover Content

private struct TooltipPopoverContent: View {
    let text: String
    var onHover: ((Bool) -> Void)?

    var body: some View {
        Text(text)
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .fixedSize()
            .contentShape(Rectangle())
            .onHover { hovering in
                onHover?(hovering)
            }
    }
}

// MARK: - View Extension

extension View {
    /// Applies a fast tooltip with 0.2 second debounce delay
    func fastTooltip(_ text: String) -> some View {
        self.modifier(CustomTooltip(text: text))
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        Text("Hover over items below")
            .font(.headline)

        Divider()

        HStack(spacing: 16) {
            // System tooltip (slow)
            Text("System")
                .padding(8)
                .background(Color.blue.opacity(0.2))
                .cornerRadius(4)
                .help("System tooltip - 1-2 second delay")

            // Fast custom tooltip (0.2s delay)
            Text("Fast Tooltip")
                .padding(8)
                .background(Color.green.opacity(0.2))
                .cornerRadius(4)
                .fastTooltip("Shows after 0.2 second delay")
        }

        Divider()

        Text("Tooltip Behavior:")
            .font(.subheadline)
            .fontWeight(.semibold)

        VStack(alignment: .leading, spacing: 4) {
            Text("• 0.2 second delay before showing")
            Text("• Dismisses immediately when hover ends")
            Text("• Stable hover detection")
            Text("• Prevents accidental tooltip triggers")
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding()
        .background(Color.green.opacity(0.1))
        .cornerRadius(8)
    }
    .padding()
    .frame(width: 500, height: 300)
}
