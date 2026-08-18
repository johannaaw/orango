//
//  OnboardingViewModel.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

import Foundation

@MainActor
@Observable
final class OnboardingViewModel {

    // MARK: - Flow step

    enum Step: Equatable {
        case welcome        // Onboarding-1 (full screen)
        case features       // Onboarding-2 (full screen)
        case howToUse       // Popup 3
        case wifiCheck      // Popup 4
        case searching      // Popup 5
        case connecting     // Popup 6
        case success        // Popup 7
        case failed         // Popup 8
        case retrying       // Popup 9
    }

    /// Popup steps render inside the floating card; welcome/features are full screen.
    var isPopupStep: Bool {
        switch step {
        case .welcome, .features: return false
        default: return true
        }
    }

    // MARK: - Published state

    private(set) var step: Step = .welcome
    private(set) var discoveredDeviceName: String?
    private(set) var isConnecting: Bool = false

    // MARK: - Dependencies

    private let deviceService: DeviceConnectionServicing
    private var connectionTask: Task<Void, Never>?

    init(deviceService: DeviceConnectionServicing? = nil) {
        self.deviceService = deviceService ?? DeviceConnectionService()
    }

    // MARK: - Navigation (called from Views)

    /// Frame 1 -> Frame 2. Call this after the splash delay, or on tap.
    func advanceFromWelcome() {
        guard step == .welcome else { return }
        step = .features
    }

    /// Frame 2 "Mulai" button -> Frame 3.
    func startOnboardingFeatures() {
        guard step == .features else { return }
        step = .howToUse
    }

    /// Frame 3 "Hubungkan OranGo" button -> begins Wifi check -> Searching -> Connecting.
    func beginDeviceConnection() {
        step = .wifiCheck
        runConnectionFlow(isRetry: false)
    }

    /// Frame 8 "Coba hubungkan kembali" button -> Frame 9, then success/fail again.
    func retryConnection() {
        step = .retrying
        runConnectionFlow(isRetry: true)
    }

    /// Stops any in-flight connection attempt; called when the flow leaves the screen.
    func cancelConnection() {
        connectionTask?.cancel()
        connectionTask = nil
        isConnecting = false
    }

    /// Frame 7 "Mulai memantau sorting" button. Call this to leave the onboarding flow.
    func finishOnboarding(_ completion: () -> Void) {
        guard step == .success else { return }
        completion()
    }

    // MARK: - Connection flow

    private func runConnectionFlow(isRetry: Bool) {
        connectionTask?.cancel()
        isConnecting = true

        connectionTask = Task { [weak self] in
            guard let self else { return }
            defer { Task { @MainActor in self.isConnecting = false } }

            do {
                if !isRetry {
                    try await Task.sleep(nanoseconds: 1_200_000_000)
                    guard !Task.isCancelled else { return }
                    await MainActor.run { self.step = .searching }
                }

                let device = try await deviceService.discoverDevice()
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.discoveredDeviceName = device
                    self.step = isRetry ? .retrying : .connecting
                }

                let didConnect = try await deviceService.connect(to: device)
                guard !Task.isCancelled else { return }

                await MainActor.run {
                    self.step = didConnect ? .success : .failed
                }
            } catch {
                guard !Task.isCancelled else { return }
                await MainActor.run { self.step = .failed }
            }
        }
    }

    /// Label used in "Menghubungkan dengan <device> ..." copy.
    var connectingDeviceLabel: String {
        discoveredDeviceName ?? "OranGo"
    }
}
