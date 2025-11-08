//
//  CameraDevice.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVFoundation
import SwiftUI

/// Represents a camera device with its zoom capabilities
struct CameraDevice: Identifiable, Equatable {
    let id = UUID()
    let device: AVCaptureDevice
    let displayName: String
    let zoomFactors: [CGFloat]
    let minZoom: CGFloat
    let maxZoom: CGFloat
    let position: AVCaptureDevice.Position
    
    static func == (lhs: CameraDevice, rhs: CameraDevice) -> Bool {
        lhs.device.uniqueID == rhs.device.uniqueID
    }
}

/// Manages discovery and configuration of available camera devices
@MainActor
class CameraDeviceManager: ObservableObject {
    @Published var availableCameras: [CameraDevice] = []
    @Published var currentCamera: CameraDevice?
    
    /// Discovers all available camera devices and their zoom capabilities
    func discoverCameras() {
        var cameras: [CameraDevice] = []
        
        // First, try to find the main virtual multi-camera device (iPhone 11+ back cameras)
        let virtualDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInTripleCamera,      // iPhone 11 Pro/12 Pro/13 Pro/14 Pro/15 Pro/16 Pro
                .builtInDualWideCamera,    // iPhone 11/12/13/14/15/16 with ultra-wide + wide
                .builtInDualCamera         // iPhone 7+/8+/X/XS with wide + telephoto
            ],
            mediaType: .video,
            position: .unspecified  // Changed from .back to include front cameras too
        )
        
        print("zoom: Found \(virtualDiscoverySession.devices.count) virtual devices")
        
        // Add virtual multi-camera devices first (these are the main ones we want)
        for device in virtualDiscoverySession.devices {
            print("zoom: Virtual Device - Type: \(device.deviceType.rawValue), Position: \(device.position.rawValue)")
            print("zoom: Virtual switchover factors: \(device.virtualDeviceSwitchOverVideoZoomFactors)")
            print("zoom: Constituent devices: \(device.constituentDevices.map { $0.deviceType.rawValue })")
            
            let zoomFactors = calculateZoomFactorsForDevice(device)
            let cameraDevice = CameraDevice(
                device: device,
                displayName: getCameraDisplayName(device),
                zoomFactors: zoomFactors,
                minZoom: device.minAvailableVideoZoomFactor,
                maxZoom: device.maxAvailableVideoZoomFactor,
                position: device.position
            )
            cameras.append(cameraDevice)
        }
        
        // If no virtual devices found, fall back to individual cameras
        if cameras.isEmpty {
            print("zoom: No virtual devices found, falling back to individual cameras")
            let individualDiscoverySession = AVCaptureDevice.DiscoverySession(
                deviceTypes: [
                    .builtInWideAngleCamera,
                    .builtInUltraWideCamera,
                    .builtInTelephotoCamera
                ],
                mediaType: .video,
                position: .unspecified
            )
            
            for device in individualDiscoverySession.devices {
                print("zoom: Individual Device - Type: \(device.deviceType.rawValue), Position: \(device.position.rawValue)")
                
                let zoomFactors = calculateZoomFactorsForDevice(device)
                let cameraDevice = CameraDevice(
                    device: device,
                    displayName: getCameraDisplayName(device),
                    zoomFactors: zoomFactors,
                    minZoom: device.minAvailableVideoZoomFactor,
                    maxZoom: device.maxAvailableVideoZoomFactor,
                    position: device.position
                )
                cameras.append(cameraDevice)
            }
        }
        
        availableCameras = cameras
        
        // Set current camera to back camera if available
        if let backCamera = cameras.first(where: { $0.position == .back }) {
            currentCamera = backCamera
            print("zoom: Set current camera to: \(backCamera.displayName) with zoom factors: \(backCamera.zoomFactors)")
        }
    }
    
    /// Calculates appropriate zoom factors for a device based on Apple's camera app behavior
    /// Uses virtualDeviceSwitchOverVideoZoomFactors to properly detect ultra-wide and telephoto zoom factors
    func calculateZoomFactorsForDevice(_ device: AVCaptureDevice) -> [CGFloat] {
        // Check if this is a virtual device (multi-camera system)
        if !device.virtualDeviceSwitchOverVideoZoomFactors.isEmpty {
            return calculateVirtualDeviceZoomFactors(for: device)
        }
        
        // Fallback for single camera devices
        return calculateStandardZoomFactors(for: device)
    }
    
    /// Internal method used during camera discovery
    private func calculateZoomFactors(for device: AVCaptureDevice) -> [CGFloat] {
        return calculateZoomFactorsForDevice(device)
    }
    
    /// Calculates zoom factors for virtual devices using switchover points
    private func calculateVirtualDeviceZoomFactors(for device: AVCaptureDevice) -> [CGFloat] {
        // Start with base zoom factor of 1
        let zoomFactors = [1.0] + device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
        print("zoom: zoomFactors: \(zoomFactors)")
        
        // Find the main wide-angle camera to determine the reference zoom factor
        guard let mainIndex = device.constituentDevices.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera }) else {
            print("zoom: No wide-angle camera found, falling back to standard calculation")
            return calculateStandardZoomFactors(for: device)
        }
        
        let mainZoomFactor = zoomFactors[mainIndex]
        print("zoom: mainZoomFactor: \(mainZoomFactor)")
        
        // Calculate relative zoom factors (this gives us the proper 0.5x, 1x, 3x values)
        let relativeFactors = zoomFactors.map { $0 / mainZoomFactor }
        print("zoom: relativeFactors: \(relativeFactors)")
        
        // For iPhone 16 and similar devices, add additional telephoto options beyond basic switchover points
        var expandedFactors = relativeFactors
        
        // Add common telephoto zoom levels if they're within device capability and not already present
        let commonZoomLevels: [CGFloat] = [2.0, 3.0, 5.0]
        for level in commonZoomLevels {
            if level <= device.maxAvailableVideoZoomFactor &&
               !expandedFactors.contains(where: { abs($0 - level) < 0.1 }) {
                expandedFactors.append(level)
            }
        }
        
        // For virtual devices, trust the switchover factors and include ultra-wide even if device reports different limits
        let filteredFactors = expandedFactors.filter { factor in
            // Always include factors that are switchover points, even if outside reported device limits
            let isSwitchoverPoint = abs(factor - 0.5) < 0.1 || // Ultra-wide
                                   abs(factor - 1.0) < 0.1 || // Wide
                                   abs(factor - 2.0) < 0.1 || // 2x telephoto
                                   abs(factor - 3.0) < 0.1 || // 3x telephoto
                                   abs(factor - 5.0) < 0.1    // 5x telephoto
            
            let withinDeviceLimits = factor >= device.minAvailableVideoZoomFactor &&
                                   factor <= device.maxAvailableVideoZoomFactor
            
            // For ultra-wide (0.5x), always include if we have ultra-wide camera
            let isUltraWide = abs(factor - 0.5) < 0.1 &&
                             device.constituentDevices.contains(where: { $0.deviceType == .builtInUltraWideCamera })
            
            let isValid = isSwitchoverPoint || withinDeviceLimits || isUltraWide
            print("zoom: Factor \(factor) - SwitchoverPoint: \(isSwitchoverPoint), WithinLimits: \(withinDeviceLimits), UltraWide: \(isUltraWide), Valid: \(isValid)")
            return isValid
        }.sorted()
        
        print("zoom: filteredFactors: \(filteredFactors)")
        return filteredFactors.isEmpty ? [1.0] : filteredFactors
    }
    
    /// Fallback calculation for non-virtual devices
    private func calculateStandardZoomFactors(for device: AVCaptureDevice) -> [CGFloat] {
        var factors: [CGFloat] = []
        
        // Standard zoom levels
        let standardFactors: [CGFloat] = [0.5, 1.0, 2.0, 3.0, 5.0]
        
        for factor in standardFactors {
            if factor >= device.minAvailableVideoZoomFactor &&
               factor <= device.maxAvailableVideoZoomFactor {
                factors.append(factor)
            }
        }
        
        return factors.isEmpty ? [1.0] : factors
    }
    
    /// Generates a user-friendly display name for a camera device
    private func getCameraDisplayName(_ device: AVCaptureDevice) -> String {
        let position = device.position == .back ? "Back" : "Front"
        let type: String
        
        switch device.deviceType {
        case .builtInUltraWideCamera:
            type = "Ultra Wide"
        case .builtInWideAngleCamera:
            type = "Wide"
        case .builtInTelephotoCamera:
            type = "Telephoto"
        case .builtInDualCamera:
            type = "Dual"
        case .builtInDualWideCamera:
            type = "Dual Wide"
        case .builtInTripleCamera:
            type = "Triple"
        default:
            type = "Camera"
        }
        
        return "\(position) \(type)"
    }
}
