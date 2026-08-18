import Foundation

struct Machine: Codable, Identifiable {
    let id: Int
    let machineName: String
    let lokasi: String?
    let statusKoneksi: String
    let terakhirTerlihat: Date?
    let thresholdAktifId: Int

    enum CodingKeys: String, CodingKey {
        case id
        case machineName = "machine_name"
        case lokasi
        case statusKoneksi = "status_koneksi"
        case terakhirTerlihat = "terakhir_terlihat"
        case thresholdAktifId = "threshold_aktif_id"
    }
}
