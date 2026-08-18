//
//  DashboardViewModel.swift
//  OranGo
//
//  Created by Davin P on 07/08/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class DashboardViewModel {
    // MARK: - Data Properties
    var batches: [Batch] = []
    var machines: [Machine] = []
    var grades: [Grade] = []
    var retailGrades: [RetailGrade] = []
    
    var isLoading = false
    var errorMessage: String?

    // MARK: - Repositories
    private let batchRepository: BatchRepositoryProtocol
    private let machineRepository: MachineRepositoryProtocol
    private let gradeRepository: GradeRepositoryProtocol
    private let retailGradeRepository: RetailGradeRepositoryProtocol

    // MARK: - Computed Properties
    
    var machineNameById: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: machines.map {
                ($0.id, $0.machineName)
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

    var retailGradeNameById: [Int: String] {
        Dictionary(
            uniqueKeysWithValues: retailGrades.map {
                ($0.id, $0.retailName)
            }
        )
    }

    // MARK: - Init

    init(
        batchRepository: BatchRepositoryProtocol? = nil,
        machineRepository: MachineRepositoryProtocol? = nil,
        gradeRepository: GradeRepositoryProtocol? = nil,
        retailGradeRepository: RetailGradeRepositoryProtocol? = nil
    ) {
        self.batchRepository = batchRepository ?? BatchRepository()
        self.machineRepository = machineRepository ?? MachineRepository()
        self.gradeRepository = gradeRepository ?? GradeRepository()
        self.retailGradeRepository = retailGradeRepository ?? RetailGradeRepository()
    }

    // MARK: - Fetch Methods

    func fetchBatches() async {
        do {
            batches = try await batchRepository.fetchBatches()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMachines() async {
        do {
            machines = try await machineRepository.fetchMachines()
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

    func fetchRetailGrades() async {
        do {
            retailGrades = try await retailGradeRepository.fetchRetailGrades()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - Load All Dashboard Data

    func loadDashboardData() async {
        isLoading = true
        errorMessage = nil

        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                await self.fetchBatches()
            }

            group.addTask {
                await self.fetchMachines()
            }

            group.addTask {
                await self.fetchGrades()
            }

            group.addTask {
                await self.fetchRetailGrades()
            }
        }

        isLoading = false
    }

    // MARK: - Create Methods

    func createBatch(_ batch: Batch) async throws {
        let createdBatch = try await batchRepository.createBatch(batch)
        batches.append(createdBatch)
    }

    func createMachine(_ machine: Machine) async throws {
        let createdMachine = try await machineRepository.createMachine(machine)
        machines.append(createdMachine)
    }
}
