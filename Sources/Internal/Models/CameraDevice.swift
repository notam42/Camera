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
            position: .unspecified
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
    private func calculateZoomFactors(for device: AVCaptureDevice) -> [CGFloat] {
        var factors: [CGFloat] = []
        
        // Standard zoom levels that match Apple's Camera app
        let standardFactors: [CGFloat] = [0.5, 1.0, 2.0, 3.0, 5.0]
        
        for factor in standardFactors {
            if factor >= device.minAvailableVideoZoomFactor &&
               factor <= device.maxAvailableVideoZoomFactor {
                factors.append(factor)
            }
        }
        
        // Add maximum zoom if it's beyond 5x and significantly different
        if device.maxAvailableVideoZoomFactor > 5.0 {
            let maxZoom = device.maxAvailableVideoZoomFactor
            if !factors.contains(where: { abs($0 - maxZoom) < 0.1 }) {
                factors.append(maxZoom)
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