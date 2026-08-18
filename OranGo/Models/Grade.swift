import Foundation

struct Grade: Codable, Identifiable {
    let id: Int
    let kelasGrading: String
    let label: String
    let warnaTampilan: String

    enum CodingKeys: String, CodingKey {
        case id
        case kelasGrading = "kelas_grading"
        case label
        case warnaTampilan = "warna_tampilan"
    }
}
