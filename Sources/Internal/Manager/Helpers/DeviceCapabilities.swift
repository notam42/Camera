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
              
              // Add debugging to see actual values
              print("🔍 Debug Zoom Detection:")
              print("   minAvailableVideoZoomFactor: \(device.minAvailableVideoZoomFactor)")
              print("   maxAvailableVideoZoomFactor: \(device.maxAvailableVideoZoomFactor)")
              
              // More precise check for ultra-wide
              let hasUltraWide = device.minAvailableVideoZoomFactor <= 0.5
              let hasTelephoto = device.maxAvailableVideoZoomFactor >= 2.0
              
              print("   hasUltraWide: \(hasUltraWide)")
              print("   hasTelephoto: \(hasTelephoto)")
              
              if hasUltraWide {
                  factors.append(0.5)
              }
              
              factors.append(1.0) // Always available
              
              if hasTelephoto {
                  factors.append(2.0)
              }
              
              // Add more zoom levels if available
              if device.maxAvailableVideoZoomFactor >= 3.0 {
                  factors.append(3.0)
              }
              
              print("   Final factors: \(factors)")
              
              return factors
    }
    
    static var isMultiCameraDevice: Bool {
        return AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil ||
               AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil ||
               AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil
    }
}
