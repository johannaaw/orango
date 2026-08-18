//
//  ConnectionIllustrationView.swift
//  OranGo
//
//  Created by Davin P on 17/08/26.
//

import SwiftUI

struct ConnectionIllustrationView: View {
    var centerSymbol: String?
    var tint: Color

    var body: some View {
        HStack(spacing: 28) {
            Image("ipad-orango")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 112)

            CenterIndicator(symbol: centerSymbol, tint: tint)
                .frame(width: 90, height: 40)

            Image("physical-orango")
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 112)
        }
    }
}

/// Row of dots (matching the dashed-line look in the mockup) with an
/// optional status icon layered on top.
private struct CenterIndicator: View {
    let symbol: String?
    let tint: Color

    private let dotCount = 8

    var body: some View {
        ZStack {
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { index in
                    let isEndpoint = index == 0 || index == dotCount - 1
                    Circle()
                        .fill(tint.opacity(isEndpoint ? 0.9 : 0.5))
                        .frame(width: isEndpoint ? 10 : 6, height: isEndpoint ? 10 : 6)
                }
            }

            if let symbol {
                Image(systemName: symbol)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color(.systemBackground)))
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        ConnectionIllustrationView(centerSymbol: nil, tint: .orangoBrandOrange)
        ConnectionIllustrationView(centerSymbol: "magnifyingglass", tint: .yellow)
        ConnectionIllustrationView(centerSymbol: "wifi", tint: .blue)
    }
    .padding(40)
}
