//
//  RetailGrade.swift
//  OranGo
//
//  Created by Johanna Angel on 16/08/26.
//

import Foundation

struct RetailGrade: Identifiable, Codable, Hashable {
    let id: Int
    let retailName: String
    let dibuatPada: String?
    let aktif: Bool?
    let catatan: String?
}
