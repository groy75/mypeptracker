import SwiftUI

struct BodyMapView: View {
    let recentDoses: [DoseEntry]

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
                bodyOutline

                ForEach(InjectionSite.allCases.filter { $0 != .other }, id: \.self) { site in
                    if let count = siteCounts[site], count > 0 {
                        Circle()
                            .fill(AppTheme.primary.opacity(min(1.0, Double(count) * 0.3)))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(count)")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundStyle(.white)
                            )
                            .position(position(for: site))
                    }
                }
            }
            .frame(width: 200, height: 340)
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

    private var bodyOutline: some View {
        Canvas { context, size in
            let midX = size.width / 2

            let headRect = CGRect(x: midX - 15, y: 10, width: 30, height: 30)
            context.fill(Ellipse().path(in: headRect), with: .color(.gray.opacity(0.15)))

            let torso = Path { p in
                p.move(to: CGPoint(x: midX - 25, y: 45))
                p.addLine(to: CGPoint(x: midX + 25, y: 45))
                p.addLine(to: CGPoint(x: midX + 20, y: 160))
                p.addLine(to: CGPoint(x: midX - 20, y: 160))
                p.closeSubpath()
            }
            context.fill(torso, with: .color(.gray.opacity(0.15)))

            let leftArm = Path { p in
                p.move(to: CGPoint(x: midX - 25, y: 50))
                p.addLine(to: CGPoint(x: midX - 45, y: 55))
                p.addLine(to: CGPoint(x: midX - 50, y: 130))
                p.addLine(to: CGPoint(x: midX - 38, y: 130))
                p.addLine(to: CGPoint(x: midX - 33, y: 60))
                p.closeSubpath()
            }
            context.fill(leftArm, with: .color(.gray.opacity(0.15)))

            let rightArm = Path { p in
                p.move(to: CGPoint(x: midX + 25, y: 50))
                p.addLine(to: CGPoint(x: midX + 45, y: 55))
                p.addLine(to: CGPoint(x: midX + 50, y: 130))
                p.addLine(to: CGPoint(x: midX + 38, y: 130))
                p.addLine(to: CGPoint(x: midX + 33, y: 60))
                p.closeSubpath()
            }
            context.fill(rightArm, with: .color(.gray.opacity(0.15)))

            let leftLeg = Path { p in
                p.move(to: CGPoint(x: midX - 18, y: 160))
                p.addLine(to: CGPoint(x: midX - 22, y: 300))
                p.addLine(to: CGPoint(x: midX - 8, y: 300))
                p.addLine(to: CGPoint(x: midX - 3, y: 160))
                p.closeSubpath()
            }
            context.fill(leftLeg, with: .color(.gray.opacity(0.15)))

            let rightLeg = Path { p in
                p.move(to: CGPoint(x: midX + 18, y: 160))
                p.addLine(to: CGPoint(x: midX + 22, y: 300))
                p.addLine(to: CGPoint(x: midX + 8, y: 300))
                p.addLine(to: CGPoint(x: midX + 3, y: 160))
                p.closeSubpath()
            }
            context.fill(rightLeg, with: .color(.gray.opacity(0.15)))
        }
    }

    private func position(for site: InjectionSite) -> CGPoint {
        let midX: CGFloat = 100
        switch site {
        case .abdomen:       return CGPoint(x: midX, y: 120)
        case .thighLeft:     return CGPoint(x: midX - 12, y: 220)
        case .thighRight:    return CGPoint(x: midX + 12, y: 220)
        case .deltoidLeft:   return CGPoint(x: midX - 42, y: 70)
        case .deltoidRight:  return CGPoint(x: midX + 42, y: 70)
        case .gluteLeft:     return CGPoint(x: midX - 18, y: 165)
        case .gluteRight:    return CGPoint(x: midX + 18, y: 165)
        case .other:         return CGPoint(x: midX, y: 310)
        }
    }
}
