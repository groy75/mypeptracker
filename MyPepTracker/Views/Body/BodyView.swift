import SwiftUI
import SwiftData

/// Body tab entry point. Renders the silhouette view with interactive
/// markers. The old "List" layout was removed in 1.8.0 — the silhouette
/// is the only Body layout.
struct BodyView: View {
    var body: some View {
        NavigationStack {
            BodySilhouetteView()
                .navigationTitle("Body")
        }
    }
}
