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

/// The figures an insight can be drawn from.
struct InsightSnapshot: Equatable {
    let periodLabel: String
    let totalWeightKg: Double
    let totalCount: Int
    let totalBatch: Int
    let gradeResults: [GradeResult]

    var hasData: Bool { totalCount > 0 }

    static func == (lhs: InsightSnapshot, rhs: InsightSnapshot) -> Bool {
        lhs.periodLabel == rhs.periodLabel && lhs.hasData == rhs.hasData
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
            You are a Senior Citrus Quality Control Analyst.
            Analyze the daily orange sorting metrics and provide exactly 3 actionable insights.

            Rules:
            1. Provide exactly 3 short sentences.
            2. Each sentence must be strictly under 90 characters.
            3. Do not invent data. Use ONLY the provided metrics.
            4. Focus areas:
               - Insight 1: Highlight the dominant grade or overall quality.
               - Insight 2: Evaluate the reject rate or throughput efficiency.
               - Insight 3: Provide a brief operational recommendation.
            5. Output the final insights in Indonesian (Bahasa Indonesia).
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

    private static func prompt(for snapshot: InsightSnapshot) -> String {
        // 1. PRA-KALKULASI (Bantu AI berhitung di Swift agar tidak halusinasi)
        let avgBatchWeight: Double = snapshot.totalBatch > 0
            ? (snapshot.totalWeightKg / Double(snapshot.totalBatch))
            : 0.0
            
        let dominantGrade = snapshot.gradeResults.max(by: { $0.weightKg < $1.weightKg })
        let rejectResult = snapshot.gradeResults.first(where: { $0.gradeType == .reject })

        // Siapkan teks konklusi siap pakai untuk AI
        let dominantText = dominantGrade != nil
            ? "\(dominantGrade!.gradeType.displayName) (\(dominantGrade!.percentage.formattedWeight)%)"
            : "N/A"
            
        let rejectText = rejectResult != nil
            ? "\(rejectResult!.percentage.formattedWeight)%"
            : "0%"

        // 2. FORMAT DATA DALAM BAHASA INGGRIS (Menghindari Apple Language Detector Error)
        let breakdown = snapshot.gradeResults
            .map { "- Grade \($0.gradeType.displayName): \($0.weightKg.formattedWeight)kg (\($0.percentage.formattedWeight)%)" }
            .joined(separator: "\n")

        // 3. SUSUN PROMPT
        return """
        Citrus Sorting Data for '\(snapshot.periodLabel)':
        - Total Processed: \(snapshot.totalWeightKg.formattedWeight) kg (\(snapshot.totalCount) oranges)
        - Total Batches: \(snapshot.totalBatch)
        - Avg Weight/Batch: \(avgBatchWeight.formattedWeight) kg
        - Dominant Grade: \(dominantText)
        - Reject Rate: \(rejectText)

        Detailed Breakdown:
        \(breakdown)

        Task: Based on these metrics, write the 3 insights following the rules.
        """
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
    private static func computed(_ snapshot: InsightSnapshot) -> [HarvestInsight] {
        var lines: [String] = []

        let ranked = snapshot.gradeResults.sorted { $0.weightKg > $1.weightKg }

        if let top = ranked.first, top.weightKg > 0 {
            lines.append("\(top.gradeType.displayName) mendominasi \(top.percentage.formattedWeight)% dari total berat.")
        }

        if let reject = snapshot.gradeResults.first(where: { $0.gradeType == .reject }) {
            let verdict = reject.percentage > 10 ? "perlu ditinjau" : "masih terkendali"
            lines.append("Reject \(reject.percentage.formattedWeight)% — \(verdict).")
        }

        if snapshot.totalBatch > 0 {
            let perBatch = snapshot.totalWeightKg / Double(snapshot.totalBatch)
            lines.append("Rata-rata \(perBatch.formattedWeight) kg per batch dari \(snapshot.totalBatch) batch selesai.")
        } else {
            lines.append("\(snapshot.totalCount) buah tersortir, belum ada batch yang diselesaikan.")
        }

        return lines.enumerated().map { HarvestInsight(rank: $0.offset + 1, description: $0.element) }
    }
}
