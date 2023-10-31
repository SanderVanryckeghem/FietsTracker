//
//  LocationManager.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 20/12/2022.
//

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject {
  private let locationManager = CLLocationManager()

  override init() {
    super.init()
    locationManager.delegate = self
    locationManager.desiredAccuracy = kCLLocationAccuracyBest
    locationManager.activityType = .fitness
    locationManager.distanceFilter = 10
  }

  func requestAuthorization() {
    locationManager.requestAlwaysAuthorization()
  }

  func startUpdatingLocation() {
    locationManager.startUpdatingLocation()
  }

  func stopUpdatingLocation() {
    locationManager.stopUpdatingLocation()
  }
}

extension LocationManager: CLLocationManagerDelegate {
  func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
    // Update the route builder with the new location data
//    if let location = locations.last {
//        routeBuilder?.addRouteData(location)
//    }
  }
}
