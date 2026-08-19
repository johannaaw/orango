//
//  InsightService.swift
//  OranGo
//
//  Harvest insights, written on-device by Foundation Models when the hardware
//  supports it and derived arithmetically when it does not.
//

import Foundation
import FoundationModels

// MARK: - Snapshot

/// The same period one step back, so an insight can talk about movement rather than level.
struct InsightComparison: Equatable {
    /// How to name it in the sentence: "kemarin", "minggu sebelumnya", …
    let label: String
    let totalWeightKg: Double
    let totalCount: Int
    let rejectPercentage: Double
    let retailGradePercentage: Double
}

/// Why fruit failed the active standard, measured against that standard's own thresholds.
/// This is the part the dashboard cannot show: the chart says how many failed, not why.
struct RejectBreakdown: Equatable {
    let standardName: String
    let failedCount: Int

    let byDiameter: Int
    let byWeight: Int
    let byColour: Int
    let byShape: Int

    /// Failed exactly one criterion, and only barely — the fruit worth chasing, because a
    /// small change upstream converts it into saleable grade.
    let nearMissCount: Int
    let nearMissCause: String?

    var dominantCause: (name: String, count: Int)? {
        let causes = [
            ("diameter", byDiameter),
            ("berat", byWeight),
            ("warna", byColour),
            ("bentuk", byShape),
        ]
        guard let top = causes.max(by: { $0.1 < $1.1 }), top.1 > 0 else { return nil }
        return top
    }
}

/// The figures an insight can be drawn from.
struct InsightSnapshot: Equatable {
    let periodLabel: String
    let totalWeightKg: Double
    let totalCount: Int
    let totalBatch: Int
    let gradeResults: [GradeResult]

    var comparison: InsightComparison? = nil
    var rejectBreakdown: RejectBreakdown? = nil
    /// Fruit per hour across the period, once there is enough of a span to mean anything.
    var throughputPerHour: Double? = nil

    var hasData: Bool { totalCount > 0 }

    /// Share of fruit that met the retail standard (A, B or C).
    var retailGradePercentage: Double {
        gradeResults
            .filter { [.gradeA, .gradeB, .gradeC].contains($0.gradeType) }
            .reduce(0) { $0 + $1.percentage }
    }

    var rejectPercentage: Double {
        gradeResults.first { $0.gradeType == .reject }?.percentage ?? 0
    }

    /// Insights are three rounded sentences, so only the rounded figures can change them.
    /// Comparing on this keeps a redraw from being mistaken for new information — and,
    /// just as importantly, lets real new information through, which comparing on the
    /// period label alone did not.
    var signature: String {
        let grades = gradeResults
            .map { "\($0.gradeType.rawValue):\(Int($0.percentage.rounded()))" }
            .joined(separator: ",")

        return "\(periodLabel)|\(Int(totalWeightKg.rounded()))|\(totalCount)|\(totalBatch)|\(grades)"
            + "|\(rejectBreakdown?.dominantCause?.name ?? "-")|\(comparison?.label ?? "-")"
    }

    static func == (lhs: InsightSnapshot, rhs: InsightSnapshot) -> Bool {
        lhs.signature == rhs.signature
    }
}

// MARK: - Insights Model

/// Drives the insight card on both the Dashboard and Batch Detail: decides when the model
/// is worth waking, and holds what it wrote.
@MainActor
@Observable
final class InsightsModel {
    private(set) var insights: [HarvestInsight] = []
    private(set) var notice: String?
    private(set) var isGenerating = false

    /// The snapshot the insights on screen were written from.
    private var generatedFrom: InsightSnapshot?
    private var generatedAt: Date?

    /// A running batch produces a scan every few seconds. Without a floor, the model would
    /// be asked to rewrite the same three lines on every poll.
    private static let cooldown: TimeInterval = 45

    func refresh(for snapshot: InsightSnapshot) async {
        guard !isGenerating else { return }

        guard snapshot.hasData else {
            insights = []
            notice = "Menunggu buah pertama disortir…"
            generatedFrom = nil
            generatedAt = nil
            return
        }

        if let generatedFrom {
            guard snapshot != generatedFrom else { return }

            // A different period deserves an answer straight away. More data for the period
            // already on screen can wait — the next poll brings it back here.
            if snapshot.periodLabel == generatedFrom.periodLabel,
               let generatedAt,
               Date.now.timeIntervalSince(generatedAt) < Self.cooldown {
                return
            }
        }

        isGenerating = true
        defer { isGenerating = false }

        let result = await InsightService.insights(for: snapshot)

        // Figures may have moved on while the model was writing; record what it described,
        // not what is current.
        generatedFrom = snapshot
        generatedAt = .now
        insights = result.insights

        if case .computed(let reason) = result.source {
            notice = reason
        } else {
            notice = nil
        }
    }
}

// MARK: - Generated Shape

/// Guided-generation target, so the model returns exactly three usable lines
/// instead of free-form prose we would have to parse.
@Generable
private struct GeneratedInsights {
    @Guide(description: "Three short observations in Indonesian Language, maximal 200 characters", .count(3))
    let items: [String]
}

// MARK: - Service

