//
//  SortingStore.swift
//  OranGo
//
//  Single source of truth for sorting data, shared by the Dashboard and Batch Detail.
//

import Foundation

@Observable
@MainActor
final class SortingStore {

    // MARK: - Data

    // Everything starts empty and is filled by `load()`. Seeding these with sample values
    // meant insights were written from figures that had never come from the server.
    var summary: DashboardSummary = .empty
    var gradeResults: [GradeResult] = GradeResult.emptyResults
    var sortingEntries: [SortingDayEntry] = []

    var machines: [SortingMachine] = []
    var gradingStandards: [GradingStandard] = []

    // Inputs the insight card needs but the dashboard itself does not display.
    private(set) var comparison: InsightComparison?
    private(set) var rejectBreakdown: RejectBreakdown?
    private(set) var throughputPerHour: Double?

    // MARK: - Loading State

    var isLoading = false
    var lastError: String?

    /// True once a fetch has replaced the seeded sample values.
    var isLive = false
    var lastUpdatedAt: Date?

    private let api = OranGoAPI.shared
    private var refreshTask: Task<Void, Never>?

    private var allBatches: [Batch] = []
    private var allScans: [HasilSortir] = []
    private var activeMachine: Machine?
    private var retailGrades: [RetailGrade] = []
    private var standardsByID: [Int: String] = [:]

    private(set) var range: DateInterval = DateFilter.daily.range(endingAt: .now)

    /// Batch weights arrive per fruit in grams; every figure the UI shows is in kilograms.
    private static let gramsPerKilogram = 1000.0

    // MARK: - Lookups

    var ongoingBatches: [BatchEntry] {
        sortingEntries.flatMap(\.batches).filter(\.isOngoing)
    }

    var availableMachines: [SortingMachine] {
        let busyIDs = Set(ongoingBatches.compactMap(\.machineID))
        return machines.filter { !busyIDs.contains($0.id) }
    }

    func batch(id: Int) -> BatchEntry? {
        sortingEntries.flatMap(\.batches).first { $0.id == id }
    }

    private var todayIndex: Int? {
        sortingEntries.firstIndex { $0.isToday }
    }

    // MARK: - Fetching

    func load() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let machinesRequest = api.machines()
            async let retailRequest = api.retailGrades()
            async let batchesRequest = api.batches()
            async let scansRequest = api.hasilSortir()

            let (machineList, retailList, batchList, scans) =
                try await (machinesRequest, retailRequest, batchesRequest, scansRequest)

            let freshMachines = machineList.map { SortingMachine(id: $0.id, name: $0.machineName) }
            let freshStandards = retailList.map { GradingStandard(id: $0.id, name: $0.retailName) }

            if freshMachines != machines { machines = freshMachines }
            if freshStandards != gradingStandards { gradingStandards = freshStandards }

            activeMachine = machineList.first
            retailGrades = retailList
            standardsByID = Dictionary(uniqueKeysWithValues: gradingStandards.map { ($0.id, $0.name) })
            allBatches = batchList
            allScans = scans.filter { $0.batch != nil }

            recompute()

