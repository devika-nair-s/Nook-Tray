import Foundation
import Combine
import AppKit

class BluetoothBatteryManager: ObservableObject {
    static let shared = BluetoothBatteryManager()
    
    @Published var isConnected: Bool = false
    @Published var deviceName: String = ""
    @Published var batteryPercentage: Int? = nil
    @Published var batteryFormattedText: String = ""
    
    private var timer: Timer?
    
    init() {
        fetchBatteryInfo()
        // Poll for bluetooth battery state changes every 8 seconds
        timer = Timer.scheduledTimer(withTimeInterval: 8.0, repeats: true) { [weak self] _ in
            self?.fetchBatteryInfo()
        }
    }
    
    func fetchBatteryInfo() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            process.arguments = ["SPBluetoothDataType", "-json"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                process.waitUntilExit()
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let btArray = json["SPBluetoothDataType"] as? [[String: Any]] {
                    
                    var foundDeviceName = ""
                    var foundBattery: Int? = nil
                    var foundFormatted = ""
                    var connected = false
                    
                    for section in btArray {
                        if let connectedDevices = section["device_connected"] as? [[String: [String: Any]]] {
                            for dict in connectedDevices {
                                for (name, props) in dict {
                                    let minorType = props["device_minorType"] as? String ?? ""
                                    let isAudio = minorType.contains("Headset") || minorType.contains("Headphone") || minorType.contains("Audio") || minorType.contains("Ear")
                                    
                                    // Parse main battery or individual left/right/case
                                    let mainStr = props["device_batteryLevelMain"] as? String
                                        ?? props["device_batteryPercent"] as? String
                                        ?? props["device_batteryLevelCombined"] as? String
                                    let leftStr = props["device_batteryLevelLeft"] as? String
                                    let rightStr = props["device_batteryLevelRight"] as? String
                                    
                                    if let left = leftStr, let right = rightStr {
                                        let leftNum = Int(left.filter { "0123456789".contains($0) }) ?? 0
                                        let rightNum = Int(right.filter { "0123456789".contains($0) }) ?? 0
                                        if leftNum == rightNum {
                                            foundBattery = leftNum
                                            foundFormatted = "\(leftNum)%"
                                        } else {
                                            foundBattery = min(leftNum, rightNum)
                                            foundFormatted = "L:\(leftNum)% R:\(rightNum)%"
                                        }
                                        foundDeviceName = name
                                        connected = true
                                        break
                                    } else if let main = mainStr {
                                        let num = Int(main.filter { "0123456789".contains($0) })
                                        foundBattery = num
                                        foundFormatted = num != nil ? "\(num!)%" : main
                                        foundDeviceName = name
                                        connected = true
                                        break
                                    } else if isAudio {
                                        foundDeviceName = name
                                        foundFormatted = "Connected"
                                        connected = true
                                        break
                                    }
                                }
                                if connected { break }
                            }
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self?.isConnected = connected
                        self?.deviceName = foundDeviceName
                        self?.batteryPercentage = foundBattery
                        self?.batteryFormattedText = foundFormatted
                    }
                }
            } catch {
                // Ignore background polling errors
            }
        }
    }
}
