//
//  StandardGradingViewModel.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class StandardGradingViewModel {
    /// Thresholds live on the retail grade itself now, so this one list backs the screen.
    var retailGrades: [RetailGrade] = []
    var grades: [Grade] = []
    var isLoading = false
    var errorMessage: String?

    private let api = OranGoAPI.shared

    var retailGradeNameById: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: retailGrades.map {
                ($0.id, $0.retailName)
            }
        )
    }

    /// The active standard sits at the top of the list; the rest keep the server's order.
    var sortedRetailGrades: [RetailGrade] {
        retailGrades.enumerated()
            .sorted { lhs, rhs in
                if lhs.element.isActive != rhs.element.isActive {
                    return lhs.element.isActive
                }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    var gradeNameById: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: grades.map {
                ($0.id, $0.kelasGrading)
            }
        )
    }

    // MARK: - GET

    func fetchRetailGrades() async {
        do {
            retailGrades = try await api.retailGrades()
        } catch {
            report(error)
        }
    }

    /// Leaving the page cancels the `.task` that started the fetch. That is routine, not a
    /// failure — reporting it is what put "Cancelled / Coba Lagi" on screen when switching pages.
    private func report(_ error: Error) {
        guard !error.isCancellation else { return }
        errorMessage = error.localizedDescription
    }

    func refreshRetailGrades() async throws {
        retailGrades = try await api.retailGrades()
    }

    func fetchGrades() async {
        do {
            grades = try await api.grades()
        } catch {
            report(error)
        }
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchRetailGrades()
            }

            group.addTask {
                await self.fetchGrades()
            }
        }

        isLoading = false
    }

    // MARK: - CREATE

    func createRetailGrade(_ draft: RetailGradeDraft) async throws {
        let created = try await api.createRetailGrade(draft)
        retailGrades.append(created)
    }

    func create(_ draft: RetailGradeDraft) async throws {
        try await createRetailGrade(draft)
    }

    // MARK: - UPDATE

    func updateRetailGrade(id: Int, draft: RetailGradeDraft) async throws {
        let updated = try await api.updateRetailGrade(id: id, draft: draft)

        if let index = retailGrades.firstIndex(where: { $0.id == updated.id }) {
            retailGrades[index] = updated
        }
    }

    func update(id: Int, draft: RetailGradeDraft) async throws {
        try await updateRetailGrade(id: id, draft: draft)
    }

    // MARK: - ACTIVATE RETAIL GRADE

    func setRetailGradeActive(id: Int, isActive: Bool) async throws {
        let previousRetailGrades = retailGrades

        if let index = retailGrades.firstIndex(where: { $0.id == id }) {
            let retailGrade = retailGrades[index]
            retailGrades[index] = RetailGrade(
                id: retailGrade.id,
                retailName: retailGrade.retailName,
                catatan: retailGrade.catatan,
                aktif: isActive,
                dibuatPada: retailGrade.dibuatPada,
                diameterMin: retailGrade.diameterMin,
                diameterMaks: retailGrade.diameterMaks,
                beratMin: retailGrade.beratMin,
                beratMaks: retailGrade.beratMaks,
                warnaOranye: retailGrade.warnaOranye
            )
        }

        do {
            try await api.setRetailGradeActive(id: id, isActive: isActive)
            await fetchRetailGrades()
        } catch {
            retailGrades = previousRetailGrades
            throw error
        }
    }

    // MARK: - DELETE

    func deleteRetailGrade(id: Int) async throws {
        try await api.deleteRetailGrade(id: id)
        try await refreshRetailGrades()
    }

    func delete(id: Int) async throws {
        try await deleteRetailGrade(id: id)
    }
}
