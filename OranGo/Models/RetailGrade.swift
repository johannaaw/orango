//
//  RetailGrade.swift
//  OranGo
//
//  One row of `retail_grades`: the retail's name plus the thresholds a fruit has to
//  meet to pass for it. The former `aturan_threshold` table was folded into this one,
//  so a grading standard is a single record with no companion rule to keep in step.
//

import Foundation

struct RetailGrade: Identifiable, Codable, Hashable {
    let id: Int
    let retailName: String
    let catatan: String?
    let aktif: Bool?
    let dibuatPada: Date?

    // MARK: Thresholds

    let diameterMin: Double?
    let diameterMaks: Double?
    let beratMin: Double?
    let beratMaks: Double?
    let warnaOranye: Double?

    /// The server leaves `aktif` off older rows, which read as inactive.
    var isActive: Bool { aktif ?? false }

    init(
        id: Int,
        retailName: String,
        catatan: String? = nil,
        aktif: Bool? = nil,
        dibuatPada: Date? = nil,
        diameterMin: Double? = nil,
        diameterMaks: Double? = nil,
        beratMin: Double? = nil,
        beratMaks: Double? = nil,
        warnaOranye: Double? = nil
    ) {
        self.id = id
        self.retailName = retailName
        self.catatan = catatan
        self.aktif = aktif
        self.dibuatPada = dibuatPada
        self.diameterMin = diameterMin
        self.diameterMaks = diameterMaks
        self.beratMin = beratMin
        self.beratMaks = beratMaks
        self.warnaOranye = warnaOranye
    }
}

// MARK: - Draft

/// The fields the server accepts on write. `id` and `dibuatPada` are its own to assign,
/// so they are deliberately absent here.
struct RetailGradeDraft: Codable, Hashable {
    var retailName: String
    var catatan: String?
    var aktif: Bool
    var diameterMin: Double
    var diameterMaks: Double
    var beratMin: Double
    var beratMaks: Double
    var warnaOranye: Double
}

// MARK: - Validation

extension RetailGradeDraft {

    /// Sanity bounds. They are deliberately generous — they exist to catch a slipped decimal
    /// point or a value typed into the wrong row, not to encode horticultural truth.
    enum Limits {
        static let nameMaxLength = 100
        static let diameterMaxCm = 50.0
        static let weightMaxGram = 5_000.0
    }

    enum ValidationError: LocalizedError, Equatable {
        case emptyName
        case nameTooLong
        case duplicateName(String)
        case notANumber(field: String)
        case outOfRange(field: String, min: Double, max: Double, unit: String)
        case minAboveMax(label: String)

        var errorDescription: String? {
            switch self {
            case .emptyName:
                return "Nama standar tidak boleh kosong."

            case .nameTooLong:
                return "Nama standar maksimal \(Limits.nameMaxLength) karakter."

            case .duplicateName(let name):
                return "Standar dengan nama \"\(name)\" sudah ada. Gunakan nama lain."

            case .notANumber(let field):
                return "\(field) harus berupa angka."

            case .outOfRange(let field, let min, let max, let unit):
                return "\(field) harus antara \(Self.trim(min)) dan \(Self.trim(max)) \(unit)."

            case .minAboveMax(let label):
                return "\(label) minimal tidak boleh lebih besar dari \(label.lowercased()) maksimal."
            }
        }

        private static func trim(_ value: Double) -> String {
            value.truncatingRemainder(dividingBy: 1) == 0
                ? String(Int(value))
                : String(value)
        }
    }

    /// Reads a number the way the user typed it. An Indonesian decimal pad produces a comma,
    /// which `Double.init` rejects outright — that alone made valid input look invalid.
    static func number(_ text: String, field: String) throws -> Double {
        let normalised = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")

        guard let value = Double(normalised), value.isFinite else {
            throw ValidationError.notANumber(field: field)
        }
        return value
    }

    /// - Parameters:
    ///   - existing: every standard already stored, for the duplicate-name check.
    ///   - excluding: the row being edited, which must not count as its own duplicate.
    func validate(against existing: [RetailGrade] = [], excluding id: Int? = nil) throws {
        let name = retailName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !name.isEmpty else { throw ValidationError.emptyName }
        guard name.count <= Limits.nameMaxLength else { throw ValidationError.nameTooLong }

        let clashes = existing.contains {
            $0.id != id && $0.retailName.compare(name, options: .caseInsensitive) == .orderedSame
        }
        guard !clashes else { throw ValidationError.duplicateName(name) }

        try Self.require(diameterMin, field: "Diameter minimal", max: Limits.diameterMaxCm, unit: "cm")
        try Self.require(diameterMaks, field: "Diameter maksimal", max: Limits.diameterMaxCm, unit: "cm")
        try Self.require(beratMin, field: "Berat minimal", max: Limits.weightMaxGram, unit: "gr")
        try Self.require(beratMaks, field: "Berat maksimal", max: Limits.weightMaxGram, unit: "gr")

        guard warnaOranye.isFinite, (0 ... 100).contains(warnaOranye) else {
            throw ValidationError.outOfRange(field: "Warna oranye minimal", min: 0, max: 100, unit: "%")
        }

        guard diameterMin <= diameterMaks else { throw ValidationError.minAboveMax(label: "Diameter") }
        guard beratMin <= beratMaks else { throw ValidationError.minAboveMax(label: "Berat") }
    }

    /// A measurement has to be a real, positive quantity — zero would let every fruit through.
    private static func require(
        _ value: Double,
        field: String,
        max: Double,
        unit: String
    ) throws {
        guard value.isFinite, value > 0, value <= max else {
            throw ValidationError.outOfRange(field: field, min: 0, max: max, unit: unit)
        }
    }
}

extension RetailGrade {
    /// Values a brand new standard starts from, mirroring the placeholders in the form.
    static let emptyDraft = RetailGradeDraft(
        retailName: "",
        catatan: nil,
        aktif: false,
        diameterMin: 0,
        diameterMaks: 0,
        beratMin: 0,
        beratMaks: 0,
        warnaOranye: 0
    )

    var draft: RetailGradeDraft {
        RetailGradeDraft(
            retailName: retailName,
            catatan: catatan,
            aktif: isActive,
            diameterMin: diameterMin ?? 0,
            diameterMaks: diameterMaks ?? 0,
            beratMin: beratMin ?? 0,
            beratMaks: beratMaks ?? 0,
            warnaOranye: warnaOranye ?? 0
        )
    }
}
