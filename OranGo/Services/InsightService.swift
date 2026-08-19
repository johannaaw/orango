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
    /// The dates that name covers, so the card can show what it measured against.
    var periodLabel: String = ""
    let totalWeightKg: Double
    let totalCount: Int
    let rejectPercentage: Double
    let retailGradePercentage: Double
    /// Kept so the current pace can be phrased as a percentage rather than a raw rate.
    var throughputPerHour: Double? = nil
    /// The earlier period's shortfall mix, so an insight can say which aspect improved.
    var rejectBreakdown: RejectBreakdown? = nil
}

/// One batch's outcome inside the period, for comparing batches against each other.
struct BatchQuality: Equatable {
    let name: String
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

    /// Counts are held for the arithmetic but never leave this type — everything the insight
    /// sees is a share of the fruit that missed the standard.
    func share(of count: Int) -> Double {
        guard failedCount > 0 else { return 0 }
        return Double(count) / Double(failedCount) * 100
    }

    var nearMissShare: Double { share(of: nearMissCount) }
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
    /// Per-batch outcomes within the period, ordered best first. Only meaningful from two up.
    var batchQuality: [BatchQuality] = []

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

    /// The snapshot the insights on screen were written from. Exposed so the card can show
    /// the figures behind its own percentages — and show the ones actually used, which after
    /// a poll are no longer the newest ones.
    private(set) var generatedFrom: InsightSnapshot?
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
    @Guide(
        description: "Between two and four observations about the oranges, in Indonesian, each one sentence under 140 characters",
        .count(2 ... 4)
    )
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
            You write a short read-out on a citrus harvest for the packing team. Your subject
            is ALWAYS the oranges and how this harvest graded — never the sorting equipment.

            Write between 2 and 4 insights — one for each angle below that the data actually
            supports, in this order. Skip any angle whose data is missing; never pad with a
            sentence that only says something could not be compared.
              1. KECEPATAN — how the sorting pace compares with the comparison period.
              2. SEBAB — which quality aspect the oranges that missed the standard fell
                 short on (colour, diameter, weight or shape).
              3. PERGESERAN SEBAB — which aspect improved or worsened against the comparison
                 period, e.g. colour shortfalls easing while diameter shortfalls grow.
              4. ANTAR BATCH — how the strongest and weakest batch of the period differ.
              5. ARAH KUALITAS — whether the fruit's quality rose OR fell overall; if there
                 is no comparison period, what share came close enough to be recoverable.

            Hard rules:
            1. Write about the fruit and the harvest only. NEVER mention the machine, sensor,
               camera, calibration, threshold settings, the operator's work, or this app.
            2. NEVER instruct, warn or correct the reader. Forbidden: "periksa", "perhatikan",
               "pastikan", "tinjau", "sebaiknya", "perlu", "tingkatkan", "cermat". These are
               observations about the oranges, not tasks for anyone.
            3. Report the direction the figures actually show. A decline is as reportable as
               a gain: "reject naik", "kualitas turun", "laju melambat" are all expected when
               the data says so. NEVER soften, omit or reverse a decline, and never end on a
               reassurance. What is forbidden is BLAME, not bad news — do not call anything
               faulty, mis-set or careless, and do not pin a shortfall on the equipment or on
               anyone's work. A poor harvest is something the fruit shows, and saying so
               plainly is the job.
            4. Never restate a figure the dashboard already shows on its own. "Grade A
               mencapai 27%" is forbidden. A percentage may appear only as part of a change
               or a cause.
            5. NEVER write "poin" or "percentage point". To describe a change between two
               rates, state BOTH values — "naik dari 7% ke 11%".
            6. EVERY quantity must be a percentage. Never write a count of fruit, a weight in
               kg, a number of batches, or a rate per hour — no "40 buah", no "390 kg", no
               "72 buah/jam". Only percentages appear in the data you are given.
            7. Use ONLY the numbers supplied. If an angle has no data, drop that angle
               entirely — never estimate, and never invent a trend.
            8. One sentence per insight, under 140 characters.
            9. Write in Indonesian (Bahasa Indonesia), in neutral third person about the
               fruit. Do not address anyone.

            BAD, never write these:
            - "Grade A mendominasi 27,8% dari total berat." (restates the dashboard)
            - "Perhatikan diameter dengan lebih cermat." (an instruction)
            - "Proses sorting perlu ditingkatkan." (blames the work)
            - "Periksa kalibrasi alat." (about the equipment)

