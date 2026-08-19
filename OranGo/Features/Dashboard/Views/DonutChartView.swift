//
//  DonutChartView.swift
//  OranGo
//
//  Dashboard donut chart showing grade distribution.
//

import SwiftUI

struct DonutChartView: View {
    let results: [GradeResult]

    var selectedGrade: GradeType? = nil

    var onSelect: ((GradeType) -> Void)? = nil

    private let ringRatio: CGFloat = 0.26

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let lineWidth = size * ringRatio

            ZStack {
                if segmentData.isEmpty {
                    Circle()
                        .strokeBorder(Color.orangoRowBackground, lineWidth: lineWidth)
                        .frame(width: size, height: size)
                }

                ForEach(Array(segmentData.enumerated()), id: \.offset) { _, segment in
                    let arc = DonutSegment(
                        startAngle: segment.startAngle,
                        endAngle: segment.endAngle,
                        lineWidth: lineWidth
                    )

                    GradePatternFill(
                        appearance: segment.appearance,
                        patternAssetName: segment.patternAssetName,
                        patternScale: size
                    )
                    .frame(width: size, height: size)
                    .compositingGroup()
                    .mask {
                        arc.frame(width: size, height: size)
                    }
                    .grayscale(isDimmed(segment.gradeType) ? 1 : 0)
                    .opacity(isDimmed(segment.gradeType) ? 0.7 : 1)
                    .contentShape(arc)
                    .onTapGesture { onSelect?(segment.gradeType) }
                }

                ForEach(Array(segmentData.enumerated()), id: \.offset) { _, segment in
                    segmentLabel(for: segment, in: size, lineWidth: lineWidth)
                        .grayscale(isDimmed(segment.gradeType) ? 1 : 0)
                        .opacity(isDimmed(segment.gradeType) ? 0.7 : 1)
                        .allowsHitTesting(false)
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Distribusi hasil sorting berdasarkan grade")
        .accessibilityValue(segmentData.isEmpty ? "Belum ada hasil sorting" : accessibilitySummary)
    }

    // MARK: - Segment Data

    private struct SegmentInfo {
        let gradeType: GradeType
        let startAngle: Angle
        let endAngle: Angle
        let midAngle: Angle
        let appearance: GradeAppearance
        let patternAssetName: String?
        let label: String
        let isSymbol: Bool
    }

    private func outlinedHaloRadius(_ segment: SegmentInfo) -> CGFloat {
        segment.appearance.inkOutline == nil ? 2 : 0
    }

    private func isDimmed(_ grade: GradeType) -> Bool {
        guard let selectedGrade else { return false }
        return grade != selectedGrade
    }

    private var segmentData: [SegmentInfo] {
        let total = results.reduce(0) { $0 + $1.weightKg }
        guard total > 0 else { return [] }

        var segments: [SegmentInfo] = []
        var currentAngle: Double = -90

        for result in results {
            guard result.weightKg > 0 else { continue }

            let fraction = result.weightKg / total
            let sweepDegrees = fraction * 360

            segments.append(SegmentInfo(
                gradeType: result.gradeType,
                startAngle: .degrees(currentAngle),
                endAngle: .degrees(currentAngle + sweepDegrees),
                midAngle: .degrees(currentAngle + sweepDegrees / 2),
                appearance: result.gradeType.chartAppearance,
                patternAssetName: result.gradeType.patternAssetName,
                label: result.gradeType.chartLabel,
                isSymbol: result.gradeType.isSymbol
            ))

            currentAngle += sweepDegrees
        }

        return segments
    }

    private var accessibilitySummary: String {
        results
            .map { "\($0.gradeType.displayName) \($0.percentage.formattedWeight) persen" }
            .joined(separator: ", ")
    }

    // MARK: - Label Positioning

    @ViewBuilder
    private func segmentLabel(for segment: SegmentInfo, in size: CGFloat, lineWidth: CGFloat) -> some View {
        let radius = (size / 2) - (lineWidth / 2)
        let glyphSize = lineWidth * 0.46 * segment.gradeType.chartGlyphScale
        let sweep = abs(segment.endAngle.radians - segment.startAngle.radians)

        if sweep * radius >= glyphSize * 1.35 {
            Group {
                if segment.isSymbol {
                    Image(systemName: segment.label)
                        .font(.system(size: glyphSize, weight: .bold))
                        .foregroundStyle(segment.appearance.ink)
                        .shadow(color: segment.appearance.fill, radius: 2)
                        .shadow(color: segment.appearance.fill, radius: 2)
                } else {
                    OutlinedGlyph(
                        string: segment.label,
                        size: glyphSize,
                        weight: .black,
                        fill: segment.appearance.ink,
                        outline: segment.appearance.inkOutline,
                        outlineWidth: glyphSize * 0.12
                    )
                    .shadow(color: segment.appearance.fill, radius: outlinedHaloRadius(segment))
                    .shadow(color: segment.appearance.fill, radius: outlinedHaloRadius(segment))
                }
            }
            .offset(
                x: radius * cos(segment.midAngle.radians),
                y: radius * sin(segment.midAngle.radians)
            )
        }
    }
}

// MARK: - Donut Segment Shape

private struct DonutSegment: Shape {
    let startAngle: Angle
    let endAngle: Angle
    let lineWidth: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2 - lineWidth / 2

        path.addArc(
            center: center,
            radius: radius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        return path.strokedPath(StrokeStyle(lineWidth: lineWidth, lineCap: .butt))
    }
}

// MARK: - Preview

#Preview {
    DonutChartView(results: GradeResult.sampleResults)
        .frame(width: 200, height: 200)
        .padding()
}
