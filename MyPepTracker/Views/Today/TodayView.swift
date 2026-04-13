import SwiftUI
import SwiftData

struct TodayView: View {
    @Query(filter: #Predicate<Peptide> { $0.isActive }, sort: \Peptide.name)
    private var activePeptides: [Peptide]

    @State private var peptideToLog: Peptide?

    var body: some View {
        NavigationStack {
            ScrollView {
                if activePeptides.isEmpty {
                    ContentUnavailableView(
                        "No Active Peptides",
                        systemImage: "pill.fill",
                        description: Text("Add a peptide from the Peptides tab to get started.")
                    )
                } else {
                    LazyVStack(spacing: AppTheme.paddingSmall) {
                        ForEach(activePeptides) { peptide in
                            PeptideCardView(peptide: peptide) {
                                peptideToLog = peptide
                            }
                        }
                    }
                    .padding(.horizontal, AppTheme.paddingMedium)
                    .padding(.top, AppTheme.paddingSmall)
                }
            }
            .background(AppTheme.background)
            .navigationTitle("Today")
            .fullScreenCover(item: $peptideToLog) { peptide in
                LogDoseSheet(peptide: peptide)
            }
        }
    }
}
