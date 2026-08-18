//
//  ThresholdRepository.swift
//  OranGo
//
//  Created by Johanna Angel on 17/08/26.
//
import Foundation

protocol ThresholdRepositoryProtocol {
    func fetchThresholdRules() async throws -> [ThresholdRule]
    func createThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule
    func updateThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule
    func deleteThresholdRule(id: Int) async throws
}

final class ThresholdRepository: ThresholdRepositoryProtocol {
    private let apiService: ThresholdRuleAPIServiceProtocol

    init(apiService: ThresholdRuleAPIServiceProtocol = APIService.shared) {
        self.apiService = apiService
    }

    func fetchThresholdRules() async throws -> [ThresholdRule] {
        try await apiService.fetchThresholdRules()
    }

    func createThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule {
        try await apiService.createThresholdRule(rule)
    }

    func updateThresholdRule(_ rule: ThresholdRule) async throws -> ThresholdRule {
        try await apiService.updateThresholdRule(rule)
    }

    func deleteThresholdRule(id: Int) async throws {
        try await apiService.deleteThresholdRule(id: id)
    }
}
