//
//  ViewController.swift
//  CC2541 SensorTag Demo
//
//  Created by Philip Bale on 11/9/14.
//  Copyright (c) 2014 Philip Bale. All rights reserved.
//

import UIKit
import CoreBluetooth;

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    
    @IBOutlet weak var connectedStatus: UILabel!
    @IBOutlet weak var ambientTemp: UILabel!
    @IBOutlet weak var irTemp: UILabel!
    
    let sensorTagUUID = CBUUID(string: "66D57D24-5AAF-7998-F09A-2425460E09A6")
    let temperatureService = CBUUID(string: "F000AA00-0451-4000-B000-000000000000")
    let temperatureCharacteristic = CBUUID(string: "F000AA01-0451-4000-B000-000000000000")
    let temperatureMonitor = CBUUID(string: "F000AA02-0451-4000-B000-000000000000")
    
    let deviceInformationService = CBUUID(string: "180a")
    
    
    var centralManager: CBCentralManager!
    var sensorTag: CBPeripheral?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    @IBAction func tryConnecting(sender: AnyObject) {
        println("Attempting to connect");
        let services = [deviceInformationService];
        centralManager.scanForPeripheralsWithServices(nil, options: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    ////// CBCentralManagerDelegate /////////////////////////
    
    // Called when connected to BLE peripheral
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        if peripheral.state == .Connected {
            println("Successfully connected")
            connectedStatus.text = "Connected!"
        }
        else {
            println("Unsuccessfully connected")
        }
    }
    
    // CBCentralManagerDelegate - This is called with the CBPeripheral class as its main input parameter. This contains most of the information there is to know about a BLE peripheral.
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        println("didDiscoverPeripheral")
        let localNamePre: AnyObject? = advertisementData[CBAdvertisementDataLocalNameKey]
        if let localName = localNamePre as? String {
            if (!localName.isEmpty && localName == "SensorTag") {
                println("Found the sensor tag: \(localName)")
                self.centralManager.stopScan()
                self.sensorTag = peripheral
                peripheral.delegate = self;
                self.centralManager.connectPeripheral(peripheral, options: nil)
            }
        }
    }
    
    // method called whenever the device state changes.
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        // Determine the state of the peripheral
        if central.state == .PoweredOff {
            println("CoreBluetooth BLE hardware is powered off")
        }
        else if central.state == .PoweredOn {
            println("CoreBluetooth BLE hardware is powered on and ready")
        }
        else if central.state == .Unauthorized {
            println("CoreBluetooth BLE state is unauthorized")
        }
        else if central.state == .Unknown {
            println("CoreBluetooth BLE state is unknown")
        }
        else if central.state == .Unsupported {
            println("CoreBluetooth BLE hardware is unsupported on this platform")
        }
    }
    
    
    ////// CBPeripheralDelegate /////////////////////////
    
    // CBPeripheralDelegate - Invoked when you discover the peripheral's available services.
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        if error == nil {
            for service in peripheral.services as [CBService] {
                println("Discovered service: \(service.UUID) \(service.UUID.data)")
                if service.UUID == temperatureService {
                    peripheral.discoverCharacteristics(nil, forService: service)
                }
            }
        }
        else {
            println("Error discovering services: \(error)")
        }
    }
    
    // Invoked when you discover the characteristics of a specified service.
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!){
        if error == nil {
            println("Service Info: \(service.description)")
            for aChar in service.characteristics as [CBCharacteristic] {
                //if aChar.UUID == HRM_MANUFACTURER_NAME_CHARACTERISTIC_UUID {
                //HRMPeripheral.readValueForCharacteristic(aChar)
                aChar.description
                println("Found: \(aChar.UUID) \(aChar.UUID.data)")
                if aChar.UUID == temperatureCharacteristic || aChar.UUID == temperatureMonitor ||
                    aChar.UUID == temperatureService {
                        var enabled:Int = 1;
                        let data = NSData(bytes: &enabled, length: 1)
                        peripheral.writeValue(data, forCharacteristic: aChar, type: CBCharacteristicWriteType.WithResponse)
                        peripheral.setNotifyValue(true, forCharacteristic: aChar)
                        println("Periph: \(peripheral.description)")
                        println("Found IR temp")
                }
                //}
            }
        }
        else {
            println("Error discovering characteristics: \(error)")
        }
    }
    
    
    // Notofied of characteristic's value
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        println("Notification received!")
        
        if (characteristic.UUID == temperatureCharacteristic) {
            getTemperatureData(characteristic, error: error)
        }
    }
    
    func getTemperatureData(characteristic: CBCharacteristic!, error: NSError!) {
        println("Getting temperature data!")
        
        var data:Int16 = 0
        characteristic.value.getBytes(&data)
        
        let ambient = Double(data)/128.0;
        let vObj2 = Double(data)*0.00000015625;
        let tDie2 = ambient + 273.15;
        let s0 = 6.4*pow(10,-14);
        let a1 = 1.75*pow(10,-3);
        let a2 = -1.678*pow(10,-5);
        let b0 = -2.94*pow(10,-5);
        let b1 = -5.7*pow(10,-7);
        let b2 = 4.63*pow(10,-9);
        let c2 = 13.4;
        let tRef = 298.15;
        let s = s0*(1+a1*(tDie2 - tRef)+a2*pow((tDie2 - tRef),2));
        let vOs = b0 + b1*(tDie2 - tRef) + b2*pow((tDie2 - tRef),2);
        let fObj = (vObj2 - vOs) + c2*pow((vObj2 - vOs),2);
        let object = pow(pow(tDie2,4) + (fObj/s),0.25) - 273.15;
        
        
        ambientTemp.text = "\(ambient)"
        irTemp.text = "\(object)"
        
    }
}

