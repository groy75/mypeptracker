import Foundation

struct ChangelogEntry: Identifiable, Sendable {
    let version: String
    let build: Int
    let date: Date
    let changes: [String]

    var id: Int { build }
}
