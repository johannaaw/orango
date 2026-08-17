//
//  ColorExtensions.swift
//  OranGo
//
//  Created by Davin P on 08/08/26.
//

import SwiftUI

// MARK: - Brand Colors

extension Color {
    // MARK: Primary Brand

    static let orangoBrandOrange = Color.orangoOrange

    static let orangoNavy = Color(red: 0.15, green: 0.18, blue: 0.28)

    // MARK: Status

    static let orangoStatusGreen = Color(red: 0.36, green: 0.75, blue: 0.29)

    // MARK: Grade Palette

    static let orangoGradeBlue = Color(red: 0.16, green: 0.42, blue: 0.85)

    static let orangoGradeYellow = Color(red: 0.95, green: 0.77, blue: 0.07)

    static let orangoGradeAmber = Color(red: 0.94, green: 0.66, blue: 0.20)

    static let orangoGradeRed = Color(red: 0.90, green: 0.20, blue: 0.16)

    static let orangoDangerRed = Color(red: 0.80, green: 0.25, blue: 0.25)

    static let orangoGradeInk = Color(red: 0.10, green: 0.10, blue: 0.12)

    // MARK: Backgrounds

    static let orangoPageBackground = Color(red: 0.94, green: 0.94, blue: 0.95)

    static let orangoCardBackground = Color.white

    static let orangoSidebarBackground = Color.white

    static let orangoRowBackground = Color(red: 0.96, green: 0.96, blue: 0.97)

    static let orangoRowHighlight = Color(red: 0.99, green: 0.94, blue: 0.88)

    // MARK: Text

    static let orangoTextPrimary = Color(red: 0.15, green: 0.15, blue: 0.20)

    static let orangoTextSecondary = Color(red: 0.50, green: 0.50, blue: 0.55)

    static let orangoTextTertiary = Color(red: 0.70, green: 0.70, blue: 0.72)

    // MARK: Borders & Dividers

    static let orangoBorder = Color(red: 0.90, green: 0.90, blue: 0.91)
}

// MARK: - Grade Appearance

struct GradeAppearance {
    let fill: Color
    let patternColor: Color?
    let ink: Color
    let border: Color?
    var inkOutline: Color? = nil
}

extension GradeType {
    var patternAssetName: String? {
        switch self {
        case .gradeA: return "pattern-polkadot"
        case .gradeB: return "pattern-angled-lines"
        case .gradeC: return "pattern-squares-plaid"
        case .edible: return "pattern-horizontal-lines"
        case .reject: return nil
        }
    }

    var chartAppearance: GradeAppearance {
        switch self {
        case .gradeA:
            return GradeAppearance(fill: .white, patternColor: .orangoGradeInk,
                                   ink: .white, border: nil,
                                   inkOutline: .orangoGradeInk)
        case .gradeB:
            return GradeAppearance(fill: .orangoGradeBlue, patternColor: .white,
                                   ink: .white, border: nil,
                                   inkOutline: .orangoGradeBlue)
        case .gradeC:
            return GradeAppearance(fill: .orangoGradeYellow, patternColor: nil,
                                   ink: .white, border: nil,
                                   inkOutline: .orangoGradeYellow)
        case .edible:
            return GradeAppearance(fill: .orangoGradeAmber, patternColor: .white,
                                   ink: .white, border: nil)
        case .reject:
            return GradeAppearance(fill: .orangoGradeRed, patternColor: nil,
                                   ink: .white, border: nil)
        }
    }

    var chartGlyphScale: CGFloat {
        switch self {
        case .reject: return 0.8
        default: return 1
        }
    }

    var selectionTint: Color {
        switch self {
        case .gradeA: return .orangoRowBackground
        default: return chartAppearance.fill.opacity(0.12)
        }
    }

    var badgeAppearance: GradeAppearance {
        switch self {
        case .gradeA:
            return GradeAppearance(fill: .white, patternColor: .orangoGradeInk,
                                   ink: .white, border: .orangoGradeInk,
                                   inkOutline: .orangoGradeInk)
        case .gradeB:
            return GradeAppearance(fill: .orangoGradeBlue, patternColor: .white,
                                   ink: .white, border: nil,
                                   inkOutline: .orangoGradeBlue)
        case .gradeC:
            return GradeAppearance(fill: .orangoGradeYellow, patternColor: nil,
                                   ink: .white, border: nil,
                                   inkOutline: .orangoGradeYellow)
        case .edible:
            return GradeAppearance(fill: .white, patternColor: .orangoGradeAmber,
                                   ink: .white, border: .orangoGradeAmber,
                                   inkOutline: .orangoGradeAmber)
        case .reject:
            return GradeAppearance(fill: .orangoGradeRed, patternColor: nil,
                                   ink: .white, border: nil)
        }
    }
}

// MARK: - Number Formatting

extension Double {
    var formattedWeight: String {
        Self.weightFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    private static let weightFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "id_ID")
        formatter.minimumFractionDigits = 1
        formatter.maximumFractionDigits = 1
        return formatter
    }()
}

extension Int {
    var formattedCount: String {
        Self.countFormatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }

    private static let countFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = Locale(identifier: "id_ID")
        formatter.maximumFractionDigits = 0
        return formatter
    }()
}

// MARK: - Date Formatting

extension Date {
    var formattedIndonesian: String {
        Self.indonesianFormatter.string(from: self)
    }

    private static let indonesianFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.setLocalizedDateFormatFromTemplate("d MMMM yyyy")
        return formatter
    }()
}

// MARK: - Collection Helpers

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
