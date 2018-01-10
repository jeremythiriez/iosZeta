//
//  MainViewController.swift
//  Zeta
//
//  Created by Jeremy thiriez on 07/12/2017.
//  Copyright © 2017 Jeremy thiriez. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate {
    var manager:CBCentralManager? = nil
    var mainPeripheral:CBPeripheral? = nil
    var writeCharacteristic:CBCharacteristic? = nil
    var readCharacteristic:CBCharacteristic? = nil
    
    let BLEService = "FE84"
    let BLEwriteCharacteristic = "2D30C083-F39F-4CE6-923F-3484EA480596"
    let BLEreadCharacteristic = "2D30C082-F39F-4CE6-923F-3484EA480596"
    
    var bytesArray = [UInt8]()
    
    var HandleData : DataHandler = DataHandler()
    
    //var recievedMessageText: UILabel!
    @IBOutlet weak var recievedMessageText: UILabel!
    @IBOutlet weak var readButton: UIButton!
    @IBOutlet weak var progressBar: UIProgressView!
    
    var counter: Float = 0 {
        didSet {
            let frationaProgress = counter
            let animated = counter != 0
            
            progressBar.setProgress(frationaProgress, animated: animated)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        manager = CBCentralManager(delegate: self, queue: nil);
        customiseNavigationBar()
        readButton.layer.cornerRadius = 5
    }
    
    func read() -> [UInt8] {
        return bytesArray
    }
    
    func treatedData(data: Data) {
        bytesArray = []
    
        for index in 0..<data.count {
            bytesArray.insert(data[index], at: index)
        }
        HandleData.HandleFrame(data: bytesArray)
        counter = HandleData.feedback
    }
    
    func customiseNavigationBar () {
        self.navigationItem.rightBarButtonItem = nil
        let rightButton = UIButton()
        if (mainPeripheral == nil) {
            rightButton.setTitle("Scan", for: [])
            rightButton.setTitleColor(UIColor.blue, for: [])
            rightButton.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 60, height: 30))
            rightButton.addTarget(self, action: #selector(self.scanButtonPressed), for: .touchUpInside)
        } else {
            rightButton.setTitle("Disconnect", for: [])
            rightButton.setTitleColor(UIColor.blue, for: [])
            rightButton.frame = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: 100, height: 30))
            rightButton.addTarget(self, action: #selector(self.disconnectButtonPressed), for: .touchUpInside)
        }
        let rightBarButton = UIBarButtonItem()
        rightBarButton.customView = rightButton
        self.navigationItem.rightBarButtonItem = rightBarButton
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.identifier == "scan-segue") {
            let scanController : ScanTableViewController = segue.destination as! ScanTableViewController
            //set the manager's delegate to the scan view so it can call relevant connection methods
            manager?.delegate = scanController
            scanController.manager = manager
            scanController.parentView = self
        }
    }
    
    // MARK: Button Methods
    @objc func scanButtonPressed() {
        performSegue(withIdentifier: "scan-segue", sender: nil)
    }
    
    @objc func disconnectButtonPressed() {
        manager?.cancelPeripheralConnection(mainPeripheral!)
    }
    
    @IBAction func switchButton(_ sender: UISwitch) {
        var request : String
        (sender.isOn) ? (request = "b") : (request = "s")
        let dataToSend = request.data(using: String.Encoding.utf8)
        if (mainPeripheral != nil) {
            mainPeripheral?.writeValue(dataToSend!, for: writeCharacteristic!, type: CBCharacteristicWriteType.withoutResponse)
            (sender.isOn) ? print("Start") : print("Stop")
        } else {
            print("haven't discovered device yet")
        }
    }
    
    @IBAction func readButtonPressed(_ sender: UIButton) {
        if (mainPeripheral != nil) {
            mainPeripheral?.readValue(for: readCharacteristic!)
            print("request read")
        } else {
            print("haven't discovered device yet")
        }
    }
    
    // MARK: - CBCentralManagerDelegate Methods    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        mainPeripheral = nil
        customiseNavigationBar()
        print("Disconnected" + peripheral.name!)
    }
    
    func alertBluetoothNotConnected() {
        let alertController = UIAlertController(title: "Zeta", message:
            "Error, please sitch on bluetooth", preferredStyle: UIAlertControllerStyle.alert)
        alertController.addAction(UIAlertAction(title: "Dismiss", style: UIAlertActionStyle.default,handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    
            switch central.state {
            case .poweredOn:
                print("powered on")
            case .poweredOff:
                print("powered off")
                alertBluetoothNotConnected()
            case .resetting:
                print("resetting")
            case .unauthorized:
                print("unauthorized")
            case .unsupported:
                print("unsupported")
            case .unknown:
                print("unknown")
            }
    }
    
    // MARK: CBPeripheralDelegate Methods
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service in peripheral.services! {
            print("Service found with UUID: " + service.uuid.uuidString)
            //device information service
            if (service.uuid.uuidString == BLEService) {
                peripheral.discoverCharacteristics(nil, for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (service.uuid.uuidString == BLEService) {
            for characteristic in service.characteristics! {
                print("charac: " + characteristic.uuid.uuidString)
                if (characteristic.uuid.uuidString == BLEwriteCharacteristic) {
                    //we'll save the reference, we need it to write data
                    writeCharacteristic = characteristic
                    //Set Notify is useful to read incoming data async
                   // peripheral.setNotifyValue(true, for: characteristic)
                    print("Found write Data Characteristic")
                }
                else if (characteristic.uuid.uuidString == BLEreadCharacteristic) {
                    //we'll save the reference, we need it to write data
                    readCharacteristic = characteristic
                    //Set Notify is useful to read incoming data async
                    peripheral.setNotifyValue(true, for: characteristic)
                    print("Found read Data Characteristic")
                }
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == readCharacteristic {
           // print(characteristic)
            treatedData(data: characteristic.value!)
//            if let data = NSString(data: characteristic.value!, encoding: String.Encoding.utf8.rawValue) {
//                print("Value Recieved: \(data)")
//            }
        }
    }
}