            GOOD — note that half of these report a decline, which is exactly right when the
            figures show one:
            - "Laju sortir turun 22% sejak kemarin."
            - "Laju sortir naik 18% sejak kemarin."
            - "72% jeruk yang belum lolos tertahan di warna kulitnya."
            - "Kegagalan warna mereda dari 80% ke 62%, sementara diameter naik dari 12% ke 24%."
            - "Batch B-20260819-004 lolos retail 88%, sedangkan B-20260819-006 hanya 71%."
            - "Jeruk lolos retail turun dari 84% ke 71% sejak kemarin."
            - "Reject naik dari 7% ke 15% sejak kemarin."
            - "20% jeruk yang belum lolos hanya terpaut tipis di warna."
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

        // Every figure below is a percentage. No count, weight or rate is put in front of the
        // model at all, so there is no absolute number available for it to write.
        // Kept in English so Apple's language detector does not reject the prompt.
        sections.append("""
        PERIOD: \(snapshot.periodLabel)
        Met retail standard (A/B/C): \(snapshot.retailGradePercentage.formattedWeight)% of weight.
        Rejected: \(snapshot.rejectPercentage.formattedWeight)% of weight.
        """)

        // 1. KECEPATAN
        if let previous = snapshot.comparison,
           let before = previous.throughputPerHour,
           let now = snapshot.throughputPerHour {
            sections.append("""
            1. KECEPATAN vs \(previous.label) (call it "\(previous.label)" in the sentence):
            - Sorting pace: \(relativeChange(from: before, to: now))
            - Volume harvested: \(relativeChange(from: previous.totalWeightKg, to: snapshot.totalWeightKg))
            """)
        } else if let previous = snapshot.comparison, previous.totalWeightKg > 0 {
            sections.append("""
            1. KECEPATAN vs \(previous.label) — pace itself is not comparable this period.
            Volume harvested: \(relativeChange(from: previous.totalWeightKg, to: snapshot.totalWeightKg))
            """)
        }

        // 2. SEBAB — shares of the fruit that missed the standard, never how many.
        if let breakdown = snapshot.rejectBreakdown, breakdown.failedCount > 0 {
            let missedShare = snapshot.totalCount > 0
                ? Double(breakdown.failedCount) / Double(snapshot.totalCount) * 100
                : 0

            sections.append("""
            2. SEBAB — \(missedShare.formattedWeight)% of the oranges did not reach standard "\(breakdown.standardName)".
            Of those oranges, the aspect they fell short on:
            - colour of the skin: \(breakdown.share(of: breakdown.byColour).formattedWeight)%
            - diameter: \(breakdown.share(of: breakdown.byDiameter).formattedWeight)%
            - weight: \(breakdown.share(of: breakdown.byWeight).formattedWeight)%
            - shape: \(breakdown.share(of: breakdown.byShape).formattedWeight)%
            Name the largest aspect. This describes the fruit, not any equipment.
            """)
        }

        // 3. PERGESERAN SEBAB — only when both periods have an aspect mix to compare.
        if let now = snapshot.rejectBreakdown,
           let before = snapshot.comparison?.rejectBreakdown,
           let label = snapshot.comparison?.label,
           now.failedCount > 0, before.failedCount > 0 {
            sections.append("""
            3. PERGESERAN SEBAB vs \(label) — share of the shortfalling oranges, then and now:
            - colour: was \(before.share(of: before.byColour).formattedWeight)%, now \(now.share(of: now.byColour).formattedWeight)%
            - diameter: was \(before.share(of: before.byDiameter).formattedWeight)%, now \(now.share(of: now.byDiameter).formattedWeight)%
            - weight: was \(before.share(of: before.byWeight).formattedWeight)%, now \(now.share(of: now.byWeight).formattedWeight)%
            - shape: was \(before.share(of: before.byShape).formattedWeight)%, now \(now.share(of: now.byShape).formattedWeight)%
            Name only the aspects that moved most. Describe as "dari X% ke Y%".
            """)
        }

        // 4. ANTAR BATCH — needs at least two batches worth comparing.
        if snapshot.batchQuality.count >= 2,
           let best = snapshot.batchQuality.first,
           let worst = snapshot.batchQuality.last {
            sections.append("""
            4. ANTAR BATCH — oranges reaching retail grade, by batch:
            - highest: \(best.name) at \(best.retailGradePercentage.formattedWeight)%
            - lowest: \(worst.name) at \(worst.retailGradePercentage.formattedWeight)%
            Batch codes are names, not quantities — writing them is fine.
            """)
        }

