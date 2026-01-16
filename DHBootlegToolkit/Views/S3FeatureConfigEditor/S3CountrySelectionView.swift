import SwiftUI
import DHBootlegToolkitCore

/// Shared country selection view with environment selector
/// Used by both Inspect and Batch Update sheets
struct S3CountrySelectionView: View {
    let title: String
    @Binding var selectedCountries: Set<String>
    @Binding var targetEnvironment: S3Environment
    let availableCountries: [S3CountryConfig]
    let onEnvironmentChange: (S3Environment) async -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Environment selector
            VStack(spacing: 0) {
                S3SheetEnvironmentSelector(
                    selectedEnvironment: $targetEnvironment,
                    onChange: onEnvironmentChange
                )
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 8)

                Divider()
            }
            .background(Color(nsColor: .controlBackgroundColor))

            // Header with Select All / Clear All
            HStack {
                Text(title)
                    .font(.subheadline.bold())

                Spacer()

                Text("\(selectedCountries.count) selected")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Button("Select All") {
                    selectedCountries = Set(availableCountries.map { $0.id })
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("Clear All") {
                    selectedCountries.removeAll()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            // Grouped country list
            List {
                ForEach(groupedAvailableCountries) { group in
                    Section {
                        ForEach(group.countries) { country in
                            S3SelectableCountryRow(
                                country: country,
                                isSelected: selectedCountries.contains(country.id),
                                onToggle: {
                                    if selectedCountries.contains(country.id) {
                                        selectedCountries.remove(country.id)
                                    } else {
                                        selectedCountries.insert(country.id)
                                    }
                                }
                            )
                        }
                    } header: {
                        HStack {
                            // Brand group select all button
                            let groupCountryIds = Set(group.countries.map { $0.id })
                            let allSelected = groupCountryIds.isSubset(of: selectedCountries)

                            Button(action: {
                                if allSelected {
                                    selectedCountries.subtract(groupCountryIds)
                                } else {
                                    selectedCountries.formUnion(groupCountryIds)
                                }
                            }) {
                                Image(systemName: allSelected ? "checkmark.square.fill" : "square")
                                    .font(.caption)
                                    .foregroundStyle(allSelected ? .blue : .secondary)
                            }
                            .buttonStyle(.plain)
                            .help(allSelected ? "Deselect all in \(group.name)" : "Select all in \(group.name)")

                            Text(group.name)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .textCase(nil)

                            Spacer()
                        }
                    }
                }
            }
            .listStyle(.inset)
        }
    }

    // MARK: - Brand Grouping

    /// Grouped countries by brand for selection
    private var groupedAvailableCountries: [BrandGroup] {
        // Single pass grouping
        var foodpandaCountries: [S3CountryConfig] = []
        var foodoraCountries: [S3CountryConfig] = []
        var yemeksepetiCountries: [S3CountryConfig] = []
        var legacyCountries: [S3CountryConfig] = []

        for country in availableCountries {
            switch country.brandName {
            case "foodpanda":
                foodpandaCountries.append(country)
            case "foodora":
                foodoraCountries.append(country)
            case "yemeksepeti":
                yemeksepetiCountries.append(country)
            case nil:
                legacyCountries.append(country)
            default:
                legacyCountries.append(country)
            }
        }

        var groups: [BrandGroup] = []

        if !foodpandaCountries.isEmpty {
            groups.append(BrandGroup(name: "foodpanda", countries: foodpandaCountries))
        }
        if !foodoraCountries.isEmpty {
            groups.append(BrandGroup(name: "foodora", countries: foodoraCountries))
        }
        if !yemeksepetiCountries.isEmpty {
            groups.append(BrandGroup(name: "yemeksepeti", countries: yemeksepetiCountries))
        }
        if !legacyCountries.isEmpty {
            groups.append(BrandGroup(name: "Legacy", countries: legacyCountries))
        }

        return groups
    }

    /// Brand group model
    private struct BrandGroup: Identifiable {
        let id = UUID()
        let name: String
        let countries: [S3CountryConfig]
    }
}
