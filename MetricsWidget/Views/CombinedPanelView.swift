import SwiftUI

struct CombinedPanelView: View {
    var store: MetricsStore
    var usageStore: UsageStore

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

            VStack(alignment: .leading, spacing: 12) {
                AppMemoryPanelView(store: store, embedded: true, rowLimit: 5)
                Divider()
                    .opacity(0.35)
                UsagePanelView(store: usageStore, embedded: true)
            }
            .frame(width: 240, alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.clear)
    }
}
