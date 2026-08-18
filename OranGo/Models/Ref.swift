//
//  Ref.swift
//  OranGo
//
//  Fluent serialises relations as a nested object holding only the row id.
//

import Foundation

struct Ref: Codable, Hashable {
    let id: Int
}
