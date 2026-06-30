import SwiftUI

struct MarketplaceRootView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        @Bindable var appModel = appModel

        if horizontalSizeClass == .regular {
            regularWidthRoot(activeTab: $appModel.activeTab)
        } else {
            compactRoot(activeTab: $appModel.activeTab)
        }
    }

    private func compactRoot(activeTab: Binding<MarketplaceTab>) -> some View {
        TabView(selection: activeTab) {
            NavigationStack {
                tabContent(.discover)
            }
            .tabItem {
                Label(MarketplaceTab.discover.title, systemImage: MarketplaceTab.discover.systemImageName)
            }
            .tag(MarketplaceTab.discover)

            NavigationStack {
                tabContent(.requests)
            }
            .tabItem {
                Label(MarketplaceTab.requests.title, systemImage: MarketplaceTab.requests.systemImageName)
            }
            .tag(MarketplaceTab.requests)

            NavigationStack {
                tabContent(.host)
            }
            .tabItem {
                Label(MarketplaceTab.host.title, systemImage: MarketplaceTab.host.systemImageName)
            }
            .tag(MarketplaceTab.host)

            NavigationStack {
                tabContent(.profile)
            }
            .tabItem {
                Label(MarketplaceTab.profile.title, systemImage: MarketplaceTab.profile.systemImageName)
            }
            .tag(MarketplaceTab.profile)
        }
    }

    private func regularWidthRoot(activeTab: Binding<MarketplaceTab>) -> some View {
        NavigationSplitView {
            List {
                Section {
                    ForEach(MarketplaceTab.allCases) { tab in
                        Button {
                            activeTab.wrappedValue = tab
                        } label: {
                            Label(tab.title, systemImage: tab.systemImageName)
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(tab == activeTab.wrappedValue ? SupperClubPalette.oxblood : SupperClubPalette.ink)
                        .listRowBackground(tab == activeTab.wrappedValue ? SupperClubPalette.blush.opacity(0.45) : Color.clear)
                        .accessibilityIdentifier("root.sidebar.\(tab.rawValue)")
                    }
                } header: {
                    Text("DineAtLocals")
                        .font(.system(.headline, design: .serif))
                        .foregroundStyle(SupperClubPalette.ink)
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("DineAtLocals")
        } detail: {
            NavigationStack {
                tabContent(activeTab.wrappedValue)
            }
            .id(activeTab.wrappedValue)
        }
        .navigationSplitViewStyle(.balanced)
    }

    @ViewBuilder
    private func tabContent(_ tab: MarketplaceTab) -> some View {
        switch tab {
        case .discover:
            DiscoverView()
        case .requests:
            RequestsView()
        case .host:
            HostingView()
        case .profile:
            ProfileView()
        }
    }
}
