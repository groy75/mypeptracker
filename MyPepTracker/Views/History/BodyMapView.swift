import SwiftUI

/// Shows injection-site distribution over the recent dose history. Uses
/// the shared `AthleticSilhouette` — same figure as the Body tab — so
/// the two views feel like the same app, just zoomed differently.
struct BodyMapView: View {
    let recentDoses: [DoseEntry]

    /// Render size for the silhouette in this view. The shared component
    /// scales its reference 320x560 drawing to whatever size is supplied;
    /// we pick a compact size because this view sits inside the History
    /// scroll list alongside the dose rows.
    private static let canvasSize = CGSize(width: 240, height: 420)

    private var siteCounts: [InjectionSite: Int] {
        var counts: [InjectionSite: Int] = [:]
        for dose in recentDoses {
            if let site = dose.injectionSite {
                counts[site, default: 0] += 1
            }
        }
        return counts
    }

    private var voiceOverSummary: String {
        guard !siteCounts.isEmpty else {
            return "No recent injection sites recorded."
        }
        let total = siteCounts.values.reduce(0, +)
        let breakdown = siteCounts
            .sorted { $0.value > $1.value }
            .map { "\($0.key.displayName) \($0.value) time\($0.value == 1 ? "" : "s")" }
            .joined(separator: ", ")
        return "Recent injection sites over the last 30 days. \(total) total doses: \(breakdown)."
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("Recent Injection Sites")
                .font(.headline)
                .padding(.top)

            ZStack {
                AthleticSilhouette()
                ForEach(InjectionSite.allCases.filter { $0 != .other }, id: \.self) { site in
                    if let count = siteCounts[site], count > 0 {
                        // Scale the reference-space site position into the
                        // actual render size.
                        let pos = AthleticSilhouette.scaled(site.silhouettePosition, in: Self.canvasSize)
                        Circle()
                            .fill(AppTheme.primary.opacity(min(1.0, Double(count) * 0.3)))
                            .frame(width: 26, height: 26)
                            .overlay(
                                Text("\(count)")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .position(pos)
                    }
                }
            }
            .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
            .padding()
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Body map")
            .accessibilityValue(voiceOverSummary)

            if !siteCounts.isEmpty {
                HStack(spacing: 16) {
                    ForEach(siteCounts.sorted(by: { $0.value > $1.value }), id: \.key) { site, count in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(AppTheme.primary)
                                .frame(width: 8, height: 8)
                                .accessibilityHidden(true)
                            Text("\(site.displayName): \(count)")
                                .font(.caption2)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
                .padding(.bottom)
            }
        }
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
    }
}
