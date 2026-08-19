//
//  DashboardModels.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import Foundation

// MARK: - Grade Type

enum GradeType: String, CaseIterable {
    case gradeA, gradeB, gradeC, edible, reject

    var serverKey: String {
        switch self {
        case .gradeA: return "A"
        case .gradeB: return "B"
        case .gradeC: return "C"
        case .edible: return "EDIBLE"
        case .reject: return "REJECT"
        }
    }

    var serverID: Int {
        switch self {
        case .gradeA: return 1
        case .gradeB: return 2
        case .gradeC: return 3
        case .edible: return 4
        case .reject: return 5
        }
    }

    var displayName: String {
        switch self {
        case .gradeA: return "Grade A"
        case .gradeB: return "Grade B"
        case .gradeC: return "Grade C"
        case .edible: return "Edible"
        case .reject: return "Reject"
        }
    }

    var chartLabel: String {
        switch self {
        case .gradeA: return "A"
        case .gradeB: return "B"
        case .gradeC: return "C"
        case .edible: return "fork.knife"
        case .reject: return "xmark"
        }
    }

    var isSymbol: Bool {
        switch self {
        case .gradeA, .gradeB, .gradeC:
            return false
        case .edible, .reject:
            return true
        }
    }
}

// MARK: - Grade Result

struct GradeResult: Identifiable {
    let id = UUID()
    let gradeType: GradeType
    let weightKg: Double
    let count: Int
    let percentage: Double

    var isEmpty: Bool { weightKg == 0 && count == 0 }
}

// MARK: - Sorting Machine

struct SortingMachine: Identifiable, Hashable {
    let id: Int
    let name: String

    static let samples: [SortingMachine] = [
        SortingMachine(id: 1, name: "OranGo-1312"),
    ]
}

// MARK: - Grading Standard

struct GradingStandard: Identifiable, Hashable {
    let id: Int
    let name: String

    static let samples: [GradingStandard] = [
        GradingStandard(id: 1, name: "Superindo - Jeruk Medan"),
        GradingStandard(id: 2, name: "Superindo - Jeruk Pontianak"),
        GradingStandard(id: 3, name: "Hypermart - Jeruk Medan"),
        GradingStandard(id: 4, name: "Pasar Lokal - Campuran"),
    ]
}

// MARK: - Batch Entry

struct BatchEntry: Identifiable {
    let id: Int
    let name: String
    let weightKg: Double?
    let status: Status
    let machineID: Int?
    let gradingStandard: String?

    enum Status {
        case ongoing
        case completed
    }

    init(
        id: Int,
        name: String,
        weightKg: Double?,
        status: Status = .completed,
        machineID: Int? = nil,
        gradingStandard: String? = nil
    ) {
        self.id = id
        self.name = name
        self.weightKg = weightKg
        self.status = status
        self.machineID = machineID
        self.gradingStandard = gradingStandard
    }

    var isOngoing: Bool { status == .ongoing }
}

// MARK: - Sorting Day Entry

struct SortingDayEntry: Identifiable {
    let date: Date
    var batches: [BatchEntry]

    var id: Date { date }

    init(date: Date, batches: [BatchEntry]) {
        self.date = date
        self.batches = batches
    }

    private var completedBatches: [BatchEntry] {
        batches.filter { $0.status == .completed }
    }

    var totalWeightKg: Double {
        completedBatches.reduce(0) { $0 + ($1.weightKg ?? 0) }
    }

    var totalBatch: Int {
        completedBatches.count
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}

// MARK: - Harvest Insight

struct HarvestInsight: Identifiable {
    let id = UUID()
    let rank: Int
    let description: String
}

// MARK: - Dashboard Summary

struct DashboardSummary {
    let machineID: String
    let isActive: Bool
    let totalWeightKg: Double
    let totalCount: Int
    let totalBatch: Int
    let gradingStandard: String
    let lastUpdatedAt: Date?

    static let empty = DashboardSummary(
        machineID: "—",
        isActive: false,
        totalWeightKg: 0,
        totalCount: 0,
        totalBatch: 0,
        gradingStandard: "—",
        lastUpdatedAt: nil
    )
}

// MARK: - Date Filter

enum DateFilter: String, CaseIterable, Identifiable {
    case daily = "Harian"
    case weekly = "Mingguan"
    case monthly = "Bulanan"

