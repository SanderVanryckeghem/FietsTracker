//
//  MetricsView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import SwiftUI

struct MetricsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    @ObservedObject var bluetoothManager = BluetoothManager()
    @State var toggleHeartrate = true
    @State var toggleEnergy = true
    var body: some View {
        TimelineView(MetricsTimelineSchedule(from: workoutManager.builder?.startDate ?? Date(),
                                             isPaused: workoutManager.session?.state == .paused)) { context in
            VStack(alignment: .leading) {
                ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime(at: context.date) ?? 0, showSubseconds: context.cadence == .live)
                    .foregroundStyle(.yellow)
                if(toggleEnergy){
                    Text(Measurement(value: workoutManager.activeEnergy, unit: UnitEnergy.kilocalories)
                        .formatted(.measurement(width: .abbreviated, usage: .workout, numberFormatStyle: .number.precision(.fractionLength(0)))))
                    .onTapGesture {
                        toggleEnergy = false
                    }
                }
                else{
                    Text("\(String(format: "%.1f", workoutManager.paceKmPerH)) Km/h")
                    .onTapGesture {
                        toggleEnergy = true
                    }
                }
                if(self.bluetoothManager.heartRate == 0){
                    if(toggleHeartrate){
                        HStack{
                            Text(workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))))
                            Image(systemName: "bolt.heart").foregroundColor(.red)
                        }
                        .onTapGesture {
                            toggleHeartrate = false
                        }
                    }
                    else{
                        HStack{
                            Text(workoutManager.averageHeartRate.formatted(.number.precision(.fractionLength(0))) + " g")
                            Image(systemName: "bolt.heart").foregroundColor(.red)
                        }
                        .onTapGesture {
                            toggleHeartrate = true
                        }
                    }
                }
                else{
                    HStack{
                        Text("\(bluetoothManager.heartRate) B")
                        Image(systemName: "bolt.heart").foregroundColor(.red)
                    }
                }
                Text(Measurement(value: workoutManager.distance, unit: UnitLength.meters).formatted(.measurement(width: .abbreviated, usage: .road)))
            }
            .font(.system(.title, design: .rounded).monospacedDigit().lowercaseSmallCaps())
            .frame(maxWidth: .infinity, alignment: .leading)
            .ignoresSafeArea(edges: .bottom)
            .scenePadding()
        }
    }
}

struct MetricsView_Previews: PreviewProvider {
    static var previews: some View {
        MetricsView().environmentObject(WorkoutManager())
    }
}

private struct MetricsTimelineSchedule: TimelineSchedule {
    var startDate: Date
    var isPaused: Bool

    init(from startDate: Date, isPaused: Bool) {
        self.startDate = startDate
        self.isPaused = isPaused
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> AnyIterator<Date> {
        var baseSchedule = PeriodicTimelineSchedule(from: self.startDate, by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0))
            .entries(from: startDate, mode: mode)
        return AnyIterator<Date> {
            guard !isPaused else { return nil }
            return baseSchedule.next()
        }
    }
}
