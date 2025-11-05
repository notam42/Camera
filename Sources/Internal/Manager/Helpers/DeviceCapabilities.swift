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
              
              // Check if this is a multi-camera device with ultra-wide
              let hasUltraWideHardware = hasUltraWideCamera()
              let hasTelephoto = device.maxAvailableVideoZoomFactor >= 2.0
              
              print("   hasUltraWideHardware: \(hasUltraWideHardware)")
              print("   hasTelephoto: \(hasTelephoto)")
              
              // For multi-camera devices, always include 0.5x even if minZoom reports 1.0
              if hasUltraWideHardware {
                  factors.append(0.5)
              }
              
              factors.append(1.0) // Always available
              
              if hasTelephoto {
                  factors.append(2.0)
              }
              
              if device.maxAvailableVideoZoomFactor >= 3.0 {
                  factors.append(3.0)
              }
              
              print("   Final factors: \(factors)")
              
              return factors
          }
          
          // ADD THIS METHOD - Check if device has ultra-wide camera hardware
          static func hasUltraWideCamera() -> Bool {
              // Check for ultra-wide camera availability
              if AVCaptureDevice.default(.builtInUltraWideCamera, for: .video, position: .back) != nil {
                  return true
              }
              
              // Check for multi-camera devices that include ultra-wide
              if let multiCamera = AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) {
                  return multiCamera.constituentDevices.contains { $0.deviceType == .builtInUltraWideCamera }
              }
              
              if let dualWideCamera = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
                  return dualWideCamera.constituentDevices.contains { $0.deviceType == .builtInUltraWideCamera }
              }
              
              return false
          }
          
          // ADD THIS METHOD - Map actual zoom level to logical zoom level
          static func getLogicalZoomFactor(from device: CaptureDevice) -> CGFloat {
              let physicalZoom = device.videoZoomFactor
              
              // If we have ultra-wide hardware and we're at the default zoom level
              if hasUltraWideCamera() && physicalZoom == 1.0 {
                  // The device reports 1.0 but we're actually at ultra-wide (0.5x logical)
                  return 0.5
              }
              
              return physicalZoom
          }
          
          static var isMultiCameraDevice: Bool {
              return AVCaptureDevice.default(.builtInTripleCamera, for: .video, position: .back) != nil ||
                     AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) != nil ||
                     AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) != nil
          }
}
