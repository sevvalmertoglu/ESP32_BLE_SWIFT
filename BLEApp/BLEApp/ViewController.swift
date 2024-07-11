//
//  ViewController.swift
//  BLEApp
//
//  Created by Şevval Mertoğlu on 10.07.2024.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController, CBCentralManagerDelegate, CBPeripheralDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    var centralManager: CBCentralManager!
    var targetPeripheral: CBPeripheral?
    var characteristic: CBCharacteristic?
    var peripherals: [(peripheral: CBPeripheral, name: String)] = []

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
        tableView.delegate = self
        tableView.dataSource = self
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
            if central.state == .poweredOn {
                // Bluetooth açık, cihazları ara
                centralManager.scanForPeripherals(withServices: nil, options: nil)
                print("Scanning for peripherals...")
            } else {
                // Bluetooth kapalı veya kullanılamaz durumda
                print("Bluetooth kullanılamaz durumda")
            }
        }
        
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
            // Bulunan cihazları listeye ekle
            let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? peripheral.name ?? "Bilinmeyen"
            if !peripherals.contains(where: { $0.peripheral == peripheral }) {
                peripherals.append((peripheral: peripheral, name: name))
                tableView.reloadData()
                print("Discovered peripheral: \(name)")
            }
        }

        func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
            // Cihaza bağlandık, servisleri keşfet
            peripheral.discoverServices(nil)
            
            // Bağlantı başarılı olduğunda alert göster
            let alert = UIAlertController(title: "Bağlantı Başarılı", message: "\(peripheral.name ?? "Cihaz") Bluetooth'a bağlandı.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Tamam", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            
            print("Connected to peripheral: \(peripheral.name ?? "Unknown")")
                
        }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
            print("Failed to connect to peripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "unknown error")")
        }

        func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
            print("Disconnected from peripheral: \(peripheral.name ?? "Unknown"), error: \(error?.localizedDescription ?? "unknown error")")
        }


        func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
            if let services = peripheral.services {
                for service in services {
                    peripheral.discoverCharacteristics(nil, for: service)
                    print("Discovered service: \(service.uuid)")
                }
            }
        }

        func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
            if let characteristics = service.characteristics {
                for char in characteristics {
                    if char.properties.contains(.write) {
                        characteristic = char
                        print("Found writable characteristic: \(char.uuid)")
                    }
                }
            }
        }
    
    @IBAction func onButtonTapped(_ sender: Any) {
        sendCommand(command: "ON")
    }
    
    @IBAction func offButtonTapped(_ sender: Any) {
        sendCommand(command: "OFF")
    }
    
    func sendCommand(command: String) {
        if let char = characteristic, let data = command.data(using: .utf8) {
            targetPeripheral?.writeValue(data, for: char, type: .withResponse)
            print("Sent command: \(command)")
        }
    }
    
    // UITableViewDataSource metodları
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            return peripherals.count
        }
        
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
          let cell = tableView.dequeueReusableCell(withIdentifier: "BluetoothDeviceCell", for: indexPath)
          let peripheralInfo = peripherals[indexPath.row]
          cell.textLabel?.text = peripheralInfo.name
          return cell
      }
        
    // UITableViewDelegate metodu
       func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
           let peripheralInfo = peripherals[indexPath.row]
           targetPeripheral = peripheralInfo.peripheral
           targetPeripheral!.delegate = self
           centralManager.stopScan()
           centralManager.connect(targetPeripheral!, options: nil)
           
           print("Selected peripheral: \(peripheralInfo.name)")
       }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        70
    }
}

