//
//  WorkoutManager.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import Foundation
import HealthKit
import CoreLocation

class WorkoutManager: NSObject, ObservableObject, CLLocationManagerDelegate{
    var heartRateData = [Double]()
    var durationTimeData = [Double]()
    var startTimeData = [Date]()
    var time1 = Date()
    var time2 = Date()
    var time3 = TimeInterval()
    var time4 = TimeInterval()
    var distance1 = 0.0
    var distance2 = 0.0
    var distance3 = 0.0
    var timer: Timer?
    var paceKmPerH = 0.0
    var gemPaceKmPerH = 0.0
    var routeLocations: [CLLocation] = []
    var routeBuilder: HKWorkoutRouteBuilder?
    var workoutByHealtkit = [HKWorkout]()
    let locationManager = CLLocationManager()
    var authorizationStatus = false
    var selectedWorkout: HKWorkoutActivityType? {
       didSet {
           guard let selectedWorkout = selectedWorkout else { return }
           startWorkout(workoutType: selectedWorkout)
       }
   }
    
    @Published var showingSummaryView: Bool = false {
        didSet {
            if showingSummaryView == false {
                resetWorkout()
            }
        }
    }
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    
    // Start the workout.
    func startWorkout(workoutType: HKWorkoutActivityType) {
        locationManager.delegate = self
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()

        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
        } catch {

            return
        }

        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore,
            workoutConfiguration: configuration
        )
        
        session?.delegate = self
        builder?.delegate = self
        
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            self.time1 = startDate
        }
    }
    
    
    // MARK: Request authorization to access HealthKit.
    func requestAuthorization() {

        locationManager.requestWhenInUseAuthorization()
        locationManager.requestAlwaysAuthorization()
        
        let typesToShare: Set = [
            HKQuantityType.workoutType(),
            HKSeriesType.workoutRoute()
        ]

        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKSeriesType.workoutRoute(),
            HKSeriesType.workoutType()
        ]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { (success, error) in
           
        }
    }

    // MARK: - Session State Control

    // The app's workout state.
    @Published var running = false

    func togglePause() {
        if running == true {
            self.pause()
        } else {
            resume()
        }
    }
    
    func pause() {
        session?.pause()
    }

    func resume() {
        session?.resume()
    }
    func endWorkout() async{
        session?.end()
        stopUpdatingPace()
        showingSummaryView = true
    }
    // MARK: - Workout Metrics
    @Published var averageHeartRate: Double = 0
    @Published var basalEnergy: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    
    func updateForStatistics(_ statistics: HKStatistics?) {
        guard let statistics = statistics else { return }
        startUpdatingPace()
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.basalEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default:
                return
            }
        }
    }
    func resetWorkout() {
        selectedWorkout = nil
        builder = nil
        workout = nil
        session = nil
        activeEnergy = 0
        basalEnergy = 0
        averageHeartRate = 0
        heartRate = 0
        distance = 0
    }
    
    func startUpdatingPace() {
        time4 = time1.timeIntervalSince(Date())
        gemPaceKmPerH = distance / time4
        time2 = Date()
        time3 = time2.timeIntervalSince(self.time1)
        distance2 = distance
        distance3 = distance2 - distance1
        if((distance3/time3)==0.0 || (distance3/time3)>100.0 ){
            time1 = time2
            distance1 = distance2
        }
        else{
            paceKmPerH = (distance3/time3) * 3.6
            time1 = time2
            distance1 = distance2
        }
    }
    func stopUpdatingPace() {
            timer?.invalidate()
            timer = nil
        }
    
    // MARK: - Read Workouts.
    
    func readWorkouts() async -> [HKWorkout]? {
        requestAuthorization()
        let autherizationStatus = healthStore.authorizationStatus(for: HKSampleType.workoutType())
        
        switch autherizationStatus {
                case .sharingAuthorized: authorizationStatus = true
                case .sharingDenied: break
                default: break
                }
        
        if (authorizationStatus){
            let cycling = HKQuery.predicateForWorkouts(with: .cycling)

            let samples = try! await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKSample], Error>) in
                healthStore.execute(HKSampleQuery(sampleType: .workoutType(), predicate: cycling, limit: HKObjectQueryNoLimit,sortDescriptors: [.init(keyPath: \HKSample.startDate, ascending: false)], resultsHandler: { query, samples, error in
                    if let hasError = error {
                        continuation.resume(throwing: hasError)
                        return
                    }

                    guard let samples = samples else {
                        fatalError("*** Invalid State: This can only fail if there was an error. ***")
                    }

                    continuation.resume(returning: samples)
                }))
            }

            guard let workouts = samples as? [HKWorkout] else {
                return nil
            }
            for workout in workouts {
                let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!

                let heartRatePredicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: [])

                let heartRateQuery = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: heartRatePredicate, options: .discreteAverage) { (query, result, error) in
                    guard let result = result, let averageHeartRate = result.averageQuantity() else {
                        
                        return
                    }

                    let bpm = averageHeartRate.doubleValue(for: HKUnit(from: "count/min"))
                    self.heartRateData.append(bpm)
                }

                healthStore.execute(heartRateQuery)
            }
            durationTimeData = workouts.map { $0.duration }
            startTimeData = workouts.map {$0.startDate}
            workoutByHealtkit = workouts
            return workouts
        }
        else{
            return nil
        }
    }
    
    func getRoutes(workoutSample: HKWorkout) {
        let workoutObjectQuery = HKQuery.predicateForObjects(from: workoutSample)
        let routeQuery = HKAnchoredObjectQuery(type: HKSeriesType.workoutRoute(), predicate: workoutObjectQuery, anchor: nil, limit: HKObjectQueryNoLimit) { (queryRoute, routeSamples, deletedRouteObjects, routeAnchor, routeError) in
            guard routeError == nil else {
                self.routeLocations = []
                return
            }
            guard routeSamples != nil else {
                self.routeLocations = []
                return
            }
            if routeSamples!.count == 0 {
                self.routeLocations = []
                return
            }
            for routeSample in routeSamples! {
                self.getLocationsFromRoute(workoutSample: workoutSample, workoutRouteSample: routeSample)
            }
            self.routeLocations = []
        }
        let healthStore = HKHealthStore()
        healthStore.execute(routeQuery)
    }


    func getLocationsFromRoute(workoutSample: HKWorkout, workoutRouteSample: HKSample) {
        let routeSampleQuery = HKWorkoutRouteQuery(route: workoutRouteSample as! HKWorkoutRoute) { (queryRouteSample, locationsOrNil, done, errorOrNil) in
            if errorOrNil != nil || locationsOrNil == nil {
                return
            }
            self.handleWorkoutRouteLocations(workout: workoutSample, locations: locationsOrNil ?? [])
        }
        let healthStore = HKHealthStore()
        healthStore.execute(routeSampleQuery)
    }
    
    func handleWorkoutRouteLocations(workout: HKWorkout, locations: [CLLocation]) {
        routeLocations.append(contentsOf: locations)
    }
    
    
    // MARK: - CLLocationManagerDelegate Methods.
    func locationManager( _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
     
        guard !locations.isEmpty, locations.first?.coordinate.latitude != 0, locations.first?.coordinate.longitude != 0 else {
                   return
               }
        let filteredLocations = locations.filter { (location: CLLocation) -> Bool in
            location.horizontalAccuracy <= 50.0
        }
        
        guard !filteredLocations.isEmpty else {
            return
        }
        
        routeBuilder?.insertRouteData(filteredLocations) { (success, error) in
            if !success {
                print(error as Any)
            }
        }
    }
    
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }

        if toState == .ended {
            locationManager.stopUpdatingLocation()
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    self.routeBuilder?.finishRoute(with: workout!, metadata: workout?.metadata) { (newRoute, error) in
                        guard newRoute != nil else {

                            return
                        }
                    }
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
            
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {

    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {

    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else {
                return // Nothing to do.
            }

            let statistics = workoutBuilder.statistics(for: quantityType)

            // Update the published values.
            updateForStatistics(statistics)
        }
    }
}

