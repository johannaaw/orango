//
//  DashboardModels.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import Foundation

// MARK: - Grade Type

/// Represents the grading categories for sorted oranges.
enum GradeType: String, CaseIterable {
    case gradeA, gradeB, gradeC, edible, reject

    /// Label/String yang akan ditampilkan di Donut Chart
    var chartLabel: String {
        switch self {
        case .gradeA: return "A"             // Teks biasa
        case .gradeB: return "B"             // Teks biasa
        case .gradeC: return "C"             // Teks biasa
        case .edible: return "fork.knife"    // SF Symbol
        case .reject: return "xmark"         // SF Symbol (pengganti "X")
        }
    }

    /// Penanda apakah `chartLabel` di atas adalah ikon SF Symbol atau bukan
    var isSymbol: Bool {
        switch self {
        case .gradeA, .gradeB, .gradeC:
            return false
        case .edible, .reject:
            return true
        }
    }
    /// SF Symbol name used as icon placeholder.
    /// TODO: Replace with custom asset images from the design system.
    var iconName: String {
        switch self {
        case .gradeA: return "a.circle.fill"
        case .gradeB: return "b.circle.fill"
        case .gradeC: return "c.circle.fill"
        case .edible: return "fork.knife.circle.fill"
        case .reject: return "xmark.circle.fill"
        }
    }
}

// MARK: - Grade Result

/// A single grade's sorting result with weight and percentage.
struct GradeResult: Identifiable {
    let id = UUID()
    let gradeType: GradeType
    let weightKg: Double
    let percentage: Double
}

// MARK: - Batch Entry

/// A single batch within a sorting day.
struct BatchEntry: Identifiable {
    let id = UUID()
    let name: String       // e.g. "Batch 1"
    let weightKg: Double   // e.g. 330
}

// MARK: - Sorting Day Entry

/// A day's sorting summary with expandable batch details.
struct SortingDayEntry: Identifiable {
    let id = UUID()
    let date: Date
    let totalWeightKg: Double
    let totalBatch: Int
    let batches: [BatchEntry]
}

// MARK: - Harvest Insight

/// A ranked insight item for the harvest section.
struct HarvestInsight: Identifiable {
    let id = UUID()
    let rank: Int          // 1, 2, 3
    let description: String
}

// MARK: - Dashboard Summary

/// Top-level dashboard summary data.
struct DashboardSummary {
    let machineID: String         // e.g. "OranGo-1312"
    let isActive: Bool
    let totalWeightKg: Double     // e.g. 390.0
    let totalCount: Int           // e.g. 1245
    let gradingStandard: String   // e.g. "Superindo - Jeruk medan"
    let lastUpdated: String       // e.g. "30 detik yang lalu"
}

// MARK: - Date Filter

/// Filter options for the dashboard date range.
enum DateFilter: String, CaseIterable, Identifiable {
    case today = "Hari Ini"
    case thisWeek = "Minggu Ini"
    case thisMonth = "Bulan Ini"

    var id: String { rawValue }
}

// MARK: - Sample Data
// TODO: Replace all sample data below with actual database / API fetches.

extension DashboardSummary {
    static let sample = DashboardSummary(
        machineID: "OranGo-1312",
        isActive: true,
        totalWeightKg: 390.0,
        totalCount: 1245,
        gradingStandard: "Superindo - Jeruk medan",
        lastUpdated: "30 detik yang lalu"
    )
}

extension GradeResult {
    static let sampleResults: [GradeResult] = [
        GradeResult(gradeType: .gradeA, weightKg: 100.6, percentage: 27.8),
        GradeResult(gradeType: .gradeB, weightKg: 96.4,  percentage: 26.6),
        GradeResult(gradeType: .gradeC, weightKg: 82.7,  percentage: 22.8),
        GradeResult(gradeType: .edible, weightKg: 56.8,  percentage: 15.7),
        GradeResult(gradeType: .reject, weightKg: 25.3,  percentage: 7.0),
    ]
}

extension HarvestInsight {
    static let sampleInsights: [HarvestInsight] = [
        HarvestInsight(rank: 1, description: "Lorem Ipsum dolor sit amet"),
        HarvestInsight(rank: 2, description: "Lorem Ipsum dolor sit amet"),
        HarvestInsight(rank: 3, description: "Lorem Ipsum dolor sit amet"),
    ]
}

extension SortingDayEntry {
    /// Helper to create a Date from day/month/year.
    private static func makeDate(day: Int, month: Int, year: Int) -> Date {
        var comps = DateComponents()
        comps.day = day
        comps.month = month
        comps.year = year
        return Calendar.current.date(from: comps) ?? .now
    }

    static let sampleEntries: [SortingDayEntry] = [
        SortingDayEntry(
            date: makeDate(day: 17, month: 8, year: 2026),
            totalWeightKg: 680,
            totalBatch: 2,
            batches: [
                BatchEntry(name: "Batch 1", weightKg: 330),
                BatchEntry(name: "Batch 2", weightKg: 350),
            ]
        ),
        SortingDayEntry(
            date: makeDate(day: 16, month: 8, year: 2026),
            totalWeightKg: 930,
            totalBatch: 3,
            batches: [
                BatchEntry(name: "Batch 1", weightKg: 330),
                BatchEntry(name: "Batch 2", weightKg: 350),
                BatchEntry(name: "Batch 3", weightKg: 310),
            ]
        ),
        SortingDayEntry(
            date: makeDate(day: 15, month: 8, year: 2026),
            totalWeightKg: 480,
            totalBatch: 4,
            batches: []
        ),
        SortingDayEntry(
            date: makeDate(day: 14, month: 8, year: 2026),
            totalWeightKg: 480,
            totalBatch: 2,
            batches: []
        ),
        SortingDayEntry(
            date: makeDate(day: 13, month: 8, year: 2026),
            totalWeightKg: 480,
            totalBatch: 1,
            batches: []
        ),
    ]
}
