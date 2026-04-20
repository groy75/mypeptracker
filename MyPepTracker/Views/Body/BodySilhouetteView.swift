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

    private static let canvasSize = CGSize(width: 320, height: 560)

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

    /// Stylized muscular front-facing silhouette. Built from a handful of
    /// overlapping filled shapes rather than one precise outline — easier
    /// to tune visually and reads clearly as a V-tapered torso with wide
    /// shoulders, round pecs/delts, narrow waist, flared hips, and tapered
    /// quads/calves.
    ///
    /// Canvas is 320x560. All coordinates are absolute so marker positions
    /// in `BodyMetric.bodyPosition` read as pixels.
    private var silhouetteOutline: some View {
        Canvas { context, _ in
            let fill = GraphicsContext.Shading.color(Color.gray.opacity(0.22))

            // MARK: Head (oval, slightly taller than wide)
            let headRect = CGRect(x: 130, y: 14, width: 60, height: 70)
            context.fill(Path(ellipseIn: headRect), with: fill)

            // MARK: Neck (short tapered trapezoid)
            let neck = Path { p in
                p.move(to: CGPoint(x: 146, y: 80))
                p.addLine(to: CGPoint(x: 174, y: 80))
                p.addLine(to: CGPoint(x: 180, y: 112))
                p.addLine(to: CGPoint(x: 140, y: 112))
                p.closeSubpath()
            }
            context.fill(neck, with: fill)

            // MARK: Shoulders / deltoids — wide rounded cap across the top.
            // Drawn as two overlapping ellipses to give a muscular delt shape.
            let leftDelt = CGRect(x: 52, y: 108, width: 88, height: 70)
            let rightDelt = CGRect(x: 180, y: 108, width: 88, height: 70)
            context.fill(Path(ellipseIn: leftDelt), with: fill)
            context.fill(Path(ellipseIn: rightDelt), with: fill)

            // MARK: Chest / torso — a V-tapered trapezoid with rounded corners.
            let torso = Path(roundedRect: CGRect(x: 88, y: 130, width: 144, height: 130), cornerRadius: 20)
            context.fill(torso, with: fill)

            // MARK: Waist — narrower block blending torso to hips.
            let waist = Path(roundedRect: CGRect(x: 104, y: 250, width: 112, height: 70), cornerRadius: 16)
            context.fill(waist, with: fill)

            // MARK: Hips / pelvis — flares back out.
            let hips = Path(roundedRect: CGRect(x: 92, y: 300, width: 136, height: 62), cornerRadius: 22)
            context.fill(hips, with: fill)

            // MARK: Upper arms — tapered capsules from delt down past the waist.
            // Angled slightly outward at the bottom for a relaxed stance.
            let leftUpperArm = Path { p in
                p.move(to: CGPoint(x: 58, y: 145))   // outer shoulder
                p.addLine(to: CGPoint(x: 92, y: 155)) // inner shoulder (tucks under delt)
                p.addLine(to: CGPoint(x: 84, y: 290)) // inner elbow
                p.addLine(to: CGPoint(x: 46, y: 280)) // outer elbow
                p.closeSubpath()
            }
            context.fill(leftUpperArm, with: fill)

            let rightUpperArm = Path { p in
                p.move(to: CGPoint(x: 262, y: 145))
                p.addLine(to: CGPoint(x: 228, y: 155))
                p.addLine(to: CGPoint(x: 236, y: 290))
                p.addLine(to: CGPoint(x: 274, y: 280))
                p.closeSubpath()
            }
            context.fill(rightUpperArm, with: fill)

            // MARK: Forearms — narrower, down to the wrist.
            let leftForearm = Path { p in
                p.move(to: CGPoint(x: 46, y: 280))
                p.addLine(to: CGPoint(x: 84, y: 290))
                p.addLine(to: CGPoint(x: 76, y: 380))
                p.addLine(to: CGPoint(x: 44, y: 380))
                p.closeSubpath()
            }
            context.fill(leftForearm, with: fill)

            let rightForearm = Path { p in
                p.move(to: CGPoint(x: 274, y: 280))
                p.addLine(to: CGPoint(x: 236, y: 290))
                p.addLine(to: CGPoint(x: 244, y: 380))
                p.addLine(to: CGPoint(x: 276, y: 380))
                p.closeSubpath()
            }
            context.fill(rightForearm, with: fill)

            // MARK: Left thigh — wide at hip, tapered to knee.
            let leftThigh = Path { p in
                p.move(to: CGPoint(x: 96, y: 358))
                p.addLine(to: CGPoint(x: 156, y: 358))
                p.addLine(to: CGPoint(x: 150, y: 470))
                p.addLine(to: CGPoint(x: 108, y: 470))
                p.closeSubpath()
            }
            context.fill(leftThigh, with: fill)

            // MARK: Right thigh (mirror).
            let rightThigh = Path { p in
                p.move(to: CGPoint(x: 164, y: 358))
                p.addLine(to: CGPoint(x: 224, y: 358))
                p.addLine(to: CGPoint(x: 212, y: 470))
                p.addLine(to: CGPoint(x: 170, y: 470))
                p.closeSubpath()
            }
            context.fill(rightThigh, with: fill)

            // MARK: Calves — narrower than thighs, down to ankles.
            let leftCalf = Path { p in
                p.move(to: CGPoint(x: 110, y: 470))
                p.addLine(to: CGPoint(x: 148, y: 470))
                p.addLine(to: CGPoint(x: 142, y: 548))
                p.addLine(to: CGPoint(x: 116, y: 548))
                p.closeSubpath()
            }
            context.fill(leftCalf, with: fill)

            let rightCalf = Path { p in
                p.move(to: CGPoint(x: 172, y: 470))
                p.addLine(to: CGPoint(x: 210, y: 470))
                p.addLine(to: CGPoint(x: 204, y: 548))
                p.addLine(to: CGPoint(x: 178, y: 548))
                p.closeSubpath()
            }
            context.fill(rightCalf, with: fill)
        }
    }
}
