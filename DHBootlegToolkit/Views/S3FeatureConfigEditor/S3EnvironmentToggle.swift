import SwiftUI
import DHBootlegToolkitCore

// MARK: - S3 Environment Toggle

/// Segmented control for switching between Staging and Production environments
struct S3EnvironmentToggle: View {
    @Environment(S3Store.self) private var store

    var body: some View {
        HStack(spacing: 0) {
            ForEach(S3Environment.allCases, id: \.self) { env in
                Button {
                    Task {
                        await store.switchEnvironment(to: env)
                    }
                } label: {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(env == .staging ? .orange : .green)
                            .frame(width: 6, height: 6)

                        Text(env.displayName)
                            .font(.subheadline)
                            .fontWeight(store.selectedEnvironment == env ? .medium : .regular)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        store.selectedEnvironment == env
                            ? Color.accentColor
                            : Color.clear
                    )
                    .foregroundStyle(
                        store.selectedEnvironment == env
                            ? .white
                            : .primary
                    )
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color(nsColor: .controlBackgroundColor), in: Capsule())
        .clipShape(Capsule())
    }
}

#Preview {
    S3EnvironmentToggle()
        .environment(S3Store())
        .padding()
}
