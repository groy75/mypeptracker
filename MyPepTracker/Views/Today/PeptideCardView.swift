import SwiftUI

struct PeptideCardView: View {
    let peptide: Peptide
    let onLogDose: () -> Void

    private var nextDoseDate: Date? {
        NotificationManager.nextDoseDate(
            scheduleType: peptide.scheduleType,
            frequency: peptide.frequency,
            lastDoseTimestamp: peptide.lastDose?.timestamp,
            scheduledTime: peptide.scheduledTime,
            scheduleDays: peptide.scheduleDays
        )
    }

    private var isOverdue: Bool {
        guard let next = nextDoseDate else { return false }
        return next < Date()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: AppTheme.paddingSmall) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(peptide.name)
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                    Text("\(Int(peptide.defaultDoseMcg))mcg • \(peptide.scheduleType.displayName)")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button(action: onLogDose) {
                    Text("Log Dose")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 16)
                        .frame(minHeight: 44)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
                .accessibilityLabel("Log dose for \(peptide.name)")
            }

            if let next = nextDoseDate {
                HStack(spacing: 6) {
                    Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "clock.fill")
                        .foregroundStyle(isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                        .font(.caption)
                    Text(isOverdue ? "Overdue" : "Next: \(next, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(isOverdue ? AppTheme.danger : AppTheme.textSecondary)
                }
            }

            if let vial = peptide.activeVial {
                let totalMcg = vial.peptideAmountMg * 1000
                let fill = totalMcg > 0 ? vial.remainingMcg / totalMcg : 0
                VialGaugeView(
                    fillFraction: fill,
                    remainingMcg: vial.remainingMcg,
                    totalMcg: totalMcg,
                    lastDoseMcg: vial.lastDoseMcg ?? peptide.defaultDoseMcg
                )
                HStack(spacing: 4) {
                    Image(systemName: "flask.fill")
                        .font(.caption2)
                    Text("Expires in \(vial.daysUntilExpiry)d")
                        .font(.caption)
                }
                .foregroundStyle(vial.daysUntilExpiry <= 3 ? AppTheme.warning : AppTheme.textSecondary)
            } else {
                Text("No active vial")
                    .font(.caption)
                    .foregroundStyle(AppTheme.warning)
            }
        }
        .padding(AppTheme.paddingMedium)
        .background(AppTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: AppTheme.cornerRadius))
        .shadow(color: .black.opacity(0.06), radius: AppTheme.cardShadowRadius, y: AppTheme.cardShadowY)
    }
}
