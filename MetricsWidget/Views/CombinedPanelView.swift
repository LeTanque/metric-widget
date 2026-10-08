import SwiftUI

struct CombinedPanelView: View {
    var store: MetricsStore
    var usageStore: UsageStore

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                NetworkPanelView(store: store, embedded: true)
                Rectangle()
                    .fill(ArcadeTileChrome.grid)
                    .frame(height: 1)
                SystemPanelView(store: store, embedded: true)
            }
            .frame(maxWidth: .infinity, alignment: .topLeading)

            Rectangle()
                .fill(ArcadeTileChrome.grid)
                .frame(width: 1)

            VStack(alignment: .leading, spacing: 12) {
                AppMemoryPanelView(store: store, embedded: true, rowLimit: 5)
                Rectangle()
                    .fill(ArcadeTileChrome.grid)
                    .frame(height: 1)
                UsagePanelView(store: usageStore, embedded: true)
            }
            .frame(width: 268, alignment: .topLeading)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.clear)
        .onAppear {
            ArcadeFont.register()
        }
    }
}
