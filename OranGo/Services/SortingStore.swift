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

    var summary: DashboardSummary = .sample
    var gradeResults: [GradeResult] = GradeResult.sampleResults
    var insights: [HarvestInsight] = HarvestInsight.sampleInsights
    var sortingEntries: [SortingDayEntry] = SortingDayEntry.sampleEntries

    var machines: [SortingMachine] = SortingMachine.samples
    var gradingStandards: [GradingStandard] = GradingStandard.samples

    // MARK: - Loading State

    var isLoading = false
    var lastError: String?

    /// True once a fetch has replaced the seeded sample values.
    var isLive = false
    var lastUpdatedAt: Date?

    private let api = OranGoAPI.shared

    private var allBatches: [BatchDTO] = []
    private var allScans: [HasilSortirDTO] = []
    private var machineDTO: MachineDTO?
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

            let (machineDTOs, retailDTOs, batchDTOs, scans) =
                try await (machinesRequest, retailRequest, batchesRequest, scansRequest)

            let freshMachines = machineDTOs.map { SortingMachine(id: $0.id, name: $0.machineName) }
            let freshStandards = retailDTOs.map { GradingStandard(id: $0.id, name: $0.retailName) }

            if freshMachines != machines { machines = freshMachines }
            if freshStandards != gradingStandards { gradingStandards = freshStandards }

            machineDTO = machineDTOs.first
            standardsByID = Dictionary(uniqueKeysWithValues: gradingStandards.map { ($0.id, $0.name) })
            allBatches = batchDTOs
            allScans = scans.filter { $0.batch != nil }

            recompute()

            isLive = true
            lastUpdatedAt = .now
            lastError = nil
        } catch {
            lastError = error.localizedDescription
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
        summary = Self.makeSummary(
            machine: machineDTO,
            scans: scans,
            batches: batches,
            standards: standardsByID,
            lastUpdatedAt: lastUpdatedAt
        )
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
        let scans = try await api.hasilSortir(batchID: id)
        apply(scans: scans, toBatch: id)
    }

    // MARK: - Batch Detail

    func detail(for route: BatchDetailRoute) -> BatchDetail {
        let batch = batch(id: route.batchID)
        let isOngoing = batch?.isOngoing ?? false

        return BatchDetail(
            route: route,
            isOngoing: isOngoing,
            totalWeightKg: isOngoing ? 0 : (batch?.weightKg ?? 0),
            totalCount: isOngoing ? 0 : (batchCounts[route.batchID] ?? 0),
            gradingStandard: batch?.gradingStandard ?? summary.gradingStandard,
            gradeResults: isOngoing ? GradeResult.emptyResults : (batchGrades[route.batchID] ?? gradeResults),
            insights: isOngoing ? [] : insights
        )
    }

    private var batchCounts: [Int: Int] = [:]
    private var batchGrades: [Int: [GradeResult]] = [:]

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

    private func apply(scans: [HasilSortirDTO], toBatch id: Int) {
        let weightKg = scans.reduce(0) { $0 + $1.berat } / Self.gramsPerKilogram

        batchCounts[id] = scans.count
        batchGrades[id] = Self.aggregateGrades(scans)

        for dayIndex in sortingEntries.indices {
            guard let batchIndex = sortingEntries[dayIndex].batches.firstIndex(where: { $0.id == id })
            else { continue }

            let batch = sortingEntries[dayIndex].batches[batchIndex]
            sortingEntries[dayIndex].batches[batchIndex] = BatchEntry(
                id: batch.id,
                name: batch.name,
                weightKg: weightKg,
                status: .completed,
                machineID: batch.machineID,
                gradingStandard: batch.gradingStandard
            )
            return
        }
    }

    // MARK: - Mapping

    private static func groupIntoDays(
        _ batches: [BatchDTO],
        scans: [HasilSortirDTO],
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

    private static func aggregateGrades(_ scans: [HasilSortirDTO]) -> [GradeResult] {
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
        machine: MachineDTO?,
        scans: [HasilSortirDTO],
        batches: [BatchDTO],
        standards: [Int: String],
        lastUpdatedAt: Date?
    ) -> DashboardSummary {
        return DashboardSummary(
            machineID: machine?.machineName ?? "—",
            isActive: machine?.statusKoneksi.caseInsensitiveCompare("Terhubung") == .orderedSame,
            totalWeightKg: scans.reduce(0) { $0 + $1.berat } / gramsPerKilogram,
            totalCount: scans.count,
            totalBatch: batches.filter { $0.selesaiPada != nil }.count,
            gradingStandard: batches.last.flatMap { standards[$0.retailGrade.id] }
                ?? standards.values.sorted().first
                ?? "—",
            lastUpdatedAt: lastUpdatedAt
        )
    }
}
