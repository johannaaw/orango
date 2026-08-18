import Foundation

struct HasilSortir: Codable, Identifiable {
    let id: Int
    let batchId: Int
    let gradeId: Int
    let retailGradeId: Int
    let waktuScan: Date
    let diameter: Double
    let berat: Double
    let warnaOranye: Double
    let bentukWajar: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case batchId = "batch_id"
        case gradeId = "grade_id"
        case retailGradeId = "retail_grade_id"
        case waktuScan = "waktu_scan"
        case diameter
        case berat
        case warnaOranye = "warna_oranye"
        case bentukWajar = "bentuk_wajar"
    }
}
