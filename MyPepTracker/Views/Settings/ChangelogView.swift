import SwiftUI

struct ChangelogView: View {
    private static let fullHistoryURL = URL(string: "https://mypeptracker.gregsplace.cc/changelog")!

    var body: some View {
        List {
            ForEach(Changelog.entries) { entry in
                Section {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(entry.version)
                                .font(.title3.weight(.semibold))
                            Text("Build \(entry.build)")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text(entry.date, format: .dateTime.month(.abbreviated).day().year())
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .accessibilityElement(children: .combine)

                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(entry.changes, id: \.self) { change in
                                HStack(alignment: .top, spacing: 8) {
                                    Text("•")
                                        .foregroundStyle(AppTheme.primary)
                                        .accessibilityHidden(true)
                                    Text(change)
                                        .font(.callout)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Section {
                Link(destination: Self.fullHistoryURL) {
                    Label("See Full History Online", systemImage: "arrow.up.forward.square")
                }
            } footer: {
                Text("The full history, including older builds, lives on the support site.")
            }
        }
        .navigationTitle("What's New")
        .navigationBarTitleDisplayMode(.inline)
    }
}
