import Foundation

struct Machine: Codable, Identifiable, Hashable {
    let id: Int
    let machineName: String
    let lokasi: String?
    let statusKoneksi: String?
    let terakhirTerlihat: Date?
    let thresholdAktif: Ref?

    var isConnected: Bool {
        statusKoneksi?.caseInsensitiveCompare("Terhubung") == .orderedSame
    }
}