@MainActor
enum InsightService {

    /// Why the on-device model could not be used, for showing in the UI.
    enum Source: Equatable {
        case model
        case computed(reason: String?)
    }

    /// Last failure from the on-device model, kept so the UI can show why the
    /// arithmetic fallback was used instead of silently swapping it in.
    private(set) static var lastModelError: String?

    struct Result {
        let insights: [HarvestInsight]
        let source: Source
    }

    static func insights(for snapshot: InsightSnapshot) async -> Result {
        guard snapshot.hasData else {
            return Result(insights: [], source: .computed(reason: nil))
        }

        switch SystemLanguageModel.default.availability {
        case .available:
            do {
                let generated = try await generate(snapshot)
                lastModelError = nil
                return Result(insights: generated, source: .model)
            } catch {
                lastModelError = String(describing: error)
                
                let reasonMessage: String
                if error.localizedDescription.contains("unsupported language") {
                    reasonMessage = "Bahasa atau Wilayah perangkat belum didukung oleh Apple Intelligence"
                } else {
                    reasonMessage = "Model gagal: \(error.localizedDescription)"
                }

                return Result(
                    insights: computed(snapshot),
                    source: .computed(reason: reasonMessage)
                )
            }

        case .unavailable(let reason):
            return Result(insights: computed(snapshot), source: .computed(reason: describe(reason)))
        }
    }

    // MARK: On-device model

    struct EmptyGenerationError: LocalizedError {
        var errorDescription: String? { "Model tidak mengembalikan teks apa pun." }
    }

    // MARK: - On-device Model Implementation

    private static func generate(_ snapshot: InsightSnapshot) async throws -> [HarvestInsight] {
        let session = LanguageModelSession(
            instructions: """
            You advise the operator of a citrus sorting line, mid-shift. The operator is
            already looking at a dashboard showing every grade's weight, count and share.

            Write exactly 3 insights. Each must take a DIFFERENT one of these angles:
              A. MOVEMENT — what changed against the comparison period, and what it implies.
              B. CAUSE — which threshold most fruit is failing, and by how much.
              C. ACTION — one concrete thing to do or check within the next hour.

            Hard rules:
            1. Never restate a figure the dashboard already shows on its own. "Grade A
               mencapai 27%" is forbidden. A percentage may appear ONLY as part of a change
               ("naik dari 7% ke 11%"), a cause ("72% gagal di warna"), or a recommendation.
            2. Never praise or grade the result. No "bagus", "sudah baik", "perlu ditinjau"
               without saying what specifically to do about it.
            3. Use ONLY the numbers supplied. If the data for an angle is missing, replace it
               with a second ACTION insight rather than estimating or inventing a trend.
            4. NEVER write "poin" or "percentage point". Every rate is expressed as a
               percentage. To describe a change between two rates, state BOTH values —
               "naik dari 7% ke 11%". For a quantity such as weight, a relative percentage
               is fine — "volume turun 12%".
            5. Each sentence strictly under 90 characters.
            6. Write in Indonesian (Bahasa Indonesia), addressing the operator as "Anda"
               or with an imperative. Be specific, not encouraging.

            Example of a BAD insight (never write this): "Grade A mendominasi 27,8% dari
            total berat, kualitas panen tergolong baik."
            Example of a GOOD insight: "Reject naik dari 7% ke 11% sejak kemarin, hampir
            semua gagal di warna."
            """
        )

        let response = try await session.respond(
            to: prompt(for: snapshot),
            generating: GeneratedInsights.self
        )
        
        let items = response.content.items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !items.isEmpty else { throw EmptyGenerationError() }

        return items.enumerated().map { index, text in
            HarvestInsight(rank: index + 1, description: text)
        }
    }

