//
//  FietsTracker_Watch_AppTests.swift
//  FietsTracker Watch AppTests
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import XCTest
import HealthKit
import CoreLocation
@testable import FietsTracker_Watch_App

final class FietsTracker_Watch_AppTests: XCTestCase {
    
    let workoutManager = WorkoutManager()
    let workoutType = HKWorkoutActivityType.cycling
    var locationManager: CLLocationManager!
    
    func testStartWorkout() {
        // Set up the test by requesting authorization to access HealthKit data
        workoutManager.requestAuthorization()
        
        // Start a workout
        workoutManager.startWorkout(workoutType: workoutType)
        
        // Assert that the workout session and builder are not nil
        XCTAssertNotNil(workoutManager.session)
        XCTAssertNotNil(workoutManager.builder)
    }
    //Not testing in simulator and permision to track location is needded
    func test_whenStartWorkout_thenStartUpdatingLocation() {
           workoutManager.startWorkout(workoutType: workoutType)
        
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
            XCTAssertNotNil(locationManager.location)
        }
    
    func testRequestAuthorization() {
        // Request authorization to access HealthKit data
        workoutManager.requestAuthorization()
        
        // Assert that the healthStore property is not nil
        XCTAssertNotNil(workoutManager.healthStore)
    }
    
    func testResetWorkout() {
        // Set up the test by setting the showingSummaryView property to true
        workoutManager.selectedWorkout = .cycling
        workoutManager.activeEnergy = 123
        workoutManager.basalEnergy = 123
        workoutManager.averageHeartRate = 124
        workoutManager.heartRate = 223
        workoutManager.distance = 12930
        
        // Call the resetWorkout() method
        workoutManager.resetWorkout()
        
        // Assert that the showingSummaryView property is now false
        XCTAssertTrue(workoutManager.selectedWorkout == nil)
        XCTAssertTrue(workoutManager.activeEnergy == 0)
        XCTAssertTrue(workoutManager.basalEnergy == 0)
        XCTAssertTrue(workoutManager.averageHeartRate == 0)
        XCTAssertTrue(workoutManager.heartRate == 0)
        XCTAssertTrue(workoutManager.distance == 0)
    }
    
    
}
