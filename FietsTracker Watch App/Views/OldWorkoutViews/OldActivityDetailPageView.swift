//
//  OldActivityDetail Page.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 19/12/2022.
//

import SwiftUI
import HealthKit
import MapKit


struct OldActivityDetailPageView: View {
    
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    
    @State private var hasTimeElapsed = false
    @State private var showAlert = false
    @State private var avgHeartRate = 0.0
    @State private var avgPace = 0.0
    @State private var routeCoordinates = []
    @State private var avgPaceString = "0"
    @State private var error: Error?
    @EnvironmentObject var workoutManager: WorkoutManager
    var workout : HKWorkout
    var durationTimeString = String()
    var body: some View {
        ScrollView(.vertical){
            VStack(alignment: .leading) {
                SummaryMetricView(
                    title: "Tijd",
                    value: durationFormatter.string(from: workout.duration ) ?? ""
                ).foregroundColor(.yellow)
                
                SummaryMetricView(
                    title: "Afstand",
                    value: Measurement(
                        value: workout.totalDistance?.doubleValue(for: .meter()) ?? 0,
                        unit: UnitLength.meters)
                    .formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .road)
                    )
                ).foregroundStyle(.green)
                
                SummaryMetricView(
                    title: "Gem. Snelheid",
                    value: avgPaceString
                ).foregroundStyle(.blue)
                
                SummaryMetricView(title: "Energie",
                                  value: Measurement(
                                    value: workout.totalEnergyBurned?.doubleValue(
                                        for: .kilocalorie()) ?? 0,
                                                     unit: UnitEnergy.kilocalories
                                                    ).formatted(
                                                        .measurement(
                                                            width: .abbreviated,
                                                            usage: .workout,
                                                            numberFormatStyle: .number.precision(.fractionLength(0))
                                                        )
                                                    )
                )
                .foregroundStyle(.pink)
                SummaryMetricView(
                    title: "Gem. Hartslag",
                    value:  avgHeartRate
                        .formatted(
                            .number.precision(
                                .fractionLength(0))) + " bpm")
                .foregroundStyle(.red)
                if (!routeCoordinates.isEmpty){
                    NavigationLink(destination: MapView(workout: workout)) {
                        Text("Workout route")
                    }
                }
            }
            .scenePadding()
        }.onAppear{
            getWorkoutRoute()
            calculateWorkoutValues()
            getHeartRateData()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                routeCoordinates = workoutManager.routeLocations
            }
        }
    }
    
    func getWorkoutRoute(){
        workoutManager.getRoutes(workoutSample: workout)
        routeCoordinates = workoutManager.routeLocations
    }
    
    func calculateWorkoutValues(){
        let distance = workout.totalDistance?.doubleValue(for: .meter())
        self.avgPace = ((distance ?? 0)/workout.duration) * 3.6
        self.avgPaceString = String(format: "%.2f km/h", self.avgPace)
    }
    
    func getHeartRateData(){
        let healthStore = workoutManager.healthStore
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate, options: .strictStartDate)
        let heartRateUnit = HKUnit(from: "count/min")
        let heartRateQuery = HKStatisticsQuery(quantityType: HKQuantityType.quantityType(forIdentifier: .heartRate)!, quantitySamplePredicate: predicate, options: .discreteAverage) { (_, result, error) in
            DispatchQueue.main.async {
                if let error = error {
                    self.error = error
                } else if let result = result, let avgHeartRate = result.averageQuantity() {
                    self.avgHeartRate = avgHeartRate.doubleValue(for: heartRateUnit)
                } else {
                    self.error = NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not retrieve average heart rate"])
                }
            }
        }
        healthStore.execute(heartRateQuery)
    }
}
