//
//  DeviceConnectionService.swift
//  OranGo
//
//  Finds the sorting machine the Onboarding flow connects to.
//

import Foundation

protocol DeviceConnectionServicing {
    func discoverDevice() async throws -> String
    func connect(to deviceName: String) async throws -> Bool
}

enum DeviceConnectionError: LocalizedError {
    case deviceNotFound

    var errorDescription: String? {
        switch self {
        case .deviceNotFound:
            return "Tidak ada mesin sorting yang terdaftar di server."
        }
    }
}

final class DeviceConnectionService: DeviceConnectionServicing {
    private let api = OranGoAPI.shared

    func discoverDevice() async throws -> String {
        let machines = try await api.machines()
        guard let machine = machines.first(where: \.isConnected) ?? machines.first else {
            throw DeviceConnectionError.deviceNotFound
        }
        return machine.machineName
    }

    /// Connection is owned by the machine itself; the app reports what the server says.
    func connect(to deviceName: String) async throws -> Bool {
        let machines = try await api.machines()
        return machines.first { $0.machineName == deviceName }?.isConnected ?? false
    }
}
