import Foundation

struct Grade: Codable, Identifiable, Hashable {
    let id: Int
    let kelasGrading: String
    let label: String
    let warnaTampilan: String
}
