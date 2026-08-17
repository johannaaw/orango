//
//  SortingStore.swift
//  OranGo
//
//  Single source of truth for sorting data, shared by the Dashboard and Batch Detail.
//

import Foundation

// TODO: [DB] Seluruh isi store ini masih memakai nilai sample.
@Observable
@MainActor
final class SortingStore {
    // MARK: - Data

    // TODO: [DB] Ganti keempat properti ini dengan hasil query dashboard.
    var summary: DashboardSummary = .sample
    var gradeResults: [GradeResult] = GradeResult.sampleResults
    var insights: [HarvestInsight] = HarvestInsight.sampleInsights
    var sortingEntries: [SortingDayEntry] = SortingDayEntry.sampleEntries

    // TODO: [DB] Ganti dengan master data mesin dan standar grading dari database.
    let machines: [SortingMachine] = SortingMachine.samples
    let gradingStandards: [GradingStandard] = GradingStandard.samples

    // MARK: - Lookups

    var ongoingBatches: [BatchEntry] {
        sortingEntries.flatMap(\.batches).filter(\.isOngoing)
    }

    var availableMachines: [SortingMachine] {
        let busyIDs = Set(ongoingBatches.compactMap(\.machineID))
        return machines.filter { !busyIDs.contains($0.id) }
    }

    func batch(id: UUID) -> BatchEntry? {
        sortingEntries.flatMap(\.batches).first { $0.id == id }
    }

    private var todayIndex: Int? {
        sortingEntries.firstIndex { $0.isToday }
    }

    // MARK: - Batch Lifecycle

    // TODO: [DB] Simpan batch baru ke database, lalu pakai record hasil simpan.
    @discardableResult
    func startBatch(machine: SortingMachine, standard: GradingStandard) -> BatchEntry? {
        guard let index = todayIndex else { return nil }

        let batch = BatchEntry(
            name: "Batch \(sortingEntries[index].batches.count + 1)",
            weightKg: nil,
            status: .ongoing,
            machineID: machine.id,
            gradingStandard: standard.name
        )
        sortingEntries[index].batches.append(batch)
        return batch
    }

    // TODO: [DB] Tandai batch selesai di database dan ambil angka asli dari mesin — weightKg di bawah masih memakai DashboardSummary.sample.
    func finishBatch(id: UUID) {
        for dayIndex in sortingEntries.indices {
            guard let batchIndex = sortingEntries[dayIndex].batches.firstIndex(where: { $0.id == id })
            else { continue }

            let batch = sortingEntries[dayIndex].batches[batchIndex]
            sortingEntries[dayIndex].batches[batchIndex] = BatchEntry(
                id: batch.id,
                name: batch.name,
                weightKg: DashboardSummary.sample.totalWeightKg,
                status: .completed,
                machineID: batch.machineID,
                gradingStandard: batch.gradingStandard
            )
            return
        }
    }

    // MARK: - Batch Detail

    // TODO: [DB] Ambil detail batch dari database berdasarkan route.batchID.
    func detail(for route: BatchDetailRoute) -> BatchDetail {
        let batch = batch(id: route.batchID)
        let isOngoing = batch?.isOngoing ?? false

        return BatchDetail(
            route: route,
            isOngoing: isOngoing,
            totalWeightKg: isOngoing ? 0 : (batch?.weightKg ?? summary.totalWeightKg),
            totalCount: isOngoing ? 0 : summary.totalCount,
            gradingStandard: batch?.gradingStandard ?? summary.gradingStandard,
            gradeResults: isOngoing ? GradeResult.emptyResults : gradeResults,
            insights: isOngoing ? [] : insights
        )
    }
}
