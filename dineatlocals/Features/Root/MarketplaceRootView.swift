import SwiftUI

struct MarketplaceRootView: View {
    @Environment(AppModel.self) private var appModel

    var body: some View {
        @Bindable var appModel = appModel

        TabView(selection: $appModel.activeTab) {
            NavigationStack {
                DiscoverView()
            }
            .tabItem {
                Label("Discover", systemImage: "sparkles.rectangle.stack")
            }
            .tag(MarketplaceTab.discover)

            NavigationStack {
                RequestsView()
            }
            .tabItem {
                Label("Requests", systemImage: "tray.full")
            }
            .tag(MarketplaceTab.requests)

            NavigationStack {
                HostingView()
            }
            .tabItem {
                Label("Host", systemImage: "house.lodge")
            }
            .tag(MarketplaceTab.host)

            NavigationStack {
                ProfileView()
            }
            .tabItem {
                Label("Profile", systemImage: "person.crop.circle")
            }
            .tag(MarketplaceTab.profile)
        }
    }
}
