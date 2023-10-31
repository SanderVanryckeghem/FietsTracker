//
//  BluetoothView.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 05/01/2023.
//

import SwiftUI

struct BluetoothView: View {
    @ObservedObject var bluetoothManager = BluetoothManager()
    var body: some View {
        VStack {
            if(bluetoothManager.status){
                Text("Hartslag: \(bluetoothManager.heartRate) BPM").font(.system(size: 14))
                Text("Sensor locatie: \(bluetoothManager.bodySensorLocation)").font(.system(size: 14))
            }
            else{
                Text("Geen toestel verbonden")
            }
        }.onDisappear {
            bluetoothManager.disconnect()
       }
    }
}
struct BluetoothView_Previews: PreviewProvider {
    static var previews: some View {
        BluetoothView()
    }
}

