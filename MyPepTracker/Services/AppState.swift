import Foundation
import SwiftUI

enum AppTab: Hashable {
    case today, peptides, history, settings
}

@Observable
@MainActor
final class AppState {
    var selectedTab: AppTab = .today
    var toastMessage: String?

    func showToast(_ message: String) {
        toastMessage = message
        let captured = message
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(2))
            if self.toastMessage == captured {
                self.toastMessage = nil
            }
        }
    }
}
