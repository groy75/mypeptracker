import SwiftUI

struct ContentView: View {
    @State private var appState = AppState()

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
    }
}
