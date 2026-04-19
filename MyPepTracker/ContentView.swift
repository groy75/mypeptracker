import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()
    @AppStorage("lastSeenChangelogBuild") private var lastSeenChangelogBuild = 0
    @State private var showWhatsNew = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $appState.selectedTab) {
                TodayView()
                    .tag(AppTab.today)
                    .tabItem {
                        Label("Today", systemImage: "pill.fill")
                    }

                PeptideListView()
                    .tag(AppTab.peptides)
                    .tabItem {
                        Label("Peptides", systemImage: "cube.box.fill")
                    }

                HistoryView()
                    .tag(AppTab.history)
                    .tabItem {
                        Label("History", systemImage: "list.clipboard.fill")
                    }

                BodyView()
                    .tag(AppTab.body)
                    .tabItem {
                        Label("Body", systemImage: "figure.arms.open")
                    }

                SettingsView()
                    .tag(AppTab.settings)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape.fill")
                    }
            }
            .tint(AppTheme.primary)

            if let message = appState.toastMessage {
                ToastView(message: message)
                    .padding(.bottom, 80)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .zIndex(1)
            }
        }
        .animation(.spring(response: 0.35, dampingFraction: 0.85), value: appState.toastMessage)
        .environment(appState)
        .onAppear(perform: presentWhatsNewIfNeeded)
        .sheet(isPresented: $showWhatsNew) {
            NavigationStack {
                ChangelogView()
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showWhatsNew = false }
                        }
                    }
            }
            .presentationDetents([.large])
        }
    }

    private func presentWhatsNewIfNeeded() {
        let current = Changelog.currentBuild
        // Only show on a genuine upgrade: lastSeen must be non-zero (prior install)
        // AND strictly less than the running build. Fresh installs don't count.
        if lastSeenChangelogBuild > 0, current > lastSeenChangelogBuild {
            showWhatsNew = true
        }
        lastSeenChangelogBuild = current
    }
}
