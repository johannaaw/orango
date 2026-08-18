import Foundation

struct RetailGrade: Identifiable, Codable, Hashable {
    let id: Int
    let retailName: String
    let dibuatPada: Date?
    let aktif: Bool?
    let catatan: String?
}

/// `GET /api/retail-grades/:id` wraps the record together with its threshold.
struct RetailGradeDetail: Codable, Hashable {
    let retailGrade: RetailGrade
    let threshold: ThresholdRule?
}
