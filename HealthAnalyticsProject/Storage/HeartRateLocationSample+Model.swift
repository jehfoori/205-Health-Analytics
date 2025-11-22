//
//  HeartRateLocationSample+Model.swift
//  HealthAnalyticsProject
//
//  Created by Aaron Zhao on 11/19/25.
//

import Foundation
import CoreData

extension HeartRateLocationSampleEntity {
    func toModel() -> HeartRateLocationSample {
        HeartRateLocationSample(
            id: objectID,
            timestamp: timestamp,
            bpm: bpm,
            latitude: latitude,
            longitude: longitude,
            horizontalAccuracy: horizontalAccuracy
        )
    }
}
