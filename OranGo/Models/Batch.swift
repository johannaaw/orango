import Foundation

struct Batch: Codable, Identifiable, Hashable {
    let id: Int
    let machineId: Int?
    let retailGradeId: Int?
    let kodeBatch: String?
    let mulaiPada: Date?
    let selesaiPada: Date?
}
