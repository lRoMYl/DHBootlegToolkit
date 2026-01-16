import Foundation

/// Verification utility for commentary counts and ratios
public struct CommentaryVerification {

    /// Verify commentary counts and ratios across all sentiments
    public static func verifyCommentaryCounts() -> VerificationReport {
        var report = VerificationReport()

        for category in SentimentCategory.allCases {
            let wittyCount = category.wittyCommentaryTemplates.count
            let positiveCount = category.positiveCommentaryTemplates.count
            let totalCount = wittyCount + positiveCount

            let positiveRatio = Double(positiveCount) / Double(totalCount)
            let wittyRatio = Double(wittyCount) / Double(totalCount)

            // Target: 70% positive (±2%), 30% witty (±2%)
            let positiveInRange = (0.68...0.72).contains(positiveRatio)
            let wittyInRange = (0.28...0.32).contains(wittyRatio)
            let ratioValid = positiveInRange && wittyInRange

            let categoryReport = CategoryReport(
                category: category,
                wittyCount: wittyCount,
                positiveCount: positiveCount,
                totalCount: totalCount,
                positiveRatio: positiveRatio,
                wittyRatio: wittyRatio,
                ratioValid: ratioValid
            )

            report.categoryReports.append(categoryReport)
        }

        // Special templates verification
        let wittySpecialCount = SentimentCategory.wittySpecialTemplates.count
        let positiveSpecialCount = SentimentCategory.positiveSpecialTemplates.count
        let specialTotal = wittySpecialCount + positiveSpecialCount

        report.specialTemplatesReport = SpecialTemplatesReport(
            wittyCount: wittySpecialCount,
            positiveCount: positiveSpecialCount,
            totalCount: specialTotal
        )

        return report
    }

    /// Print verification report to console
    public static func printVerificationReport() {
        let report = verifyCommentaryCounts()

        print("=== Commentary Verification Report ===\n")

        for categoryReport in report.categoryReports {
            let status = categoryReport.ratioValid ? "✅ PASS" : "❌ FAIL"
            print("\(categoryReport.category.label):")
            print("  Witty: \(categoryReport.wittyCount) (\(String(format: "%.1f", categoryReport.wittyRatio * 100))%)")
            print("  Positive: \(categoryReport.positiveCount) (\(String(format: "%.1f", categoryReport.positiveRatio * 100))%)")
            print("  Total: \(categoryReport.totalCount)")
            print("  Status: \(status)\n")
        }

        if let specialReport = report.specialTemplatesReport {
            print("Special Templates:")
            print("  Witty: \(specialReport.wittyCount)")
            print("  Positive: \(specialReport.positiveCount)")
            print("  Total: \(specialReport.totalCount)\n")
        }

        let totalRegular = report.categoryReports.reduce(0) { $0 + $1.totalCount }
        let totalSpecial = report.specialTemplatesReport?.totalCount ?? 0
        let grandTotal = totalRegular + totalSpecial

        print("Grand Totals:")
        print("  Regular: \(totalRegular)")
        print("  Special: \(totalSpecial)")
        print("  Total: \(grandTotal)")

        let allValid = report.categoryReports.allSatisfy { $0.ratioValid }
        print("\nOverall Status: \(allValid ? "✅ ALL PASS" : "❌ SOME FAILED")")
    }
}

// MARK: - Report Types

public struct VerificationReport {
    public var categoryReports: [CategoryReport] = []
    public var specialTemplatesReport: SpecialTemplatesReport?
}

public struct CategoryReport {
    public let category: SentimentCategory
    public let wittyCount: Int
    public let positiveCount: Int
    public let totalCount: Int
    public let positiveRatio: Double
    public let wittyRatio: Double
    public let ratioValid: Bool
}

public struct SpecialTemplatesReport {
    public let wittyCount: Int
    public let positiveCount: Int
    public let totalCount: Int
}
