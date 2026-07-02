import Foundation

// MARK: - Convenience extensions for existing models
// Models are defined in Core/Models/UserProfile.swift and Core/Models/ReadingContent.swift

extension ReadingContent {
    /// Total word count across all pages
    var totalWordCount: Int {
        pages.reduce(0) { $0 + $1.wordCount }
    }
}