    var id: String { rawValue }

    // MARK: Range

    func range(endingAt date: Date, calendar: Calendar = .current) -> DateInterval {
        let end = calendar.startOfDay(for: date)

        switch self {
        case .daily:
            return DateInterval(start: end, end: end)

        case .weekly:
            let weekday = calendar.component(.weekday, from: end)
            let start = calendar.date(byAdding: .day, value: -(weekday - 1), to: end) ?? end
            return DateInterval(start: start, end: end)

        case .monthly:
            let components = calendar.dateComponents([.year, .month], from: end)
            let start = calendar.date(from: components) ?? end
            return DateInterval(start: start, end: end)
        }
    }
}

extension DateInterval {
    func containsDay(_ date: Date, calendar: Calendar = .current) -> Bool {
        let day = calendar.startOfDay(for: date)
        return day >= start && day <= end
    }
}

// MARK: - Sample Data
// TODO: [DB] Hapus seluruh blok sample di bawah setelah data database tersambung.

extension DashboardSummary {
    static let sample = DashboardSummary(
        machineID: "OranGo-1312",
        isActive: true,
        totalWeightKg: 390.0,
        totalCount: 1245,
        totalBatch: 2,
        gradingStandard: "Superindo - Jeruk medan",
        lastUpdatedAt: nil
    )
}

extension GradeResult {
    static let emptyResults: [GradeResult] = GradeType.allCases.map {
        GradeResult(gradeType: $0, weightKg: 0, count: 0, percentage: 0)
    }

    static let sampleResults: [GradeResult] = [
        GradeResult(gradeType: .gradeA, weightKg: 100.6, count: 402, percentage: 27.8),
        GradeResult(gradeType: .gradeB, weightKg: 96.4,  count: 245, percentage: 26.6),
        GradeResult(gradeType: .gradeC, weightKg: 82.7,  count: 298, percentage: 22.8),
        GradeResult(gradeType: .edible, weightKg: 56.8,  count: 201, percentage: 15.7),
        GradeResult(gradeType: .reject, weightKg: 25.3,  count: 99,  percentage: 7.0),
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
    private static func daysAgo(_ offset: Int) -> Date {
        let calendar = Calendar.current
        let day = calendar.date(byAdding: .day, value: -offset, to: .now) ?? .now
        return calendar.startOfDay(for: day)
    }

    private static func makeBatches(_ weights: [Double]) -> [BatchEntry] {
        weights.enumerated().map { index, weight in
            BatchEntry(id: Self.nextSampleBatchID(), name: "Batch \(index + 1)", weightKg: weight)
        }
    }

    private static var sampleBatchCounter = 0

    private static func nextSampleBatchID() -> Int {
        sampleBatchCounter += 1
        return sampleBatchCounter
    }

    static let sampleEntries: [SortingDayEntry] = [
        SortingDayEntry(date: daysAgo(0), batches: makeBatches([330, 350])),
        SortingDayEntry(date: daysAgo(1), batches: makeBatches([330, 350, 310])),
        SortingDayEntry(date: daysAgo(2), batches: makeBatches([120, 120, 120, 120])),
        SortingDayEntry(date: daysAgo(3), batches: makeBatches([240, 240])),
        SortingDayEntry(date: daysAgo(4), batches: makeBatches([480])),

        SortingDayEntry(date: daysAgo(5), batches: makeBatches([250, 240, 235])),
        SortingDayEntry(date: daysAgo(6), batches: makeBatches([300, 310])),
        SortingDayEntry(date: daysAgo(7), batches: makeBatches([260, 280])),
        SortingDayEntry(date: daysAgo(8), batches: makeBatches([165, 165, 165])),
        SortingDayEntry(date: daysAgo(9), batches: makeBatches([380])),

        SortingDayEntry(date: daysAgo(10), batches: makeBatches([210, 200, 205, 205])),
        SortingDayEntry(date: daysAgo(11), batches: makeBatches([320, 320])),
    ]
}
