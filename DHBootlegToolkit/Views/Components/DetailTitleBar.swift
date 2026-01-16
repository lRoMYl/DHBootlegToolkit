import SwiftUI

struct DetailTitleBar: View {
    let title: String

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.bar)
    }
}

#Preview {
    VStack(spacing: 0) {
        DetailTitleBar(title: "Localization Editor")
        Divider()
        Spacer()
    }
    .frame(width: 400, height: 300)
}
