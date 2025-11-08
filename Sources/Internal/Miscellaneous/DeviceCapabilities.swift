//
//  DeviceCapabilities.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVFoundation

/// Utility class for detecting device capabilities and handling zoom factor conversions
struct DeviceCapabilities {
    
    /// Checks if the current device has an ultra-wide camera
    static func hasUltraWideCamera() -> Bool {
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInDualWideCamera,
                .builtInTripleCamera
            ],
            mediaType: .video,
            position: .back
        )
        
        // Check if any device has constituent ultra-wide camera
        for device in discoverySession.devices {
            if device.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) {
                return true
            }
        }
        
        return false
    }
    
    /// Gets the logical zoom factor from a physical device zoom factor
    /// For virtual devices, this converts the actual device zoom back to the logical zoom level
    static func getLogicalZoomFactor(from device: any CaptureDevice) -> CGFloat {
        guard let avDevice = device as? AVCaptureDevice else {
            return device.videoZoomFactor
        }
        
        // For virtual devices with ultra-wide, convert physical zoom back to logical zoom
        if !avDevice.virtualDeviceSwitchOverVideoZoomFactors.isEmpty &&
           avDevice.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) {
            
            let physicalZoom = avDevice.videoZoomFactor
            
            // Find the main wide-angle camera reference point
            let zoomFactors = [1.0] + avDevice.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
            guard let mainIndex = avDevice.constituentDevices.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera }) else {
                return physicalZoom
            }
            
            let mainZoomFactor = zoomFactors[mainIndex]
            
            // Convert physical zoom to logical zoom
            return physicalZoom / mainZoomFactor
        }
        
        // For single cameras or devices without ultra-wide, use physical zoom directly
        return avDevice.videoZoomFactor
    }
    
    /// Gets the physical zoom factor from a logical zoom factor
    /// This is used when setting zoom on virtual devices
    static func getPhysicalZoomFactor(from logicalZoom: CGFloat, device: any CaptureDevice) -> CGFloat {
        guard let avDevice = device as? AVCaptureDevice else {
            return logicalZoom
        }
        
        // For virtual devices with ultra-wide, convert logical zoom to physical zoom
        if !avDevice.virtualDeviceSwitchOverVideoZoomFactors.isEmpty &&
           avDevice.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera }) {
            
            // Find the main wide-angle camera reference point
            let zoomFactors = [1.0] + avDevice.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
            guard let mainIndex = avDevice.constituentDevices.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera }) else {
                return logicalZoom
            }
            
            let mainZoomFactor = zoomFactors[mainIndex]
            
            // Convert logical zoom to physical zoom
            return logicalZoom * mainZoomFactor
        }
        
        // For single cameras or devices without ultra-wide, use logical zoom directly
        return logicalZoom
    }
}