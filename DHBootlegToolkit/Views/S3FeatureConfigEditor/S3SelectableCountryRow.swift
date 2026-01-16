import SwiftUI
import DHBootlegToolkitCore

// MARK: - S3 Selectable Country Row

/// Selectable country row with checkbox - used in Inspect and Apply modals
struct S3SelectableCountryRow: View {
    let country: S3CountryConfig
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .font(.title3)
                .foregroundStyle(isSelected ? .blue : .secondary)

            // Flag emoji
            Text(country.flagEmoji)
                .font(.title2)

            // Country info
            VStack(alignment: .leading, spacing: 2) {
                // Primary: Country name
                Text(country.countryName)
                    .font(.body)
                    .foregroundStyle(.primary)

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
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onToggle()
        }
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
        S3SelectableCountryRow(
            country: S3CountryConfig(
                countryCode: "sg",
                configURL: URL(fileURLWithPath: "/tmp/sg/config.json"),
                gitStatus: .unchanged
            ),
            isSelected: false,
            onToggle: {}
        )

        S3SelectableCountryRow(
            country: S3CountryConfig(
                countryCode: "my",
                configURL: URL(fileURLWithPath: "/tmp/my/config.json"),
                gitStatus: .modified
            ),
            isSelected: true,
            onToggle: {}
        )
    }
    .listStyle(.inset)
}
