//
//  DeviceCapabilities.swift
//  MijickCamera
//
//  Created by Manuel Winter on 05.11.25.
//


import AVFoundation
import UIKit

struct DeviceCapabilities {
    static func getAvailableZoomFactors(for device: CaptureDevice) -> [CGFloat] {
        var factors: [CGFloat] = []
        
        // Check device model for specific capabilities
        let deviceModel = UIDevice.current.model
        let hasUltraWide = device.minAvailableVideoZoomFactor < 1.0
        let hasTelephoto = device.maxAvailableVideoZoomFactor > 2.0
        
        if hasUltraWide {
            factors.append(0.5)
        }
        
        factors.append(1.0) // Always available
        
        if hasTelephoto {
            factors.append(2.0)
        }
        
        return factors
    }
    
    static var isMultiCameraDevice: Bool {
        return AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil ||
               AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil ||
               AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil
    }
}
