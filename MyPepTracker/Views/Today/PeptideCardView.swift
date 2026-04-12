import SwiftUI

struct PeptideCardView: View {
    let peptide: Peptide
    let onLogDose: () -> Void

    private var nextDoseDate: Date? {
        NotificationManager.nextDoseDate(
            scheduleType: peptide.scheduleType,
            frequencyHours: peptide.frequencyHours,
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
                        .padding(.vertical, 8)
                        .background(AppTheme.primary)
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
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
                HStack(spacing: 12) {
                    Label(
                        "\(vial.daysUntilExpiry)d left",
                        systemImage: "flask.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(vial.daysUntilExpiry <= 3 ? AppTheme.warning : AppTheme.textSecondary)

                    let remaining = vial.estimatedRemainingDoses(forDoseMcg: peptide.defaultDoseMcg)
                    Label(
                        "~\(remaining) doses",
                        systemImage: "syringe.fill"
                    )
                    .font(.caption)
                    .foregroundStyle(remaining <= 2 ? AppTheme.warning : AppTheme.textSecondary)
                }
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