        // 5. ARAH KUALITAS
        if let previous = snapshot.comparison {
            sections.append("""
            5. ARAH KUALITAS vs \(previous.label):
            - Reaching retail grade: was \(previous.retailGradePercentage.formattedWeight)%, now \(snapshot.retailGradePercentage.formattedWeight)%
            - Rejected: was \(previous.rejectPercentage.formattedWeight)%, now \(snapshot.rejectPercentage.formattedWeight)%
            Describe as "dari X% ke Y%". Do not subtract two rates.
            """)
        } else if let breakdown = snapshot.rejectBreakdown,
                  breakdown.nearMissCount > 0,
                  let cause = breakdown.nearMissCause {
            sections.append("""
            5. ARAH KUALITAS: no earlier period yet. Instead: \(breakdown.nearMissShare.formattedWeight)% of the
            oranges that did not reach standard came up short on \(cause) alone, and only barely.
            """)
        }

        sections.append("""
        TASK: write one insight for each numbered angle present above — between 2 and 4 in
        total, in that order. An angle missing above simply does not get an insight; do not
        mention its absence. Every figure above is a percentage; write percentages only.
        Describe the oranges. No instructions, no warnings, no mention of equipment.
        """)

        return sections.joined(separator: "\n\n")
    }

    /// The aspect whose share of the shortfall moved furthest between the two periods.
    private static func largestShift(
        from before: RejectBreakdown,
        to now: RejectBreakdown
    ) -> (aspect: String, before: Double, after: Double)? {
        let aspects: [(String, Int, Int)] = [
            ("warna", before.byColour, now.byColour),
            ("diameter", before.byDiameter, now.byDiameter),
            ("berat", before.byWeight, now.byWeight),
            ("bentuk", before.byShape, now.byShape),
        ]

        let shifts = aspects.map { name, wasCount, nowCount in
            (aspect: name, before: before.share(of: wasCount), after: now.share(of: nowCount))
        }

        guard let top = shifts.max(by: { abs($0.after - $0.before) < abs($1.after - $1.before) }),
              abs(top.after - top.before) >= 1
        else { return nil }

        return top
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

        // 1. KECEPATAN
        if let previous = snapshot.comparison,
           let before = previous.throughputPerHour,
           let now = snapshot.throughputPerHour,
           before > 0 {
            let percent = (now - before) / before * 100
            lines.append(
                "Laju sortir \(percent >= 0 ? "naik" : "turun") \(abs(percent).formattedWeight)% sejak \(previous.label)."
            )
        } else if let previous = snapshot.comparison, previous.totalWeightKg > 0 {
            let percent = (snapshot.totalWeightKg - previous.totalWeightKg) / previous.totalWeightKg * 100
            lines.append(
                "Jumlah panen tersortir \(percent >= 0 ? "naik" : "turun") \(abs(percent).formattedWeight)% sejak \(previous.label)."
            )
        }

        // 2. SEBAB
        if let breakdown = snapshot.rejectBreakdown,
           breakdown.failedCount > 0,
           let cause = breakdown.dominantCause {
            lines.append(
                "\(breakdown.share(of: cause.count).formattedWeight)% jeruk yang belum lolos tertahan di \(cause.name)."
            )
        }

        // 3. PERGESERAN SEBAB — the aspect that moved most between the two periods.
        if let now = snapshot.rejectBreakdown,
           let before = snapshot.comparison?.rejectBreakdown,
           now.failedCount > 0, before.failedCount > 0,
           let shift = largestShift(from: before, to: now) {
            lines.append(
                "Kegagalan \(shift.aspect) \(shift.after >= shift.before ? "naik" : "mereda") dari \(shift.before.formattedWeight)% ke \(shift.after.formattedWeight)%."
            )
        }

        // 4. ANTAR BATCH
        if snapshot.batchQuality.count >= 2,
           let best = snapshot.batchQuality.first,
           let worst = snapshot.batchQuality.last {
            lines.append(
                "Batch \(best.name) lolos retail \(best.retailGradePercentage.formattedWeight)%, \(worst.name) \(worst.retailGradePercentage.formattedWeight)%."
            )
        }

        // 5. ARAH KUALITAS
        if let previous = snapshot.comparison {
            let direction = snapshot.retailGradePercentage >= previous.retailGradePercentage ? "naik" : "turun"
            lines.append(
                "Jeruk lolos retail \(direction) dari \(previous.retailGradePercentage.formattedWeight)% ke \(snapshot.retailGradePercentage.formattedWeight)%."
            )
        } else if let breakdown = snapshot.rejectBreakdown,
                  breakdown.nearMissCount > 0,
                  let cause = breakdown.nearMissCause {
            lines.append(
                "\(breakdown.nearMissShare.formattedWeight)% jeruk yang belum lolos hanya terpaut tipis di \(cause)."
            )
        }

        if lines.isEmpty {
            lines.append("Belum cukup data panen untuk dibandingkan pada periode ini.")
        }

        return lines.prefix(4).enumerated().map {
            HarvestInsight(rank: $0.offset + 1, description: $0.element)
        }
    }
}
