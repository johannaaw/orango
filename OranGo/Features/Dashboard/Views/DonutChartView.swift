//
//  DonutChartView.swift
//  OranGo
//
//  Dashboard donut chart showing grade distribution.
//

import SwiftUI

/// A donut chart that visualizes grade distribution as colored arc segments.
/// TODO: Add patterned fills (dots, lines, crosshatch) to match the Figma design.
struct DonutChartView: View {
    let results: [GradeResult]

    /// Thickness of the donut ring.
    private let lineWidth: CGFloat = 40

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)

            ZStack {
                // Draw arc segments
                ForEach(Array(segmentData.enumerated()), id: \.offset) { index, segment in
                    DonutSegment(
                        startAngle: segment.startAngle,
                        endAngle: segment.endAngle,
                        lineWidth: lineWidth
                    )
                    .fill(segment.color)

                    // Segment label (A, B, C, etc.)
                    segmentLabel(
                        for: segment,
                        in: size
                    )
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    // MARK: - Segment Data

        private struct SegmentInfo {
            let startAngle: Angle
            let endAngle: Angle
            let midAngle: Angle
            let color: Color
            let label: String
            let isSymbol: Bool // ✅ Tambahkan properti ini
        }

        private var segmentData: [SegmentInfo] {
            let total = results.reduce(0) { $0 + $1.weightKg }
            guard total > 0 else { return [] }

            var segments: [SegmentInfo] = []
            var currentAngle: Double = -90 // Start from top

            for result in results {
                let fraction = result.weightKg / total
                let sweepDegrees = fraction * 360
                let startAngle = Angle.degrees(currentAngle)
                let endAngle = Angle.degrees(currentAngle + sweepDegrees)
                let midAngle = Angle.degrees(currentAngle + sweepDegrees / 2)

                segments.append(SegmentInfo(
                    startAngle: startAngle,
                    endAngle: endAngle,
                    midAngle: midAngle,
                    color: result.gradeType.color,
                    label: result.gradeType.chartLabel,
                    isSymbol: result.gradeType.isSymbol // ✅ Panggil dari Enum
                ))

                currentAngle += sweepDegrees
            }

            return segments
        }

        // MARK: - Label Positioning

        @ViewBuilder
        private func segmentLabel(for segment: SegmentInfo, in size: CGFloat) -> some View {
            let radius = (size / 2) - (lineWidth / 2)
            let x = radius * cos(segment.midAngle.radians)
            let y = radius * sin(segment.midAngle.radians)

            // ✅ Gunakan isSymbol untuk menentukan cara render
            if segment.isSymbol {
                Image(systemName: segment.label)
                    .font(.system(size: 16, weight: .bold)) // Ukuran bisa disesuaikan
                    .foregroundStyle(.white)
                    .offset(x: x, y: y)
            } else {
                Text(segment.label)
                    .font(.system(size: 20, weight: .black)) 
                    .foregroundStyle(.white)
                    .offset(x: x, y: y)
            }
        }
}

// MARK: - Donut Segment Shape

/// A single arc segment of the donut chart.
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
