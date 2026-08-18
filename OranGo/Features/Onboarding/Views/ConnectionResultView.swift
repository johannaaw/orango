//
//  ConnectionResultView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//


//  Shared body for Frame 7 (success) and Frame 8 (failed).
//  Both are: big SF Symbol status icon + bold message + a single active CTA.
//

import SwiftUI

struct ConnectionResultView: View {
    let symbol: String
    let tint: Color
    let message: String
    let buttonTitle: String
    let action: () -> Void

    var body: some View {
        VStack(spacing: 36) {
            Image(systemName: symbol)
                .font(.system(size: 84, weight: .regular))
                .foregroundStyle(tint)

            Text(message)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)

            OnboardingButton(title: buttonTitle, isEnabled: true, action: action)
        }
        .padding(44)
    }
}

extension ConnectionResultView {
    static func success(action: @escaping () -> Void) -> ConnectionResultView {
        ConnectionResultView(
            symbol: "checkmark.circle",
            tint: .green,
            message: "OranGo berhasil terhubung",
            buttonTitle: "Mulai memantau sorting",
            action: action
        )
    }
    static func failed(action: @escaping () -> Void) -> ConnectionResultView {
        ConnectionResultView(
            symbol: "wifi.slash",
            tint: .red,
            message: "OranGo gagal terhubung,\nperiksa kembali koneksi Anda!",
            buttonTitle: "Coba hubungkan kembali",
            action: action
        )
    }
}

#Preview {
    ConnectionResultView.success(action: {})
    ConnectionResultView.failed(action: {})
}
