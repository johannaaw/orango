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
    var thresholdRules: [ThresholdRule] = []
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

    var gradeNameById: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: grades.map {
                ($0.id, $0.kelasGrading)
            }
        )
    }

    // MARK: - GET

    func fetchThresholdRules() async {
        do {
            thresholdRules = try await api.thresholdRules()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRetailGrades() async {
        do {
            retailGrades = try await api.retailGrades()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchGrades() async {
        do {
            grades = try await api.grades()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadAll() async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchThresholdRules()
            }

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

    func createThresholdRule(_ rule: ThresholdRule) async throws {
        let createdRule = try await api.createThresholdRule(rule)
        thresholdRules.append(createdRule)
    }

    func create(_ rule: ThresholdRule) async throws {
        try await createThresholdRule(rule)
    }

    // MARK: - UPDATE

    func updateThresholdRule(_ rule: ThresholdRule) async throws {
        let updatedRule = try await api.updateThresholdRule(rule)

        if let index = thresholdRules.firstIndex(where: { $0.id == updatedRule.id }) {
            thresholdRules[index] = updatedRule
        }
    }

    func update(_ rule: ThresholdRule) async throws {
        try await updateThresholdRule(rule)
    }

    // MARK: - ACTIVATE RETAIL GRADE

    func activateRetailGrade(id: Int) async throws {
        try await api.activateRetailGrade(id: id)

        await fetchRetailGrades()
    }

    // MARK: - DELETE

    func deleteThresholdRule(id: Int) async throws {
        try await api.deleteThresholdRule(id: id)
        thresholdRules.removeAll { $0.id == id }
    }

    func delete(id: Int) async throws {
        try await deleteThresholdRule(id: id)
    }
}
