//
//  Coordinates.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 10/01/2023.
//

import Foundation
import MapKit


struct PointOfInterest: Identifiable {

    let id = UUID()
    let name: String
    let latitude: Double
    let longitude: Double
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
