//
//  ConnectionStatusView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//


//  Shared body for Frames 4 (wifi check), 5 (searching), 6 (connecting),
//  and 9 (retrying). Only the message, center icon, and tint differ —
//  the CTA button is always present but disabled while connecting.
//

import SwiftUI

struct ConnectionStatusView: View {
    let message: String
    var centerSymbol: String?
    var tint: Color

    var body: some View {
        VStack(spacing: 36) {
            ConnectionIllustrationView(centerSymbol: centerSymbol, tint: tint)

            Text(message)
                .font(.system(size: 24, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(.primary)

            // button "Mulai memantau sorting" become tappable once connection actually succeeds (see ConnectionResultView).
            OnboardingButton(title: "Mulai memantau sorting", isEnabled: false) {}
        }
        .padding(44)
    }
}

extension ConnectionStatusView {
    static func wifiCheck() -> ConnectionStatusView {
        ConnectionStatusView(
            message: "Pastikan Anda berada dalam jaringan Wi-Fi yang sama dengan alat sortir OranGo.",
            centerSymbol: nil,
            tint: .oranGoOrange
        )
    }

    static func searching() -> ConnectionStatusView {
        ConnectionStatusView(
            message: "Mencari alat sortir OranGo ...",
            centerSymbol: "magnifyingglass",
            tint: .yellow
        )
    }

    static func connecting(deviceName: String) -> ConnectionStatusView {
        ConnectionStatusView(
            message: "Menghubungkan dengan\n\(deviceName) ...",
            centerSymbol: "wifi",
            tint: .blue
        )
    }

    static func retrying() -> ConnectionStatusView {
        ConnectionStatusView(
            message: "Mencoba menghubungkan kembali...",
            centerSymbol: "wifi",
            tint: .blue
        )
    }
}

#Preview {
    ConnectionStatusView.connecting(deviceName: "OranGo-1312")
//    ConnectionStatusView.searching()
//    ConnectionStatusView.retrying()
    ConnectionStatusView.wifiCheck()
    
}
