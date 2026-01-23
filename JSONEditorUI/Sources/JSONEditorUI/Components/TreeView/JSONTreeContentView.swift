import SwiftUI

// MARK: - JSON Tree Content View

/// Generic virtualized tree content view for JSON editing
/// This is a protocol-based approach where the consumer provides the row view
public struct JSONTreeContentView<NodeType: Identifiable, RowView: View>: View {
    let nodes: [NodeType]
    let searchMatches: JSONSearchMatches
    let pathsToExpand: ([String]?) -> Set<String>
    @Binding var scrollProxy: ScrollViewProxy?
    let rowBuilder: (NodeType) -> RowView

    public init(
        nodes: [NodeType],
        searchMatches: JSONSearchMatches,
        pathsToExpand: @escaping ([String]?) -> Set<String>,
        scrollProxy: Binding<ScrollViewProxy?>,
        @ViewBuilder rowBuilder: @escaping (NodeType) -> RowView
    ) {
        self.nodes = nodes
        self.searchMatches = searchMatches
        self.pathsToExpand = pathsToExpand
        self._scrollProxy = scrollProxy
        self.rowBuilder = rowBuilder
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(nodes) { node in
                        rowBuilder(node)
                    }
                }
                .padding()
            }
            .onAppear {
                scrollProxy = proxy
            }
            .onChange(of: searchMatches.currentPath) { _, newPath in
                if let path = newPath {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        proxy.scrollTo(path.joined(separator: "."), anchor: .center)
                    }
                }
            }
        }
    }
}
