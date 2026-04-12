import SwiftUI

struct DoseEntryRow: View {
    let entry: DoseEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.peptide?.name ?? "Unknown")
                    .font(.body.weight(.medium))
                Spacer()
                Text(entry.timestamp, format: .dateTime.month(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 12) {
                Text("\(Int(entry.doseMcg)) mcg")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                if let site = entry.injectionSite {
                    Label(site.displayName, systemImage: "mappin.circle.fill")
                        .font(.caption)
                        .foregroundStyle(AppTheme.primary)
                }
            }

            if let notes = entry.notes {
                Text(notes)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .italic()
            }
        }
        .padding(.vertical, 4)
    }
}
