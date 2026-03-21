import SwiftData
import SwiftUI

struct ContentView: View {
    @Environment(AppModel.self) private var appModel
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            MarketplaceRootView()

            if appModel.isLoading && appModel.currentUser == nil {
                ProgressView("Loading DineAtLocals")
                    .padding(24)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
        }
        .task {
            await appModel.loadIfNeeded()
            appModel.syncDiscoveryCache(using: modelContext)
        }
        .onChange(of: appModel.experiences) { _, _ in
            appModel.syncDiscoveryCache(using: modelContext)
        }
        .alert("Something went wrong", isPresented: Binding(
            get: { appModel.errorMessage != nil },
            set: { if !$0 { appModel.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {
                appModel.errorMessage = nil
            }
        } message: {
            Text(appModel.errorMessage ?? "")
        }
        .overlay(alignment: .bottom) {
            if let noticeMessage = appModel.noticeMessage {
                NoticeBanner(message: noticeMessage)
                    .padding(.bottom, 12)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appModel.noticeMessage)
    }
}

private struct NoticeBanner: View {
    let message: String

    var body: some View {
        Text(message)
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .foregroundStyle(.white)
            .background(Color.accentColor.gradient, in: Capsule())
            .shadow(radius: 10, y: 4)
    }
}

#Preview {
    ContentView()
        .environment(AppModel.preview())
        .modelContainer(for: CachedExperienceRecord.self, inMemory: true)
}
