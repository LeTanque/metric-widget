import SwiftUI

struct CombinedPanelView: View {
    var store: MetricsStore

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                NetworkPanelView(store: store, embedded: true)
                Divider()
                    .opacity(0.35)
                SystemPanelView(store: store, embedded: true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Divider()
                .opacity(0.35)

            AppMemoryPanelView(store: store, embedded: true, rowLimit: 8)
                .frame(width: 220, alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.clear)
    }
}
