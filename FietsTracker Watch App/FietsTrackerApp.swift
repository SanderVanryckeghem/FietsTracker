//
//  FietsTrackerApp.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import SwiftUI
@main
struct FietsTracker_Watch_AppApp: App {
    @StateObject var workoutManager = WorkoutManager()
     @SceneBuilder var body: some Scene {
        WindowGroup {
            NavigationView(){
                StartView()
            }
            .sheet(isPresented: $workoutManager.showingSummaryView){
                SummaryView()
            }
            .environmentObject(workoutManager)
        }
    }
}
