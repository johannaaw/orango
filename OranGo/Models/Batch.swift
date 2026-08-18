import Foundation

struct Batch: Codable, Identifiable, Hashable {
    let id: Int
    let kodeBatch: String
    let mulaiPada: Date
    let selesaiPada: Date?
    let machine: Ref
    let retailGrade: Ref

    var machineId: Int { machine.id }
    var retailGradeId: Int { retailGrade.id }
    var isOngoing: Bool { selesaiPada == nil }
}
