import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "pill.fill")
                }

            PeptideListView()
                .tabItem {
                    Label("Peptides", systemImage: "cube.box.fill")
                }

            HistoryView()
                .tabItem {
                    Label("History", systemImage: "list.clipboard.fill")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(AppTheme.primary)
    }
}
