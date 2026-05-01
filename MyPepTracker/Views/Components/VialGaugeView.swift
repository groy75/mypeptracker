import SwiftUI

struct VialGaugeView: View {
    let fillFraction: Double
    let remainingMcg: Double
    let totalMcg: Double
    let lastDoseMcg: Double?

    private var gaugeColor: Color {
        switch fillFraction {
        case 0.5...: return Color(red: 0.18, green: 0.72, blue: 0.42)
        case 0.25...: return Color(red: 0.97, green: 0.60, blue: 0.08)
        default:      return Color(red: 0.90, green: 0.24, blue: 0.24)
        }
    }

    private var remainingLabel: String {
        let mcg = max(0, remainingMcg)
        if mcg >= 1000 {
            return String(format: "%.1f mg left", mcg / 1000)
        }
        return "\(Int(mcg)) mcg left"
    }

    private var totalLabel: String {
        totalMcg >= 1000
            ? String(format: "%.0f mg", totalMcg / 1000)
            : "\(Int(totalMcg)) mcg"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.15))
                    Capsule()
                        .fill(gaugeColor)
                        .frame(width: geo.size.width * max(0, min(1, fillFraction)))
                        .animation(.spring(duration: 0.45), value: fillFraction)
                }
            }
            .frame(height: 12)

            HStack(alignment: .firstTextBaseline) {
                Text(remainingLabel)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                Text("of \(totalLabel)")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary.opacity(0.6))
                Spacer()
                if let dose = lastDoseMcg {
                    Text("~\(max(0, Int(fillFraction * totalMcg / dose))) doses at \(Int(dose)) mcg")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Text("\(Int(max(0, fillFraction) * 100))%")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(gaugeColor)
            }
        }
    }
}
