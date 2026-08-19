//
//  AturanThreshold.swift
//  OranGo
//
//  Created by Johanna Angel on 16/08/26.
//
import Foundation

struct ThresholdRule: Codable, Identifiable, Hashable {
    let id: Int
    let retailGradeId: Int
    let diameterMin: Double?
    let diameterMaks: Double?
    let beratMin: Double?
    let beratMaks: Double?
    let warnaOranye: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case retailGrade
        case diameterMin
        case diameterMaks
        case beratMin
        case beratMaks
        case warnaOranye
    }

    // Standard initializer for creating new instances
    init(
        id: Int = 0,
        retailGradeId: Int,
        diameterMin: Double? = nil,
        diameterMaks: Double? = nil,
        beratMin: Double? = nil,
        beratMaks: Double? = nil,
        warnaOranye: Double? = nil
    ) {
        self.id = id
        self.retailGradeId = retailGradeId
        self.diameterMin = diameterMin
        self.diameterMaks = diameterMaks
        self.beratMin = beratMin
        self.beratMaks = beratMaks
        self.warnaOranye = warnaOranye
    }

    // Custom decoder to extract id from nested retailGrade object
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.id = try container.decode(Int.self, forKey: .id)
        self.diameterMin = try container.decodeIfPresent(Double.self, forKey: .diameterMin)
        self.diameterMaks = try container.decodeIfPresent(Double.self, forKey: .diameterMaks)
        self.beratMin = try container.decodeIfPresent(Double.self, forKey: .beratMin)
        self.beratMaks = try container.decodeIfPresent(Double.self, forKey: .beratMaks)
        self.warnaOranye = try container.decodeIfPresent(Double.self, forKey: .warnaOranye)
        
        // Extract retailGradeId from the nested relation reference.
        if let retailGrade = try container.decodeIfPresent(Ref.self, forKey: .retailGrade) {
            self.retailGradeId = retailGrade.id
        } else {
            self.retailGradeId = 0
        }
    }
    
    // Standard encoding
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(diameterMin, forKey: .diameterMin)
        try container.encodeIfPresent(diameterMaks, forKey: .diameterMaks)
        try container.encodeIfPresent(beratMin, forKey: .beratMin)
        try container.encodeIfPresent(beratMaks, forKey: .beratMaks)
        try container.encodeIfPresent(warnaOranye, forKey: .warnaOranye)
        // For encoding, send retailGradeId as a plain integer (server may ignore nested format)
        try container.encode(["id": retailGradeId], forKey: .retailGrade)
    }
}
