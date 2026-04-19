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

            // Feedback & Links
            Section("Feedback & Support") {
                Link(destination: URL(string: "mailto:greg@gregsplace.cc?subject=MyPepTracker%20Feedback")!) {
                    Label("Email the Developer", systemImage: "envelope.fill")
                }
                NavigationLink {
                    ChangelogView()
                } label: {
                    Label("What's New", systemImage: "sparkles")
                }
                Link(destination: URL(string: "https://mypeptracker.gregsplace.cc/privacy")!) {
                    Label("Privacy Policy", systemImage: "hand.raised.fill")
                }
                Link(destination: URL(string: "https://mypeptracker.gregsplace.cc")!) {
                    Label("Support Website", systemImage: "globe")
                }
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
