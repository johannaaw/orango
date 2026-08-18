//
//  RetailGrade.swift
//  OranGo
//
//  Created by Johanna Angel on 16/08/26.
//

import Foundation

struct RetailGrade: Identifiable, Codable {
    let id: Int
    let retailName: String
    let dibuatPada: Date
    let aktif: Bool
    let catatan: String?

    enum CodingKeys: String, CodingKey {
        case id
        case retailName = "retail_name"
        case dibuatPada = "dibuat_pada"
        case aktif
        case catatan
    }
}
