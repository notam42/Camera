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
        
        // Discover all available camera devices
        let discoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [
                .builtInWideAngleCamera,
                .builtInUltraWideCamera,
                .builtInTelephotoCamera,
                .builtInDualCamera,
                .builtInDualWideCamera,
                .builtInTripleCamera
            ],
            mediaType: .video,
            position: .back//.unspecified
        )
        
        for device in discoverySession.devices {
            let zoomFactors = calculateZoomFactors(for: device)
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
        
        availableCameras = cameras
        
        // Set current camera to back camera if available
        if let backCamera = cameras.first(where: { $0.position == .back }) {
            currentCamera = backCamera
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
            return calculateStandardZoomFactors(for: device)
        }
        
        let mainZoomFactor = zoomFactors[mainIndex]
        print("zoom: mainZoomFactor: \(mainZoomFactor)")
        // Calculate relative zoom factors (this gives us the proper 0.5x, 1x, 3x values)
        let relativeFactors = zoomFactors.map { $0 / mainZoomFactor }
        
        // Filter and sort the factors
        let filteredFactors = relativeFactors.filter { factor in
            factor >= device.minAvailableVideoZoomFactor &&
            factor <= device.maxAvailableVideoZoomFactor
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
