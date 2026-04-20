import SwiftUI
import SwiftData

/// Alternative Body-tab layout: renders a front-facing human silhouette
/// with an interactive marker per anatomical metric. Weight and body-fat
/// live as pills above the silhouette since they don't map to a single
/// anatomical point.
///
/// Markers navigate via the parent's NavigationStack into MetricDetailView.
struct BodySilhouetteView: View {
    @Query(sort: \BodyMeasurement.timestamp, order: .reverse) private var allMeasurements: [BodyMeasurement]
    @Query private var allGoals: [BodyMetricGoal]

    private static let canvasSize = CGSize(width: 240, height: 400)

    private var latestByMetric: [BodyMetric: BodyMeasurement] {
        var out: [BodyMetric: BodyMeasurement] = [:]
        for entry in allMeasurements where out[entry.metric] == nil {
            out[entry.metric] = entry
        }
        return out
    }

    private func goal(for metric: BodyMetric) -> BodyMetricGoal? {
        allGoals.first { $0.metric == metric }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Pills for non-anatomical metrics (weight, body fat).
                HStack(spacing: 12) {
                    summaryPill(.weight)
                    summaryPill(.bodyFatPercent)
                }
                .padding(.horizontal)

                // The silhouette + markers.
                ZStack {
                    silhouetteOutline
                    ForEach(BodyMetric.allCases.filter { $0.bodyPosition != nil }, id: \.self) { metric in
                        marker(for: metric)
                    }
                }
                .frame(width: Self.canvasSize.width, height: Self.canvasSize.height)
                .padding(.horizontal)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Body silhouette with measurement markers")
            }
            .padding(.vertical)
        }
    }

    // MARK: - Pills (weight, body fat)

    @ViewBuilder
    private func summaryPill(_ metric: BodyMetric) -> some View {
        let imperial = BodyMetricUnitPreference.preferImperial(for: metric)
        let latest = latestByMetric[metric]
        NavigationLink {
            MetricDetailView(metric: metric)
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: metric.symbol)
                        .font(.caption)
                    Text(metric.displayName)
                        .font(.caption.weight(.semibold))
                }
                .foregroundStyle(AppTheme.textSecondary)
                if let latest {
                    Text(BodyMetricFormat.formatted(latest.value, unit: metric.unit, imperial: imperial))
                        .font(.title3.monospacedDigit())
                        .foregroundStyle(AppTheme.textPrimary)
                } else {
                    Text("Tap to record")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(AppTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Markers on the silhouette

    @ViewBuilder
    private func marker(for metric: BodyMetric) -> some View {
        if let position = metric.bodyPosition {
            let imperial = BodyMetricUnitPreference.preferImperial(for: metric)
            let latest = latestByMetric[metric]
            let g = goal(for: metric)
            let isGoalComplete = g.flatMap { goal in
                latest.map { goal.isComplete(currentValue: $0.value) }
            } ?? false

            let fillColor: Color = {
                if isGoalComplete { return AppTheme.success }
                if latest != nil { return AppTheme.primary }
                return Color.gray.opacity(0.4)
            }()

            NavigationLink {
                MetricDetailView(metric: metric)
            } label: {
                VStack(spacing: 2) {
                    ZStack {
                        Circle()
                            .fill(fillColor)
                            .frame(width: 30, height: 30)
                            .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        Image(systemName: metric.symbol)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                    if let latest {
                        Text(BodyMetricFormat.formatted(latest.value, unit: metric.unit, imperial: imperial))
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(AppTheme.surface)
                            .clipShape(Capsule())
                    }
                }
            }
            .buttonStyle(.plain)
            .position(position)
            .accessibilityLabel(accessibilityLabel(for: metric, latest: latest, imperial: imperial))
        }
    }

    private func accessibilityLabel(for metric: BodyMetric, latest: BodyMeasurement?, imperial: Bool) -> String {
        guard let latest else { return "\(metric.displayName): not recorded yet. Double tap to log." }
        let value = BodyMetricFormat.formatted(latest.value, unit: metric.unit, imperial: imperial)
        return "\(metric.displayName): \(value). Double tap to open."
    }

    // MARK: - Silhouette outline
    //
    // Adapted from the smaller BodyMapView used for injection sites. Drawn
    // here at 240x400 with slightly softer proportions. Pure Canvas — no
    // image assets.

    private var silhouetteOutline: some View {
        Canvas { context, _ in
            let midX: CGFloat = 120
            let fill = GraphicsContext.Shading.color(Color.gray.opacity(0.18))

            // Head.
            let headRect = CGRect(x: midX - 26, y: 14, width: 52, height: 52)
            context.fill(Path(ellipseIn: headRect), with: fill)

            // Neck.
            let neck = Path { p in
                p.move(to: CGPoint(x: midX - 10, y: 60))
                p.addLine(to: CGPoint(x: midX + 10, y: 60))
                p.addLine(to: CGPoint(x: midX + 10, y: 76))
                p.addLine(to: CGPoint(x: midX - 10, y: 76))
                p.closeSubpath()
            }
            context.fill(neck, with: fill)

            // Torso (shoulders → waist → pelvis), slightly hourglass.
            let torso = Path { p in
                p.move(to: CGPoint(x: midX - 45, y: 76))   // left shoulder
                p.addLine(to: CGPoint(x: midX + 45, y: 76)) // right shoulder
                p.addLine(to: CGPoint(x: midX + 38, y: 170)) // right waist
                p.addLine(to: CGPoint(x: midX + 42, y: 240)) // right hip
                p.addLine(to: CGPoint(x: midX - 42, y: 240)) // left hip
                p.addLine(to: CGPoint(x: midX - 38, y: 170)) // left waist
                p.closeSubpath()
            }
            context.fill(torso, with: fill)

            // Left arm.
            let leftArm = Path { p in
                p.move(to: CGPoint(x: midX - 45, y: 80))
                p.addLine(to: CGPoint(x: midX - 62, y: 90))
                p.addLine(to: CGPoint(x: midX - 72, y: 200))
                p.addLine(to: CGPoint(x: midX - 58, y: 205))
                p.addLine(to: CGPoint(x: midX - 52, y: 100))
                p.closeSubpath()
            }
            context.fill(leftArm, with: fill)

            // Right arm (mirrored).
            let rightArm = Path { p in
                p.move(to: CGPoint(x: midX + 45, y: 80))
                p.addLine(to: CGPoint(x: midX + 62, y: 90))
                p.addLine(to: CGPoint(x: midX + 72, y: 200))
                p.addLine(to: CGPoint(x: midX + 58, y: 205))
                p.addLine(to: CGPoint(x: midX + 52, y: 100))
                p.closeSubpath()
            }
            context.fill(rightArm, with: fill)

            // Left leg.
            let leftLeg = Path { p in
                p.move(to: CGPoint(x: midX - 42, y: 240))
                p.addLine(to: CGPoint(x: midX - 4, y: 240))
                p.addLine(to: CGPoint(x: midX - 10, y: 385))
                p.addLine(to: CGPoint(x: midX - 36, y: 385))
                p.closeSubpath()
            }
            context.fill(leftLeg, with: fill)

            // Right leg.
            let rightLeg = Path { p in
                p.move(to: CGPoint(x: midX + 4, y: 240))
                p.addLine(to: CGPoint(x: midX + 42, y: 240))
                p.addLine(to: CGPoint(x: midX + 36, y: 385))
                p.addLine(to: CGPoint(x: midX + 10, y: 385))
                p.closeSubpath()
            }
            context.fill(rightLeg, with: fill)
        }
    }
}
