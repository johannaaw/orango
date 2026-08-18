//
//  DeviceConnectionService.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

//  Handles discovery + connection to a physical OranGo sorting device.
//  This is a placeholder implementation (simulated delays) so the
//  Onboarding flow is fully functional end-to-end. Replace the bodies of
//  `discoverDevice()` and `connect(to:)` with real WiFi/BLE/MQTT discovery
//  logic once that layer is ready.
//

import Foundation

protocol DeviceConnectionServicing {
    /// Looks for a nearby OranGo device on the local network and returns its name.
    func discoverDevice() async throws -> String

    /// Attempts to connect to a previously discovered device.
    /// Returns `true` on success, `false` on a "graceful" failure (e.g. device didn't respond), throws only for unexpected errors.
    func connect(to deviceName: String) async throws -> Bool
}

enum DeviceConnectionError: Error {
    case deviceNotFound
    case connectionTimedOut
}

final class DeviceConnectionService: DeviceConnectionServicing {

    func discoverDevice() async throws -> String {
        // simulated network discovery delay.
        try await Task.sleep(nanoseconds: 1_600_000_000)
        return "OranGo-1312"
    }

    func connect(to deviceName: String) async throws -> Bool {
        // simulated handshake delay.
        try await Task.sleep(nanoseconds: 2_000_000_000)
        return true
    }
}
