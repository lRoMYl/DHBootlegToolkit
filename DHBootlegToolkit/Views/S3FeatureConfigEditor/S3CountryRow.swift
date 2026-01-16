import SwiftUI
import DHBootlegToolkitCore

// MARK: - S3 Country Row

/// Row view for displaying a country in the S3 browser sidebar
struct S3CountryRow: View {
    @Environment(S3Store.self) private var store
    let country: S3CountryConfig

    @State private var isHovering = false

    private var isSelected: Bool {
        store.selectedCountry?.id == country.id
    }

    var body: some View {
        HStack(spacing: 8) {
            // Flag emoji (instead of generic icon)
            Text(country.flagEmoji)
                .font(.title2)

            // Country info
            VStack(alignment: .leading, spacing: 2) {
                // Primary: Country name
                Text(country.countryName)
                    .font(.body)
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                // Secondary: GEID + Brand
                HStack(spacing: 4) {
                    if let geid = country.geid {
                        Text(geid)
                            .font(.caption2.monospaced())
                            .foregroundStyle(.secondary)
                    }

                    if let brand = country.brandName {
                        Text("•")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        Text(brand)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                // Deprecated badge (if applicable)
                if let deprecatedInfo = country.deprecatedInfo {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption2)
                            .foregroundStyle(.orange)

                        Text(deprecatedBadgeText(deprecatedInfo))
                            .font(.caption2)
                            .foregroundStyle(.orange)
                    }
                    .padding(.top, 2)
                }
            }

            Spacer()

            // Discard button (show on hover when file has git changes)
            if country.gitStatus == .modified {
                Button {
                    Task {
                        await store.discardChanges(for: country.id)
                    }
                } label: {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.body)
                }
                .buttonStyle(.plain)
                .opacity(isHovering ? 1 : 0)
                .help("Discard changes")
            }

            // Git status badge
            switch country.gitStatus {
            case .added:
                StatusLetterBadge(letter: "A", color: .green)
            case .modified:
                StatusLetterBadge(letter: "M", color: .blue)
            case .deleted:
                StatusLetterBadge(letter: "D", color: .red)
            case .unchanged:
                EmptyView()
            }
        }
        .contentShape(Rectangle())
        .onHover { isHovering = $0 }
    }

    /// Generate deprecated badge text
    private func deprecatedBadgeText(_ info: S3CountryConfig.DeprecatedInfo) -> String {
        let oldGEIDsText = info.oldGEIDs.joined(separator: ", ")

        switch info.status {
        case .deprecated:
            if let replacement = info.replacementGEID {
                return "Deprecated: \(oldGEIDsText) → \(replacement)"
            }
            return "Deprecated: \(oldGEIDsText)"
        case .closed:
            return "Closed: \(oldGEIDsText)"
        case .migrated:
            // Show notes for migrated entries (e.g., "Migrated to Glovo")
            if let notes = info.notes {
                return notes
            }
            return "Migrated: \(oldGEIDsText)"
        case .active:
            return ""
        }
    }
}

#Preview {
    List {
        S3CountryRow(country: S3CountryConfig(
            countryCode: "sg",
            configURL: URL(fileURLWithPath: "/tmp/sg/config.json"),
            gitStatus: .unchanged
        ))

        S3CountryRow(country: S3CountryConfig(
            countryCode: "my",
            configURL: URL(fileURLWithPath: "/tmp/my/config.json"),
            gitStatus: .modified
        ))

        S3CountryRow(country: S3CountryConfig(
            countryCode: "th",
            configURL: URL(fileURLWithPath: "/tmp/th/config.json"),
            gitStatus: .added
        ))
    }
    .listStyle(.sidebar)
    .environment(S3Store())
    .frame(width: 280, height: 200)
}
