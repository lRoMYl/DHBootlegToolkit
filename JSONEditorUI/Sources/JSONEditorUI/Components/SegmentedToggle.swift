import SwiftUI

// MARK: - Segmented Toggle

/// Generic segmented control for any enum type
/// Works with any enum that conforms to Hashable & CaseIterable
public struct SegmentedToggle<T: Hashable & CaseIterable & RawRepresentable>: View where T.AllCases: RandomAccessCollection, T.RawValue == String {
    @Binding var selection: T
    let displayTransform: ((T) -> String)?

    /// Creates a segmented toggle with automatic display from RawValue
    public init(selection: Binding<T>) {
        self._selection = selection
        self.displayTransform = nil
    }

    /// Creates a segmented toggle with custom display transformation
    public init(selection: Binding<T>, displayTransform: @escaping (T) -> String) {
        self._selection = selection
        self.displayTransform = displayTransform
    }

    public var body: some View {
        Picker("", selection: $selection) {
            ForEach(Array(T.allCases), id: \.self) { option in
                Text(displayName(for: option))
                    .tag(option)
            }
        }
        .pickerStyle(.segmented)
    }

    private func displayName(for option: T) -> String {
        if let transform = displayTransform {
            return transform(option)
        }
        // Default: capitalize first letter of raw value
        let raw = option.rawValue
        return raw.prefix(1).uppercased() + raw.dropFirst()
    }
}

// MARK: - Preview

#Preview {
    enum Platform: String, Hashable, CaseIterable {
        case mobile
        case web
        case desktop
    }

    enum Environment: String, Hashable, CaseIterable {
        case staging
        case production
    }

    struct PreviewContainer: View {
        @State private var platform: Platform = .mobile
        @State private var environment: Environment = .staging

        var body: some View {
            VStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Platform: \(platform.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SegmentedToggle(selection: $platform)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Environment: \(environment.rawValue)")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SegmentedToggle(selection: $environment)
                }

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Custom Display Transform:")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    SegmentedToggle(selection: $platform) { option in
                        switch option {
                        case .mobile: return "📱 Mobile"
                        case .web: return "🌐 Web"
                        case .desktop: return "💻 Desktop"
                        }
                    }
                }
            }
            .padding()
            .frame(width: 400)
        }
    }

    return PreviewContainer()
}
