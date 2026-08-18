import Foundation

struct HasilSortir: Codable, Identifiable, Hashable {
    let id: Int
    let batchId: Int?
    let gradeId: Int?
    let retailGradeId: Int?
    let waktuScan: Date?
    let diameter: Double?
    let berat: Double?
    let warnaOranye: Double?
    let bentukWajar: Bool?
}
