//
//  OnboardingView.swift
//  OranGo
//
//  Created by Davin P on 15/08/26.
//

// onboarding itu harus backgroundnya si dashboard, so we must integrate it

import SwiftUI

struct OnboardingView: View {
    @State private var viewModel: OnboardingViewModel
    let onOnboardingFinished: () -> Void
    
    @MainActor
    init(
        viewModel: OnboardingViewModel? = nil,
        onOnboardingFinished: @escaping () -> Void
    ) {
        _viewModel = State(initialValue: viewModel ?? OnboardingViewModel())
        self.onOnboardingFinished = onOnboardingFinished
    }

    var body: some View {
        ZStack {
            switch viewModel.step {
            case .welcome:
                OnboardingWelcomeView(onFinishedSplash: viewModel.advanceFromWelcome)
                    .transition(.opacity)

            case .features:
                OnboardingFeaturesView(onStart: viewModel.startOnboardingFeatures)
                    .transition(.opacity)

            default:
                popupFlow
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: viewModel.step)
        .onDisappear { viewModel.cancelConnection() }
    }

    // MARK: - Popup steps (Frames 3-9)

    @ViewBuilder
    private var popupFlow: some View {
        ZStack {
            OnboardingPopupBackdrop()

            OnboardingPopupCard {
                popupContent
            }
            .padding(.horizontal, 40)
        }
    }

    @ViewBuilder
    private var popupContent: some View {
        switch viewModel.step {
        case .howToUse:
            HowToUseOranGoView(onConnect: viewModel.beginDeviceConnection)

        case .wifiCheck:
            ConnectionStatusView.wifiCheck()

        case .searching:
            ConnectionStatusView.searching()

        case .connecting:
            ConnectionStatusView.connecting(deviceName: viewModel.connectingDeviceLabel)

        case .retrying:
            ConnectionStatusView.retrying()

        case .success:
            ConnectionResultView.success {
                viewModel.finishOnboarding(onOnboardingFinished)
            }

        case .failed:
            ConnectionResultView.failed {
                viewModel.retryConnection()
            }

        case .welcome, .features:
            EmptyView() // unreachable here, handled above
        }
    }
}

#Preview {
    OnboardingView(onOnboardingFinished: {})
}
