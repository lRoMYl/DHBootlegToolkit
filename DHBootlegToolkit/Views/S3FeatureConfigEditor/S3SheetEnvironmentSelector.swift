import SwiftUI
import DHBootlegToolkitCore

/// Environment selector designed for sheets (with label)
struct S3SheetEnvironmentSelector: View {
    @Binding var selectedEnvironment: S3Environment
    let onChange: (S3Environment) async -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Target Environment:")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 0) {
                ForEach(S3Environment.allCases, id: \.self) { env in
                    Button {
                        Task {
                            await onChange(env)
                        }
                    } label: {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(env == .staging ? .orange : .green)
                                .frame(width: 6, height: 6)

                            Text(env.displayName)
                                .font(.subheadline)
                                .fontWeight(selectedEnvironment == env ? .medium : .regular)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            selectedEnvironment == env ? Color.accentColor : Color.clear
                        )
                        .foregroundStyle(
                            selectedEnvironment == env ? .white : .primary
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
            .clipShape(Capsule())
        }
    }
}
