import SwiftUI

struct AboutView: View {
    private let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    private let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"

    var body: some View {
        List {
            // App header
            Section {
                VStack(spacing: 8) {
                    Image(systemName: "cross.vial.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppTheme.primary)
                    Text("MyPepTracker")
                        .font(.title2.weight(.semibold))
                    Text("Version \(appVersion) (\(buildNumber))")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .listRowBackground(Color.clear)
            }

            // Feedback
            Section("Feedback") {
                Link(destination: URL(string: "mailto:greg.roy@metricaid.com?subject=MyPepTracker%20Feedback")!) {
                    Label("Email the Developer", systemImage: "envelope.fill")
                }
            }

            // Changelog
            Section("Changelog") {
                ChangelogEntry(
                    version: "1.0.0",
                    date: "April 12, 2026",
                    changes: [
                        "Initial release",
                        "Track 3-5 peptides with mixed schedules",
                        "Reconstitution logging with auto-calculated concentration",
                        "Dose logging with injection site tracking and notes",
                        "Backdate doses for past entries",
                        "Push notification reminders (dose, overdue, vial expiry, low vial)",
                        "Flexible scheduling: twice daily through monthly",
                        "Cycle tracking with progress and days remaining",
                        "28 peptide presets across 10 categories",
                        "Injection site body map visualization",
                        "Data export (JSON / CSV)",
                        "Dose stepper widget with selectable step sizes",
                    ]
                )
            }

            // License
            Section("License") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("MIT License")
                        .font(.subheadline.weight(.semibold))
                    Text("Copyright (c) 2026 Greg Roy")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files, to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, subject to the following conditions:")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                    Text("THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED.")
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(.vertical, 4)
            }

            // Disclaimer
            Section("Disclaimer") {
                Text("MyPepTracker is a personal tracking tool only. It does not provide medical advice. Always consult a qualified healthcare provider before starting, stopping, or modifying any peptide protocol.")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
        .navigationTitle("About")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChangelogEntry: View {
    let version: String
    let date: String
    let changes: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("v\(version)")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text(date)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
            ForEach(changes, id: \.self) { change in
                HStack(alignment: .top, spacing: 8) {
                    Text("•")
                        .foregroundStyle(AppTheme.primary)
                    Text(change)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
