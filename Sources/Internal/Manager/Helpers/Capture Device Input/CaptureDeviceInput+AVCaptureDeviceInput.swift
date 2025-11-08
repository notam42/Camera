//
//  CaptureDeviceInput+AVCaptureDeviceInput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVKit
/*
// Debug
extension AVCaptureDeviceInput: CaptureDeviceInput {
    static func get(mediaType: AVMediaType, position: AVCaptureDevice.Position?) -> Self? {
        let device = { switch mediaType {
            case .audio: AVCaptureDevice.default(for: .audio)
            case .video where position == .front: AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            case .video where position == .back: AVCaptureDevice.default(for: .video)
            default: fatalError()
        }}()

        guard let device, let deviceInput = try? Self(device: device) else { return nil }
        return deviceInput
    }
}
*/
extension AVCaptureDeviceInput: CaptureDeviceInput {
    static func get(mediaType: AVMediaType, position: AVCaptureDevice.Position?) -> Self? {
        let device: AVCaptureDevice? = {
            switch mediaType {
            case .audio:
                return AVCaptureDevice.default(for: .audio)
            case .video where position == .front:
                return AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            case .video where position == .back:
                // Use the same device discovery logic as CameraManager
                print("zoom: Device selection - using discovery session approach")
                
                let deviceTypes: [AVCaptureDevice.DeviceType] = [
                    .builtInTripleCamera,
                    .builtInDualWideCamera,
                    .builtInDualCamera,
                    .builtInWideAngleCamera,
                ]
                
                let discoverySession = AVCaptureDevice.DiscoverySession(
                    deviceTypes: deviceTypes,
                    mediaType: .video,
                    position: .back
                )
                
                print("zoom: Available devices from discovery session:")
                for (index, device) in discoverySession.devices.enumerated() {
                    print("zoom: [\(index)] \(device.deviceType.rawValue)")
                }
                
                let selectedDevice = discoverySession.devices.first
                print("zoom: Selected device: \(selectedDevice?.deviceType.rawValue ?? "none")")
                
                return selectedDevice
            default:
                fatalError()
            }
        }()
        
        guard let device, let deviceInput = try? Self(device: device) else { return nil }
        return deviceInput
    }
}