    /// Every comparison and ratio is worked out here in Swift. The model is asked to phrase
    /// conclusions, never to do arithmetic — that is where it used to drift.
    private static func prompt(for snapshot: InsightSnapshot) -> String {
        var sections: [String] = []

        // Kept in English so Apple's language detector does not reject the prompt.
        sections.append("""
        PERIOD: \(snapshot.periodLabel)
        Processed: \(snapshot.totalWeightKg.formattedWeight) kg across \(snapshot.totalCount) fruit, \(snapshot.totalBatch) finished batches.
        Met retail standard (A/B/C): \(snapshot.retailGradePercentage.formattedWeight)%. Rejected: \(snapshot.rejectPercentage.formattedWeight)%.
        """)

        // MOVEMENT. Rates are handed over as before/after pairs, never as a difference, so
        // there is no "points" figure in the prompt for the model to reach for.
        if let previous = snapshot.comparison {
            sections.append("""
            MOVEMENT vs \(previous.label) (call it "\(previous.label)" in the sentence):
            - Volume: was \(previous.totalWeightKg.formattedWeight) kg, now \(snapshot.totalWeightKg.formattedWeight) kg (\(relativeChange(from: previous.totalWeightKg, to: snapshot.totalWeightKg)))
            - Fruit count: was \(previous.totalCount), now \(snapshot.totalCount)
            - Reject rate: was \(previous.rejectPercentage.formattedWeight)%, now \(snapshot.rejectPercentage.formattedWeight)%
            - Retail-grade rate: was \(previous.retailGradePercentage.formattedWeight)%, now \(snapshot.retailGradePercentage.formattedWeight)%
            Describe rate changes as "dari X% ke Y%". Do not subtract two rates.
            """)
        } else {
            sections.append("MOVEMENT: no comparable earlier period. Do not invent a trend.")
        }

        // CAUSE
        if let breakdown = snapshot.rejectBreakdown, breakdown.failedCount > 0 {
            var lines = [
                "CAUSE — \(breakdown.failedCount) fruit missed standard \"\(breakdown.standardName)\":",
                "- diameter out of range: \(breakdown.byDiameter)",
                "- weight out of range: \(breakdown.byWeight)",
                "- orange colour below threshold: \(breakdown.byColour)",
                "- irregular shape: \(breakdown.byShape)",
            ]

            if breakdown.nearMissCount > 0, let cause = breakdown.nearMissCause {
                lines.append(
                    "- \(breakdown.nearMissCount) of them failed ONLY on \(cause), and only barely — these are recoverable."
                )
            }
            sections.append(lines.joined(separator: "\n"))
        } else {
            sections.append("CAUSE: no per-criterion data available. Do not guess a cause.")
        }

        // THROUGHPUT, for the ACTION angle
        if let throughput = snapshot.throughputPerHour {
            sections.append("THROUGHPUT: \(throughput.formattedWeight) fruit per hour.")
        }

        sections.append("""
        TASK: write the 3 insights following the rules — one MOVEMENT, one CAUSE, one ACTION.
        Do not repeat any grade share on its own.
        """)

        return sections.joined(separator: "\n\n")
    }

    /// Relative change of a quantity, which is safe to state as a percentage. Rates are
    /// never put through this — the difference of two percentages is not a percentage.
    private static func relativeChange(from old: Double, to new: Double) -> String {
        guard old > 0 else { return "no earlier figure" }

        let percent = (new - old) / old * 100
        let direction = percent >= 0 ? "up" : "down"
        return "\(direction) \(abs(percent).formattedWeight)%"
    }
    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> String {
        switch reason {
        case .deviceNotEligible:
            return "Perangkat ini belum mendukung Apple Intelligence"
        case .appleIntelligenceNotEnabled:
            return "Apple Intelligence belum diaktifkan di Pengaturan"
        case .modelNotReady:
            return "Model sedang diunduh, coba lagi nanti"
        @unknown default:
            return "Model bahasa tidak tersedia"
        }
    }

    // MARK: Arithmetic fallback

    /// Runs everywhere, including the Simulator, which has no Apple Intelligence.
    /// Follows the same three angles as the prompt, so the screen reads the same whether or
    /// not the device can run the model.
    private static func computed(_ snapshot: InsightSnapshot) -> [HarvestInsight] {
        var lines: [String] = []

        // MOVEMENT
        if let previous = snapshot.comparison {
            let rejectDelta = snapshot.rejectPercentage - previous.rejectPercentage

            if abs(rejectDelta) >= 1 {
                // Both rates are named, so the sentence carries no ambiguous "points" figure.
                let direction = rejectDelta > 0 ? "naik" : "turun"
                lines.append(
                    "Reject \(direction) dari \(previous.rejectPercentage.formattedWeight)% ke \(snapshot.rejectPercentage.formattedWeight)% sejak \(previous.label)."
                )
            } else if previous.totalWeightKg > 0 {
                let percent = (snapshot.totalWeightKg - previous.totalWeightKg) / previous.totalWeightKg * 100
                let direction = percent >= 0 ? "naik" : "turun"
                lines.append(
                    "Volume \(direction) \(abs(percent).formattedWeight)% sejak \(previous.label), reject stabil."
                )
            }
        }

        // CAUSE
        if let breakdown = snapshot.rejectBreakdown,
           breakdown.failedCount > 0,
           let cause = breakdown.dominantCause {
            let share = Double(cause.count) / Double(breakdown.failedCount) * 100
            lines.append("\(share.formattedWeight)% buah gagal di \(cause.name), bukan kriteria lain.")
        }

        // ACTION
        if let breakdown = snapshot.rejectBreakdown,
           breakdown.nearMissCount > 0,
           let cause = breakdown.nearMissCause {
            lines.append("\(breakdown.nearMissCount) buah gagal tipis di \(cause) — tinjau ambangnya.")
        } else if let throughput = snapshot.throughputPerHour {
            lines.append("Laju \(throughput.formattedWeight) buah/jam; periksa mesin bila melambat.")
        } else if snapshot.totalBatch > 0 {
            let perBatch = snapshot.totalWeightKg / Double(snapshot.totalBatch)
            lines.append("Rata-rata \(perBatch.formattedWeight) kg per batch dari \(snapshot.totalBatch) batch.")
        }

        if lines.isEmpty {
            lines.append("\(snapshot.totalCount) buah tersortir; belum cukup data untuk dibandingkan.")
        }

        return lines.enumerated().map { HarvestInsight(rank: $0.offset + 1, description: $0.element) }
    }
}
