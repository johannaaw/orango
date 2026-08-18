import Foundation

protocol MachineRepositoryProtocol {
    func fetchMachines() async throws -> [Machine]
    func createMachine(_ machine: Machine) async throws -> Machine
}

final class MachineRepository: MachineRepositoryProtocol {
    private let apiService: MachineAPIServiceProtocol

    init(apiService: MachineAPIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    func fetchMachines() async throws -> [Machine] {
        try await apiService.fetchMachines()
    }

    func createMachine(_ machine: Machine) async throws -> Machine {
        try await apiService.createMachine(machine)
    }
}
