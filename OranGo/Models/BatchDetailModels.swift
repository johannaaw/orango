//
//  BatchDetailModels.swift
//  OranGo
//
//  Model for the per-batch detail screen reached from the Detail Sorting table.
//

import Foundation

// MARK: - Batch Detail Route

struct BatchDetailRoute: Hashable {
    let batchID: Int
    let batchName: String
    let date: Date

    var title: String {
        "\(batchName) - \(date.formattedIndonesian)"
    }
}

// MARK: - Batch Detail

struct BatchDetail {
    let route: BatchDetailRoute
    let isOngoing: Bool
    let totalWeightKg: Double
    let totalCount: Int
    let gradingStandard: String
    let gradeResults: [GradeResult]
    let insights: [HarvestInsight]

    /// Insight inputs, not shown on the screen itself.
    var rejectBreakdown: RejectBreakdown? = nil
    var throughputPerHour: Double? = nil
}

// MARK: - Sample Data
// TODO: [DB] Hapus blok sample di bawah setelah data database tersambung.

extension BatchDetail {
    static func sample(for route: BatchDetailRoute) -> BatchDetail {
        BatchDetail(
            route: route,
            isOngoing: false,
            totalWeightKg: DashboardSummary.sample.totalWeightKg,
            totalCount: DashboardSummary.sample.totalCount,
            gradingStandard: DashboardSummary.sample.gradingStandard,
            gradeResults: GradeResult.sampleResults,
            insights: HarvestInsight.sampleInsights
        )
    }
}
