//
//  CameraManager+ZoomButtons.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import AVFoundation
import SwiftUI

// MARK: - Zoom Buttons Support
extension CameraManager {
    /// Device manager for handling camera device discovery and zoom capabilities
    private static let deviceManager = CameraDeviceManager()
    
    /// Access to the shared device manager
    var deviceManager: CameraDeviceManager {
        Self.deviceManager
    }
    
    /// Gets available zoom factors for the current camera
    var availableZoomFactors: [CGFloat] {
        guard let currentDevice = getCurrentCameraDevice() else { return [1.0] }
        return calculateZoomFactors(for: currentDevice)
    }
    
    /// Sets zoom factor with smooth animation support
    func setZoomFactorSmooth(_ zoomFactor: CGFloat) {
        Task { @MainActor in
            do {
                try setCameraZoomFactor(zoomFactor)
            } catch {
                // Handle zoom error - could be logged or shown to user
                print("Failed to set zoom factor: \(error)")
            }
        }
    }
    
    /// Gets the current camera device
    private func getCurrentCameraDevice() -> AVCaptureDevice? {
        return getCameraInput()?.device as? AVCaptureDevice
    }
    
    /// Calculates appropriate zoom factors for a device based on Apple's camera app behavior
    private func calculateZoomFactors(for device: AVCaptureDevice) -> [CGFloat] {
        var factors: [CGFloat] = []
        
        // Define standard zoom levels that work well across different devices
        let potentialFactors: [CGFloat] = [0.5, 1.0, 2.0, 3.0, 5.0]
        
        for factor in potentialFactors {
            if factor >= device.minAvailableVideoZoomFactor &&
               factor <= device.maxAvailableVideoZoomFactor {
                factors.append(factor)
            }
        }
        
        // Add maximum zoom if it's significantly beyond our standard factors
        let maxZoom = device.maxAvailableVideoZoomFactor
        if maxZoom > 5.0 && !factors.contains(where: { abs($0 - maxZoom) < 0.5 }) {
            factors.append(maxZoom)
        }
        
        // Ensure we always have at least 1.0x
        if factors.isEmpty || !factors.contains(1.0) {
            factors = [1.0]
        }
        
        return factors.sorted()
    }
    
    /// Initializes camera device discovery
    func setupCameraDeviceDiscovery() {
        deviceManager.discoverCameras()
    }
    
    /// Updates the current camera in device manager when camera position changes
    func updateCurrentCameraDevice() {
        guard let currentDevice = getCurrentCameraDevice() else { return }
        
        // Find matching camera device in our discovered cameras
        if let matchingCamera = deviceManager.availableCameras.first(where: { 
            $0.device.uniqueID == currentDevice.uniqueID 
        }) {
            deviceManager.currentCamera = matchingCamera
        }
    }
}

// MARK: - Camera Device Capabilities
extension CameraManager {
    /// Checks if the device supports ultra-wide camera (0.5x zoom)
    var supportsUltraWide: Bool {
        availableZoomFactors.contains(0.5)
    }
    
    /// Checks if the device supports telephoto zoom (3x or higher)
    var supportsTelephoto: Bool {
        availableZoomFactors.contains { $0 >= 3.0 }
    }
    
    /// Gets the maximum available zoom factor
    var maxZoomFactor: CGFloat {
        getCurrentCameraDevice()?.maxAvailableVideoZoomFactor ?? 1.0
    }
    
    /// Gets the minimum available zoom factor
    var minZoomFactor: CGFloat {
        getCurrentCameraDevice()?.minAvailableVideoZoomFactor ?? 1.0
    }
}