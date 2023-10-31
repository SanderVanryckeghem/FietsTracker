//
//  MapView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 10/01/2023.
//

import SwiftUI
import MapKit
import HealthKit

struct MapView: View {
    var workout : HKWorkout
    @EnvironmentObject var workoutManager: WorkoutManager
    @State private var routeCoordinates: [CLLocation] = []{
        didSet{
            if routeCoordinates.count > 0{
                
            }
        }
    }
    @State private var region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 40.83834587046632, longitude: 14.254053016537693),
            span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
        )
    @State var places = [
            PointOfInterest(name: "Galeria Umberto I", latitude: 40.83859036140747, longitude:  14.24945566830365)
        ]
    
    var body: some View {
        Map(coordinateRegion: $region, annotationItems: places) { place in
            MapAnnotation(coordinate: place.coordinate) {
                Text("°").font(.system(size: 5))
                        }
        }.onAppear{
            routeCoordinates = workoutManager.routeLocations
                print(routeCoordinates)
            if(!routeCoordinates.isEmpty){
                region =  MKCoordinateRegion(
                    center: CLLocationCoordinate2D(latitude: routeCoordinates[0].coordinate.latitude, longitude: routeCoordinates[0].coordinate.longitude),
                    span: MKCoordinateSpan(latitudeDelta: 0.03, longitudeDelta: 0.03)
                )
                places = []
                routeCoordinates.forEach{ co in
                    places.append(PointOfInterest(name: "", latitude: co.coordinate.latitude, longitude: co.coordinate.longitude))
                }
            }
        }
                
    }
}


