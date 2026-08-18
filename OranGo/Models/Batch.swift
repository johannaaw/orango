import Foundation

struct Batch: Codable, Identifiable {
    let id: Int
    let machineId: Int
    let retailGradeId: Int
    let kodeBatch: String
    let mulaiPada: Date
    let selesaiPada: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case machineId = "machine_id"
        case retailGradeId = "retail_grade_id"
        case kodeBatch = "kode_batch"
        case mulaiPada = "mulai_pada"
        case selesaiPada = "selesai_pada"
    }
}
