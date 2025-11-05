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
        let device = { switch mediaType {
            case .audio:
                AVCaptureDevice.default(for: .audio)
            case .video where position == .front:
                AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
            case .video where position == .back:
                // Try to get a multi-camera device that includes ultra-wide
                AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) ??
                AVCaptureDevice.default(for: .video) // Fallback to default
            default:
                fatalError()
        }}()
        
//        guard let device else { return nil }
//        return try? .init(device: device) as? Self
      
      guard let device, let deviceInput = try? Self(device: device) else { return nil }
      return deviceInput
    }
}
