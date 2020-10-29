//
//  BLE_BackgroundApp.swift
//  BLE Background
//
//  Created by Darwin Quezada Gaibor on 10/24/20.
//

import SwiftUI
import UIKit
import CoreBluetooth
import CoreLocation
import BackgroundTasks
import UserNotifications
import ProximityNotification

@main
struct BLE_BackgroundApp: App  {
    @UIApplicationDelegateAdaptor(MyAppDelegator.self) var appDelegate
    @Environment(\.scenePhase) var scenePhase
    //BLE
    @StateObject var bleManagerDel = bleManagerDelegate()
    @State var manager = CBCentralManager()
    //Beacons
    @State var clManager = CLLocationManager()
    @StateObject var clMangerDelegate = locationDelegate()
    
    @ObservedObject var obManagerDelegate = locationDelegate()
    
    //Queues 
    private let centralQueue = DispatchQueue.global(qos: .userInitiated)
    private let peripheralQueue = DispatchQueue.global(qos: .userInitiated)
    
    init(){
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound])
        {(granted, error) in
            
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .active:
                NSLog("Activo")
                manager.delegate = bleManagerDel
                clManager.delegate = clMangerDelegate
                if obManagerDelegate.lastDistance == .immediate{
                    NSLog("Beacon immediate")
                }else if obManagerDelegate.lastDistance == .near{
                    NSLog("Beacon cerca")
                }else if obManagerDelegate.lastDistance == .far{
                    NSLog("Beacon Lejos")
                }else{
                    NSLog("Beacon Desconocido")
                }
            case .background:
                NSLog("Background")
                periodicallySendScreenOnNotifications()
                manager.delegate = bleManagerDel
            case .inactive:
                NSLog("Inactivo")
                manager.delegate = bleManagerDel
            @unknown default:
                NSLog("Something new here")
            }
        }
    }
    
    private func periodicallySendScreenOnNotifications() {
        NSLog("Sending notification")
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now()+40.0) {
            self.sendNotification()
            self.periodicallySendScreenOnNotifications()
        }
    }
    
    private func sendNotification() {
        NSLog("Ingresando al despachador de mensajes")
        DispatchQueue.main.async {
            let center = UNUserNotificationCenter.current()
            center.removeAllDeliveredNotifications()
            let content = UNMutableNotificationContent()
            content.title = "Scanning beacons"
            content.body = ""
            content.categoryIdentifier = "low-priority"
            let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            center.add(request)
        }
    }
    // Notificaciones
    
}

class bleManagerDelegate: NSObject, ObservableObject, CBCentralManagerDelegate, CBPeripheralDelegate{
    
    var centralManager: CBCentralManager!
    var myPeripheral: CBPeripheral!
    
    override init() {
        super .init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        print("Central state update")
        if central.state != .poweredOn {
            print("Central is not powered on")
        } else {
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    //Busqueda de Bluetooth
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print("\nName : \(peripheral.name ?? "(Dispositivo sin nombre)")")
        //print("\nUUID : \(advertisementData["kCBAdvDataManufacturerData"] ?? "(Dispositivo sin UUID)")")
        //print("RSSI   : \(RSSI)")
        print("NAME   : \(peripheral.name)")
        print("UUID   : \(peripheral.description)")
        print("RSSI   : \(RSSI)")
        peripheral
        /*for ad in advertisementData{
            print(ad)
        }*/
    }
}

class locationDelegate: NSObject, ObservableObject, CLLocationManagerDelegate {

    var locationManager: CLLocationManager?
    var lastDistance = CLProximity.unknown

    
    override init() {
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.requestWhenInUseAuthorization()
        locationManager?.requestAlwaysAuthorization()
    }

    func locationManager(_ manager: CLLocationManager,
                         didChangeAuthorization status: CLAuthorizationStatus ){
        if status == .authorizedWhenInUse{
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
                if CLLocationManager.isRangingAvailable(){
                    startScanning()
                }
            }
        }else if status == .authorizedAlways{
            if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self){
                if CLLocationManager.isRangingAvailable(){
                    startScanning()
                }
            }
        }
    }
    
    func startScanning() {
        
        let uuid = UUID(uuidString: "42C75E17-76B7-B091-F43A-C9C710281714")!
        let contraint = CLBeaconIdentityConstraint(uuid: uuid, major: 123, minor: 456)
        let beaconRegion =  CLBeaconRegion(beaconIdentityConstraint: contraint, identifier: "UJI Beacon")
        
        locationManager?.startMonitoring(for: beaconRegion)
        locationManager?.startRangingBeacons(satisfying: contraint)
        
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print(error)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailRangingFor beaconConstraint: CLBeaconIdentityConstraint, error: Error) {
        print(error)
    }
    
    //Busqueda de Beacons
    func locationManager(_ manager: CLLocationManager, didRange beacons: [CLBeacon], satisfying beaconConstraint:
                            CLBeaconIdentityConstraint) {
       
        if let beacon = beacons.first{
            update(distance: beacon.proximity)
            /*print(beacon.uuid)
            print(beacon.major)
            print(beacon.minor)
            print(beacon.rssi)
            print(beacon.accuracy)
            print(beacon.timestamp)
            print(beacon.description)*/
            
            
        }else{
            update(distance: .unknown)
            //NSLog("No encontramos beacons")
        }
    }
    
    func update(distance: CLProximity){
        lastDistance = distance
    }
    
    func proxNotifiBle() {
    }
    
}

