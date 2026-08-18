//
//  OutlinedGlyph.swift
//  OranGo
//
//  Draws a letter as a real outline: filled inside, stroked around the edge.
//

import SwiftUI
import CoreText

struct GlyphShape: Shape {
    let string: String
    let weight: UIFont.Weight

    func path(in rect: CGRect) -> Path {
        let layoutSize: CGFloat = 100
        let font = UIFont.systemFont(ofSize: layoutSize, weight: weight)
        let attributed = NSAttributedString(string: string, attributes: [.font: font])
        let line = CTLineCreateWithAttributedString(attributed)

        guard let runs = CTLineGetGlyphRuns(line) as? [CTRun] else { return Path() }

        let combined = CGMutablePath()
        for run in runs {
            let attributes = CTRunGetAttributes(run)
            let key = Unmanaged.passUnretained(kCTFontAttributeName).toOpaque()
            guard let raw = CFDictionaryGetValue(attributes, key) else { continue }
            let runFont = unsafeBitCast(raw, to: CTFont.self)

            let count = CTRunGetGlyphCount(run)
            guard count > 0 else { continue }

            var glyphs = [CGGlyph](repeating: 0, count: count)
            var positions = [CGPoint](repeating: .zero, count: count)
            CTRunGetGlyphs(run, CFRange(location: 0, length: count), &glyphs)
            CTRunGetPositions(run, CFRange(location: 0, length: count), &positions)

            for index in 0 ..< count {
                guard let glyph = CTFontCreatePathForGlyph(runFont, glyphs[index], nil) else { continue }
                let offset = CGAffineTransform(translationX: positions[index].x, y: positions[index].y)
                combined.addPath(glyph, transform: offset)
            }
        }

        let bounds = combined.boundingBoxOfPath
        guard bounds.width > 0, bounds.height > 0 else { return Path() }

        let scale = min(rect.width / bounds.width, rect.height / bounds.height)
        var transform = CGAffineTransform.identity
            .translatedBy(
                x: rect.midX - bounds.midX * scale,
                y: rect.midY + bounds.midY * scale
            )
            .scaledBy(x: scale, y: -scale)

        guard let fitted = combined.copy(using: &transform) else { return Path() }
        return Path(fitted)
    }
}

// MARK: - Outlined Glyph

struct OutlinedGlyph: View {
    let string: String
    let size: CGFloat
    let weight: UIFont.Weight
    let fill: Color
    var outline: Color? = nil
    var outlineWidth: CGFloat = 2

    var body: some View {
        if let outline {
            let shape = GlyphShape(string: string, weight: weight)

            ZStack {
                shape.stroke(outline, lineWidth: outlineWidth * 2)
                shape.fill(fill)
            }
            .frame(width: size * 0.72, height: size * 0.72)
            .accessibilityHidden(true)
        } else {
            Text(string)
                .font(.system(size: size, weight: swiftUIWeight))
                .foregroundStyle(fill)
                .accessibilityHidden(true)
        }
    }

    private var swiftUIWeight: Font.Weight {
        switch weight {
        case .black: return .black
        case .bold: return .bold
        case .semibold: return .semibold
        default: return .regular
        }
    }
}

// MARK: - Outlined Symbol

struct OutlinedSymbol: View {
    let systemName: String
    let size: CGFloat
    let fill: Color
    var outline: Color? = nil
    var outlineWidth: CGFloat = 2

    private let steps = 12

    var body: some View {
        ZStack {
            if let outline {
                ForEach(0 ..< steps, id: \.self) { step in
                    let angle = Double(step) / Double(steps) * 2 * .pi
                    symbol
                        .foregroundStyle(outline)
                        .offset(
                            x: cos(angle) * outlineWidth,
                            y: sin(angle) * outlineWidth
                        )
                }
            }

            symbol.foregroundStyle(fill)
        }
        .accessibilityHidden(true)
    }

    private var symbol: some View {
        Image(systemName: systemName)
            .font(.system(size: size, weight: .bold))
    }
}

// MARK: - Preview

#Preview {
    HStack(spacing: 24) {
        ForEach(["A", "B", "C"], id: \.self) { letter in
            OutlinedGlyph(
                string: letter,
                size: 52,
                weight: .black,
                fill: .white,
                outline: .black
            )
        }

        OutlinedSymbol(
            systemName: "fork.knife",
            size: 24,
            fill: .white,
            outline: .orangoGradeAmber,
            outlineWidth: 1.5
        )
    }
    .padding(40)
    .background(Color.orangoGradeYellow)
}
