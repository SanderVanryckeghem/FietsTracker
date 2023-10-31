//
//  ShowOldActivityView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 15/12/2022.
//

import SwiftUI
import HealthKit

struct ShowOldActivityView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    var body: some View {
        VStack{
            if (workoutManager.authorizationStatus){
                if(workoutManager.workoutByHealtkit.count == 0){
                    Text("U heeft nog geen ritten omm weer te geven.")
                }
                else{
                    List(workoutManager.workoutByHealtkit, id: \.self) { workoutHealtkit in
                        NavigationLink("\(workoutHealtkit.startDate.formatted())", destination: OldActivityDetailPageView(workout: workoutHealtkit))
                    }
                }
            }
            else{
                ScrollView{
                    Text("U gaf deze app geen toestemming om deze data te bekijken.")
                    Text("U kunt toestemming geven via deze stappen: instellingen -> gezondheid -> app -> fietstracker -> alles aan")
                }
            }
        }.onAppear{
            Task{
                await workoutManager.readWorkouts()
            }
        }
    }
}

struct ShowOldActivityView_Previews: PreviewProvider {
    static var previews: some View {
        ShowOldActivityView()
    }
}
