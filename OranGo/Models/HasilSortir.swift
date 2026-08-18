import Foundation

struct HasilSortir: Codable, Identifiable, Hashable {
    let id: Int
    let batch: Ref?
    let grade: Ref
    let retailGrade: Ref
    let waktuScan: Date
    let diameter: Double
    let berat: Double
    let warnaOranye: Double
    let bentukWajar: Bool

    var batchId: Int? { batch?.id }
    var gradeId: Int { grade.id }
}
