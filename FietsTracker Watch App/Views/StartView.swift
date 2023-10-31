//
//  StartView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 14/12/2022.
//

import SwiftUI
import HealthKit
import CoreLocation

struct StartView: View {
    @EnvironmentObject var workoutManager: WorkoutManager
    private let locationManager = CLLocationManager()
    @State private var showingAlertLocation = false
    var locationStatus: CLAuthorizationStatus {
            locationManager.authorizationStatus
        }
    var workoutTypes: [HKWorkoutActivityType] = [.cycling] // lijst met workoutTypes
    //weergeven van de startpagina
    var body: some View {
        List() {
                NavigationLink(
                    destination: SessionPagingView(),
                    tag: workoutTypes[0],
                    selection: $workoutManager.selectedWorkout,
                    label: {
                        Label("Start fietsrit", systemImage: "bicycle")
                            .labelStyle(.titleAndIcon)
                    }
                ).padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
            NavigationLink(
                destination: ShowOldActivityView(),
                label: {
                    Label("Laatste ritten", systemImage: "book")
                        .labelStyle(.titleAndIcon)
                }
                
            ).padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
            NavigationLink(
                destination: BluetoothView(),
                label: {
                    Label("Bluetooth", systemImage: "applewatch.radiowaves.left.and.right")
                        .labelStyle(.titleAndIcon)
                }
                
            ).padding(EdgeInsets(top: 15, leading: 5, bottom: 15, trailing: 5))
            
                .listStyle(.carousel)
                .navigationBarTitle("FietsTracker")
                .onAppear{
                    workoutManager.requestAuthorization()
                    workoutManager.workoutByHealtkit = []
                    
                    Task{
                        await workoutManager.readWorkouts()
                    }
                    if (locationStatus == .denied){
                        showingAlertLocation = true
                    }
                }
                .alert("Er is geen toegang voor de locatie te volgen. \n Wilt u uw workout route kunnen bekijken schakel dit in. \n Instructie: Open Instellingen op uw iphone -> Privacy en beveiliging -> Locatievoorzieningen -> FietsTracker -> altijd", isPresented: $showingAlertLocation) {
                    Button("Ok", role: .cancel) { }
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        StartView().environmentObject(WorkoutManager())
    }
}
//Een type een naam geven
extension HKWorkoutActivityType: Identifiable {
    public var id: UInt {
        rawValue
    }

    var name: String {
        switch self {
        case .cycling:
            return "FietsTracker"
        default:
            return ""
        }
    }
}
