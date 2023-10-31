//
//  ControlsView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import SwiftUI

struct ControlsView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var body: some View  {
        VStack{
            HStack{
                Text("Tijd: ")
                ElapsedTimeView(elapsedTime: workoutManager.builder?.elapsedTime ?? 0)
            }
            HStack {
                VStack {
                    Button {
                        Task{
                            await workoutManager.endWorkout()
                        }
                    } label: {
                        Image(systemName: "xmark")
                    }
                    .tint(.red)
                    .font(.title2)
                    Text("Stop")
                }
                VStack {
                    Button {
                        workoutManager.togglePause()
                    } label: {
                        Image(systemName: workoutManager.running ? "pause" : "play")
                    }
                    .tint(.yellow)
                    .font(.title2)
                    Text(workoutManager.running ? "Pauzeer" : "Doorgaan")
                }
            }
        }
    }
}

struct ControlsView_Previews: PreviewProvider {
    static var previews: some View {
        ControlsView().environmentObject(WorkoutManager())
    }
}
