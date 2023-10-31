//
//  SummaryView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import SwiftUI
import HealthKit

struct SummaryView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @Environment(\.dismiss) var dismiss
    @State private var durationFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        return formatter
    }()
    var body: some View {
        if workoutManager.workout == nil{
            ProgressView("Opslaan Workout")
                .navigationBarBackButtonHidden(true)
        }
        else{
            ScrollView(.vertical){
                VStack(alignment: .leading) {
                    SummaryMetricView(
                        title: "Volledige Tijd",
                        value: durationFormatter.string(from: workoutManager.workout?.duration ?? 0.0 ) ?? ""
                    ).foregroundColor(.yellow)
                    SummaryMetricView(
                        title: "Afstand",
                        value: Measurement(
                            value: workoutManager.workout?.totalDistance?.doubleValue(for: .meter()) ?? 0,
                            unit: UnitLength.meters)
                        .formatted(
                            .measurement(
                                width: .abbreviated,
                                usage: .road)
                        )
                    ).foregroundStyle(.green)
                    SummaryMetricView(title: "Energie",
                                      value: Measurement(value: workoutManager.workout?.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0,
                                                         unit: UnitEnergy.kilocalories
                                                        ).formatted(
                                                            .measurement(
                                                                width: .abbreviated,
                                                                usage: .workout,
                                                                numberFormatStyle: .number.precision(.fractionLength(0))
                                                            )
                                                        )
                    ).foregroundStyle(.pink)
                    SummaryMetricView(
                        title: "Gem. Hartslag",
                        value: workoutManager.averageHeartRate
                            .formatted(
                                .number.precision(
                                    .fractionLength(0))) + " bpm")
                    .foregroundStyle(.red)
                    Text("Activity Rings")
                    ActivityRingsView(healthStore: workoutManager.healthStore
                    ).frame(width: 50, height: 50)
                    Button("Klaar"){
                        dismiss()
                    }
                }
                .scenePadding()
            }
            .navigationTitle("Samenvatting")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SummaryView_Previews: PreviewProvider {
    static var previews: some View {
        SummaryView().environmentObject(WorkoutManager())
    }
}

struct SummaryMetricView: View {
    var title: String
    var value: String

    var body: some View {
        Text(title)
            .foregroundStyle(.foreground)
        Text(value)
            .font(.system(.title2, design: .rounded).lowercaseSmallCaps())
        Divider()
    }
}
