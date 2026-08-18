//
//  AturanThreshold.swift
//  OranGo
//
//  Created by Johanna Angel on 16/08/26.
//
import Foundation

struct ThresholdRule: Codable, Identifiable {
    let id: Int
    let retailGradeId: Int
    let gradeId: Int
    let diameterMin: Double?
    let diameterMaks: Double?
    let beratMin: Double?
    let beratMaks: Double?
    let warnaOranye: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case retailGradeId = "retail_grade_id"
        case gradeId = "grade_id"
        case diameterMin = "diameter_min"
        case diameterMaks = "diameter_maks"
        case beratMin = "berat_min"
        case beratMaks = "berat_maks"
        case warnaOranye = "warna_oranye"
    }
}
