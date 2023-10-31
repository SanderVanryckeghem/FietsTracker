//
//  BluetoothManager.swift
//  FietsTracker Watch App
//
//  Created by Sander Vanryckeghem on 05/01/2023.
// https://www.kodeco.com/231-core-bluetooth-tutorial-for-ios-heart-rate-monitor

import Foundation
import CoreBluetooth

final class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate {
    @Published var heartRate: Int = 0
    @Published var status: Bool = false
    @Published var bodySensorLocation: String = "--"
    private let heartRateServiceCBUUID = CBUUID(string: "0x180D")
    private let heartRateMeasurementCharacteristicCBUUID = CBUUID(string: "2A37")
    private let bodySensorLocationCharacteristicCBUUID = CBUUID(string: "2A38")
    
    private var centralManager: CBCentralManager!
    private var heartRatePeripheral: CBPeripheral!
    
    override init() {
        super.init()
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            self.centralManager.scanForPeripherals(withServices: [self.heartRateServiceCBUUID])
            
        @unknown default:
            print("error")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                            advertisementData: [String : Any], rssi RSSI: NSNumber) {
        self.heartRatePeripheral = peripheral
        self.heartRatePeripheral.delegate = self
        self.centralManager.stopScan()
        self.centralManager.connect(self.heartRatePeripheral)
        }
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            print("Connected!")
        status = true
        self.heartRatePeripheral.discoverServices([self.heartRateServiceCBUUID])
        }
        
        // MARK: - CBPeripheralDelegate
        
        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            guard let services = peripheral.services else { return }
            
            for service in services {
                print(service)
                peripheral.discoverCharacteristics(nil, for: service)
            }
            
        }
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        guard let characteristics = service.characteristics else { return }
        for characteristic in characteristics {
            if characteristic.uuid == self.heartRateMeasurementCharacteristicCBUUID {
                // Read the characteristic value
                peripheral.readValue(for: characteristic)
                // Subscribe to notifications for the characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == self.bodySensorLocationCharacteristicCBUUID {
                // Read the characteristic value
                peripheral.readValue(for: characteristic)
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case self.heartRateMeasurementCharacteristicCBUUID:
            heartRate = heartRate(from: characteristic)
        case self.bodySensorLocationCharacteristicCBUUID:
            bodySensorLocation = bodyLocation(from: characteristic)
        default: break
            
        }
    }

    private func heartRate(from characteristic: CBCharacteristic) -> Int {
        guard let characteristicData = characteristic.value else { return -1 }
        let byteArray = [UInt8](characteristicData)
        
        // See: https://www.bluetooth.com/specifications/gatt/viewer?attributeXmlFile=org.bluetooth.characteristic.heart_rate_measurement.xml
        let firstBitValue = byteArray[0] & 0x01
        if firstBitValue == 0 {
            // Heart Rate Value Format is in the 2nd byte
            return Int(byteArray[1])
        } else {
            
            // Heart Rate Value Format is in the 2nd and 3rd bytes
            return (Int(byteArray[1]) << 8) + Int(byteArray[2])
        }
    }
    
    private func bodyLocation(from characteristic: CBCharacteristic) -> String {
        guard let characteristicData = characteristic.value else { return "Error" }
        let byteArray = [UInt8](characteristicData)
        
        switch byteArray[0] {
        case 0: return "Other"
        case 1: return "Chest"
        case 2: return "Wrist"
        case 3: return "Finger"
        case 4: return "Hand"
        case 5: return "Ear Lobe"
        case 6: return "Foot"
        default:
            return "Reserved for future use"
        }
    }
    
    func disconnect() {
        if let heartRatePeripheral = self.heartRatePeripheral {
            centralManager.cancelPeripheralConnection(heartRatePeripheral)
        }
        status = false
    }
}