            isLive = true
            lastUpdatedAt = .now
            lastError = nil
        } catch {
            // A cancelled poll is not a failure worth showing on the dashboard.
            if !error.isCancellation {
                lastError = error.localizedDescription
            }
        }
    }

    /// Retail grades an unfinished batch is still sorting against, so the grading standard
    /// screen can refuse to change one out from under a running machine.
    var retailGradeIDsInUse: Set<Int> {
        Set(allBatches.filter { $0.selesaiPada == nil }.map(\.retailGrade.id))
    }

    /// One refresher for the whole app, so pushing a detail screen does not double
    /// the request rate.
    func startAutoRefresh() {
        guard refreshTask == nil else { return }

        refreshTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.load()
                try? await Task.sleep(for: .seconds(Date.refreshInterval))
            }
        }
    }

    // MARK: - Period

    func setRange(_ newRange: DateInterval) {
        range = newRange
        recompute()
    }

    private func recompute() {
        let scans = allScans.filter { range.containsDay($0.waktuScan) }
        let scannedBatchIDs = Set(scans.compactMap { $0.batch?.id })
        let batches = allBatches.filter {
            range.containsDay($0.mulaiPada) || scannedBatchIDs.contains($0.id)
        }

        sortingEntries = Self.groupIntoDays(batches, scans: scans, standards: standardsByID, range: range)
        gradeResults = Self.aggregateGrades(scans)
        comparison = makeComparison(current: scans)
        rejectBreakdown = Self.makeRejectBreakdown(scans, standard: activeStandard)
        throughputPerHour = Self.makeThroughput(scans)
        summary = Self.makeSummary(
            machine: activeMachine,
            scans: scans,
            batches: batches,
            standards: standardsByID,
            activeStandard: activeStandardName,
            lastUpdatedAt: lastUpdatedAt
        )
    }

    /// The standard the machine is grading against right now. The machine's own pointer wins
    /// over the `aktif` flags, which the server currently sets on more than one row.
    private var activeStandard: RetailGrade? {
        if let id = activeMachine?.thresholdAktif?.id,
           let match = retailGrades.first(where: { $0.id == id }) {
            return match
        }
        return retailGrades.first(where: \.isActive)
    }

    private var activeStandardName: String? {
        activeStandard?.retailName
    }

    // MARK: - Insight Inputs

    /// The same span, one span earlier — so "kemarin" for a day view and "minggu sebelumnya"
    /// for a week view both fall out of the selected range rather than needing to be told.
    private func makeComparison(current: [HasilSortir]) -> InsightComparison? {
        let calendar = Calendar.current
        let days = (calendar.dateComponents([.day], from: range.start, to: range.end).day ?? 0) + 1

        guard
            let previousStart = calendar.date(byAdding: .day, value: -days, to: range.start),
            let previousEnd = calendar.date(byAdding: .day, value: -days, to: range.end)
        else { return nil }

        let previousRange = DateInterval(start: previousStart, end: previousEnd)
        let previousScans = allScans.filter { previousRange.containsDay($0.waktuScan) }

        // Nothing to compare against is not a trend of zero; say nothing instead.
        guard !previousScans.isEmpty, !current.isEmpty else { return nil }

        let results = Self.aggregateGrades(previousScans)
        let reject = results.first { $0.gradeType == .reject }?.percentage ?? 0
        let retail = results
            .filter { [.gradeA, .gradeB, .gradeC].contains($0.gradeType) }
            .reduce(0) { $0 + $1.percentage }

        let label: String
        switch days {
        case 1: label = "kemarin"
        case 2 ... 7: label = "minggu sebelumnya"
        default: label = "periode sebelumnya"
        }

        return InsightComparison(
            label: label,
            totalWeightKg: previousScans.reduce(0) { $0 + $1.berat } / Self.gramsPerKilogram,
            totalCount: previousScans.count,
            rejectPercentage: reject,
            retailGradePercentage: retail
        )
    }

    /// How close a miss still counts as recoverable.
    private static let nearMissDiameterCm = 0.3
    private static let nearMissColourPoints = 5.0

    static func makeRejectBreakdown(_ scans: [HasilSortir], standard: RetailGrade?) -> RejectBreakdown? {
        guard let standard else { return nil }

        // Edible and reject are both fruit that did not make retail grade.
        let failed = scans.filter { scan in
            scan.grade.id == GradeType.reject.serverID || scan.grade.id == GradeType.edible.serverID
        }
        guard !failed.isEmpty else { return nil }

        var byDiameter = 0, byWeight = 0, byColour = 0, byShape = 0
        var nearMissDiameter = 0, nearMissColour = 0

        for scan in failed {
            let failsDiameter = outOfRange(scan.diameter, min: standard.diameterMin, max: standard.diameterMaks)
            let failsWeight = outOfRange(scan.berat, min: standard.beratMin, max: standard.beratMaks)
            let failsColour = standard.warnaOranye.map { scan.warnaOranye < $0 } ?? false
            let failsShape = !scan.bentukWajar

            if failsDiameter { byDiameter += 1 }
            if failsWeight { byWeight += 1 }
            if failsColour { byColour += 1 }
            if failsShape { byShape += 1 }

            // Only a fruit failing exactly one criterion is worth chasing — fixing one
            // threshold cannot rescue a fruit that misses on several.
            let failureCount = [failsDiameter, failsWeight, failsColour, failsShape].filter { $0 }.count
            guard failureCount == 1 else { continue }

            if failsDiameter, let margin = margin(scan.diameter, min: standard.diameterMin, max: standard.diameterMaks),
               margin <= nearMissDiameterCm {
                nearMissDiameter += 1
            }

            if failsColour, let threshold = standard.warnaOranye,
               threshold - scan.warnaOranye <= nearMissColourPoints {
                nearMissColour += 1
            }
        }

        let nearMissCount = nearMissDiameter + nearMissColour
        let nearMissCause: String? = nearMissCount == 0
            ? nil
            : (nearMissColour >= nearMissDiameter ? "warna" : "diameter")

        return RejectBreakdown(
            standardName: standard.retailName,
            failedCount: failed.count,
            byDiameter: byDiameter,
            byWeight: byWeight,
            byColour: byColour,
            byShape: byShape,
            nearMissCount: nearMissCount,
            nearMissCause: nearMissCause
        )
    }

    private static func outOfRange(_ value: Double, min: Double?, max: Double?) -> Bool {
        if let min, value < min { return true }
        if let max, value > max { return true }
        return false
    }

    /// How far outside the range the value sits, or nil when it is inside.
    private static func margin(_ value: Double, min: Double?, max: Double?) -> Double? {
        if let min, value < min { return min - value }
        if let max, value > max { return value - max }
        return nil
    }

    static func makeThroughput(_ scans: [HasilSortir]) -> Double? {
        // A handful of scans over a few seconds extrapolates to nonsense.
        guard scans.count >= 10 else { return nil }

        let times = scans.map(\.waktuScan).sorted()
        guard let first = times.first, let last = times.last else { return nil }

        let hours = last.timeIntervalSince(first) / 3600
        guard hours >= 0.25 else { return nil }

        return Double(scans.count) / hours
    }

    // MARK: - Batch Lifecycle

    @discardableResult
    func startBatch(machine: SortingMachine, standard: GradingStandard) async throws -> BatchEntry {
        let dto = try await api.createBatch(
            machineID: machine.id,
            retailGradeID: standard.id
        )
        let batch = BatchEntry(
            id: dto.id,
            name: dto.kodeBatch,
            weightKg: nil,
            status: .ongoing,
            machineID: dto.machine.id,
            gradingStandard: standard.name
        )
        allBatches.append(dto)
        insert(batch, on: dto.mulaiPada)
        return batch
    }

    func finishBatch(id: Int) async throws {
        _ = try await api.finishBatch(id: id)
        await load()
    }

    // MARK: - Batch Detail

    func detail(for route: BatchDetailRoute) -> BatchDetail {
        let batch = batch(id: route.batchID)
        let scans = allScans.filter { $0.batchId == route.batchID }

        // A batch is graded against the standard it was started with, not whichever one is
        // active now.
        let standardID = allBatches.first { $0.id == route.batchID }?.retailGrade.id
        let standard = standardID.flatMap { id in retailGrades.first { $0.id == id } }

        return BatchDetail(
            route: route,
            isOngoing: batch?.isOngoing ?? false,
            totalWeightKg: scans.reduce(0) { $0 + $1.berat } / Self.gramsPerKilogram,
            totalCount: scans.count,
            gradingStandard: batch?.gradingStandard ?? summary.gradingStandard,
            gradeResults: Self.aggregateGrades(scans),
            insights: [],
            rejectBreakdown: Self.makeRejectBreakdown(scans, standard: standard),
            throughputPerHour: Self.makeThroughput(scans)
        )
    }

    // MARK: - Mutation Helpers

    private func insert(_ batch: BatchEntry, on date: Date) {
        let day = Calendar.current.startOfDay(for: date)

        if let index = sortingEntries.firstIndex(where: {
            Calendar.current.isDate($0.date, inSameDayAs: day)
        }) {
            sortingEntries[index].batches.append(batch)
        } else {
            sortingEntries.insert(SortingDayEntry(date: day, batches: [batch]), at: 0)
        }
    }

    // MARK: - Mapping

    private static func groupIntoDays(
        _ batches: [Batch],
        scans: [HasilSortir],
        standards: [Int: String],
        range: DateInterval
    ) -> [SortingDayEntry] {
        let calendar = Calendar.current
        let batchesByID = Dictionary(uniqueKeysWithValues: batches.map { ($0.id, $0) })

        var weightByDayAndBatch: [Date: [Int: Double]] = [:]
        for scan in scans {
            guard let batchID = scan.batch?.id else { continue }
            let day = calendar.startOfDay(for: scan.waktuScan)
            weightByDayAndBatch[day, default: [:]][batchID, default: 0] += scan.berat
        }

        // A batch that has not produced a scan yet still belongs on the day it started.
        for batch in batches where range.containsDay(batch.mulaiPada) {
            let day = calendar.startOfDay(for: batch.mulaiPada)
            if weightByDayAndBatch[day]?[batch.id] == nil {
                weightByDayAndBatch[day, default: [:]][batch.id] = 0
            }
        }

        // Today always gets a row so a first batch of the day can be started from it.
        let today = calendar.startOfDay(for: .now)
        if range.containsDay(today) {
            weightByDayAndBatch[today] = weightByDayAndBatch[today] ?? [:]
        }

        return weightByDayAndBatch
            .sorted { $0.key > $1.key }
            .map { day, weights in
                SortingDayEntry(
                    date: day,
                    batches: weights
                        .sorted { lhs, rhs in
                            let left = batchesByID[lhs.key]?.mulaiPada ?? .distantPast
                            let right = batchesByID[rhs.key]?.mulaiPada ?? .distantPast
                            return left < right
                        }
                        .map { batchID, grams in
                            let dto = batchesByID[batchID]
                            let isOngoing = dto?.selesaiPada == nil
                            return BatchEntry(
                                id: batchID,
                                name: dto?.kodeBatch ?? "Batch \(batchID)",
                                weightKg: isOngoing ? nil : grams / gramsPerKilogram,
                                status: isOngoing ? .ongoing : .completed,
                                machineID: dto?.machine.id,
                                gradingStandard: dto.flatMap { standards[$0.retailGrade.id] }
                            )
                        }
                )
            }
    }

    private static func aggregateGrades(_ scans: [HasilSortir]) -> [GradeResult] {
        var weightByGrade: [Int: Double] = [:]
        var countByGrade: [Int: Int] = [:]

        for scan in scans {
            weightByGrade[scan.grade.id, default: 0] += scan.berat
            countByGrade[scan.grade.id, default: 0] += 1
        }

        let totalWeight = weightByGrade.values.reduce(0, +)

        return GradeType.allCases.map { grade in
            let weight = weightByGrade[grade.serverID] ?? 0
            return GradeResult(
                gradeType: grade,
                weightKg: weight / gramsPerKilogram,
                count: countByGrade[grade.serverID] ?? 0,
                percentage: totalWeight > 0 ? weight / totalWeight * 100 : 0
            )
        }
    }

    private static func makeSummary(
        machine: Machine?,
        scans: [HasilSortir],
        batches: [Batch],
        standards: [Int: String],
        activeStandard: String?,
        lastUpdatedAt: Date?
    ) -> DashboardSummary {
        return DashboardSummary(
            machineID: machine?.machineName ?? "—",
            isActive: machine?.isConnected ?? false,
            totalWeightKg: scans.reduce(0) { $0 + $1.berat } / gramsPerKilogram,
            totalCount: scans.count,
            totalBatch: batches.filter { $0.selesaiPada != nil }.count,
            gradingStandard: activeStandard
                ?? batches.last.flatMap { standards[$0.retailGrade.id] }
                ?? "—",
            lastUpdatedAt: lastUpdatedAt
        )
    }
}
