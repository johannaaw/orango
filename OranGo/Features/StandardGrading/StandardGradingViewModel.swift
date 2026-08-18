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

    private let repository: ThresholdRepositoryProtocol
    private let retailGradeRepository: RetailGradeRepositoryProtocol
    private let gradeRepository: GradeRepositoryProtocol

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

    init(repository: ThresholdRepositoryProtocol? = nil, retailGradeRepository: RetailGradeRepositoryProtocol? = nil, gradeRepository: GradeRepositoryProtocol? = nil) {
        self.repository = repository ?? ThresholdRepository()
        self.retailGradeRepository = retailGradeRepository ?? RetailGradeRepository()
        self.gradeRepository = gradeRepository ?? GradeRepository()
    }

    // MARK: - GET

    func fetchThresholdRules() async {
        do {
            thresholdRules = try await repository.fetchThresholdRules()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchRetailGrades() async {
        do {
            retailGrades = try await retailGradeRepository.fetchRetailGrades()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchGrades() async {
        do {
            grades = try await gradeRepository.fetchGrades()
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
        let createdRule = try await repository.createThresholdRule(rule)
        thresholdRules.append(createdRule)
    }

    func create(_ rule: ThresholdRule) async throws {
        try await createThresholdRule(rule)
    }

    // MARK: - UPDATE

    func updateThresholdRule(_ rule: ThresholdRule) async throws {
        let updatedRule = try await repository.updateThresholdRule(rule)

        if let index = thresholdRules.firstIndex(where: { $0.id == updatedRule.id }) {
            thresholdRules[index] = updatedRule
        }
    }

    func update(_ rule: ThresholdRule) async throws {
        try await updateThresholdRule(rule)
    }

    // MARK: - ACTIVATE RETAIL GRADE

    func activateRetailGrade(id: Int) async throws {
        try await retailGradeRepository.activateRetailGrade(id: id)

        await fetchRetailGrades()
    }

    // MARK: - DELETE

    func deleteThresholdRule(id: Int) async throws {
        try await repository.deleteThresholdRule(id: id)
        thresholdRules.removeAll { $0.id == id }
    }

    func delete(id: Int) async throws {
        try await deleteThresholdRule(id: id)
    }
}
