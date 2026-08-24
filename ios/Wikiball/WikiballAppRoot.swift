import SwiftUI

/// Final application router for the design-system branch.
/// Non-round navigation is handled by the new four-tab experience shell; active rounds use
/// the branded Club Journey/result implementation rather than the legacy ContentView.
struct WBApplicationRoot: View {
    @EnvironmentObject private var store: GameStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        Group {
            if store.round == nil {
                WikiballExperienceRoot()
            } else {
                WBGameplayView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { store.syncBackgroundMusic() }
        .onChange(of: store.round != nil) { _, _ in store.syncBackgroundMusic() }
        .onChange(of: scenePhase) { _, phase in store.setAppActive(phase == .active) }
    }
}
