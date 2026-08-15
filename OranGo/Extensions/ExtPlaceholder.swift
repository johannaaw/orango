//
//  ColorExtensions.swift
//  OranGo
//
//  Created by Davin P on 08/08/26.
//

import SwiftUI

// MARK: - Brand Colors
// TODO: Replace approximate colors with exact hex values from the design system.

extension Color {

    // MARK: Primary Brand

    /// Primary orange used for accents, buttons, active states.
    static let orangoBrandOrange = Color(red: 0.90, green: 0.45, blue: 0.10)

    /// Dark navy used for sidebar background and text headings.
    static let orangoNavy = Color(red: 0.15, green: 0.18, blue: 0.28)

    // MARK: Status

    /// Green badge color for "Aktif" status.
    static let orangoStatusGreen = Color(red: 0.20, green: 0.72, blue: 0.40)

    // MARK: Grade Segment Colors (Donut chart)

    static let gradeAColor = Color(red: 0.95, green: 0.90, blue: 0.75)   // Cream / light tan
    static let gradeBColor = Color(red: 0.45, green: 0.60, blue: 0.85)   // Blue
    static let gradeCColor = Color(red: 0.95, green: 0.75, blue: 0.20)   // Yellow / gold
    static let edibleColor = Color(red: 0.85, green: 0.85, blue: 0.80)   // Light grey-green
    static let rejectColor = Color(red: 0.90, green: 0.30, blue: 0.25)   // Red

    // MARK: Backgrounds

    /// Light grey page background.
    static let orangoPageBackground = Color(red: 0.95, green: 0.95, blue: 0.96)

    /// White card background.
    static let orangoCardBackground = Color.white

    /// Sidebar background.
    static let orangoSidebarBackground = Color.white

    // MARK: Text

    /// Primary text color.
    static let orangoTextPrimary = Color(red: 0.15, green: 0.15, blue: 0.20)

    /// Secondary / muted text.
    static let orangoTextSecondary = Color(red: 0.50, green: 0.50, blue: 0.55)

    /// Tertiary / hint text.
    static let orangoTextTertiary = Color(red: 0.70, green: 0.70, blue: 0.72)

    // MARK: Borders & Dividers

    /// Light border color for cards and table rows.
    static let orangoBorder = Color(red: 0.90, green: 0.90, blue: 0.91)

    // MARK: Insight Rank Colors

    /// Ranked insight badge colors (green, blue/teal, orange).
    static let insightRank1 = Color(red: 0.20, green: 0.72, blue: 0.40)
    static let insightRank2 = Color(red: 0.25, green: 0.55, blue: 0.82)
    static let insightRank3 = Color(red: 0.93, green: 0.58, blue: 0.15)
}

// MARK: - GradeType Color Mapping

extension GradeType {
    /// The color used for this grade in charts and badges.
    var color: Color {
        switch self {
        case .gradeA: return .gradeAColor
        case .gradeB: return .gradeBColor
        case .gradeC: return .gradeCColor
        case .edible: return .edibleColor
        case .reject: return .rejectColor
        }
    }
}

// MARK: - Date Formatting

extension Date {
    /// Formats the date as "17 Agustus 2026" using Indonesian locale.
    var formattedIndonesian: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "id_ID")
        formatter.dateFormat = "d MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Formats the date as "2 Aug, 2026".
    var formattedShort: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US")
        formatter.dateFormat = "d MMM, yyyy"
        return formatter.string(from: self)
    }
}
