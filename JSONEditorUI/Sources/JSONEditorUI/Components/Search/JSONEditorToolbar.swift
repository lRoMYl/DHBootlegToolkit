import SwiftUI

// MARK: - JSON Editor Toolbar

/// Complete toolbar for JSON editor with search, expand/collapse, and filter controls
public struct JSONEditorToolbar: View {
  // MARK: - Search Parameters (pass-through to JSONSearchBar)
  @Binding var searchQuery: String
  @Binding var exactMatch: Bool
  @Binding var caseSensitive: Bool
  let currentMatch: Int
  let totalMatches: Int
  let onSearchNext: () -> Void
  let onSearchPrevious: () -> Void
  let focusCoordinator: FieldFocusCoordinator

  // MARK: - Tree Control Parameters
  let expandCollapseConfig: ExpandCollapseConfig?
  let filterConfig: FilterConfig?

  public init(
    searchQuery: Binding<String>,
    exactMatch: Binding<Bool>,
    caseSensitive: Binding<Bool>,
    currentMatch: Int,
    totalMatches: Int,
    onSearchNext: @escaping () -> Void,
    onSearchPrevious: @escaping () -> Void,
    focusCoordinator: FieldFocusCoordinator,
    expandCollapseConfig: ExpandCollapseConfig? = nil,
    filterConfig: FilterConfig? = nil
  ) {
    self._searchQuery = searchQuery
    self._exactMatch = exactMatch
    self._caseSensitive = caseSensitive
    self.currentMatch = currentMatch
    self.totalMatches = totalMatches
    self.onSearchNext = onSearchNext
    self.onSearchPrevious = onSearchPrevious
    self.focusCoordinator = focusCoordinator
    self.expandCollapseConfig = expandCollapseConfig
    self.filterConfig = filterConfig
  }

  public var body: some View {
    ControlBar {
      JSONSearchBar(
        searchQuery: $searchQuery,
        exactMatch: $exactMatch,
        caseSensitive: $caseSensitive,
        currentMatch: currentMatch,
        totalMatches: totalMatches,
        onNext: onSearchNext,
        onPrevious: onSearchPrevious,
        focusCoordinator: focusCoordinator
      )

      if expandCollapseConfig != nil || filterConfig != nil {
        Divider()
          .frame(height: 20)
      }

      if let config = expandCollapseConfig {
        expandCollapseButton(config)
      }

      if let config = filterConfig {
        filterButton(config)
      }
    }
  }

  // MARK: - Private Buttons

  private func expandCollapseButton(_ config: ExpandCollapseConfig) -> some View {
    Button {
      config.onToggle()
    } label: {
      Image(systemName: config.isExpanded ? "chevron.down.square" : "chevron.right.square")
        .imageScale(.small)
        .frame(width: 12, height: 12)
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .help(config.isExpanded ? "Collapse All" : "Expand All")
  }

  private func filterButton(_ config: FilterConfig) -> some View {
    Button {
      config.onToggle()
    } label: {
      HStack(spacing: 4) {
        Image(systemName: "line.3.horizontal.decrease.circle")
          .imageScale(.small)
          .frame(width: 12, height: 12)

        if config.isActive, let count = config.count, count > 0 {
          Text("\(count)")
            .font(.caption2.weight(.medium).monospacedDigit())
        }
      }
    }
    .buttonStyle(.bordered)
    .controlSize(.small)
    .tint(config.isActive ? .blue : .primary)
    .background(config.isActive ? Color.accentColor.opacity(0.15) : Color.clear)
    .cornerRadius(4)
    .disabled(config.isDisabled)
    .help(config.isActive ? "Show All Fields" : "Show Changed Fields Only")
  }
}

// MARK: - Configuration Types

public struct ExpandCollapseConfig {
  public let isExpanded: Bool
  public let onToggle: () -> Void

  public init(isExpanded: Bool, onToggle: @escaping () -> Void) {
    self.isExpanded = isExpanded
    self.onToggle = onToggle
  }
}

public struct FilterConfig {
  public let isActive: Bool
  public let isDisabled: Bool
  public let count: Int?
  public let onToggle: () -> Void

  public init(
    isActive: Bool,
    isDisabled: Bool = false,
    count: Int? = nil,
    onToggle: @escaping () -> Void
  ) {
    self.isActive = isActive
    self.isDisabled = isDisabled
    self.count = count
    self.onToggle = onToggle
  }
}
