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
        // First, ensure device discovery has been done
        if deviceManager.availableCameras.isEmpty {
            deviceManager.discoverCameras()
        }
        
        // Try to use discovered virtual device for the current camera position
        let currentPosition = attributes.cameraPosition
        if let discoveredCamera = deviceManager.availableCameras.first(where: { $0.position == currentPosition }) {
            print("zoom: Using discovered camera zoom factors for \(currentPosition): \(discoveredCamera.zoomFactors)")
            return discoveredCamera.zoomFactors
        }
        
        // Fallback: calculate from current session device
        guard let currentDevice = getCurrentCameraDevice() else {
            print("zoom: No current device, using fallback [1.0]")
            return [1.0]
        }
        
        print("zoom: Fallback: calculating zoom factors for session device: \(currentDevice.uniqueID)")
        let factors = deviceManager.calculateZoomFactorsForDevice(currentDevice)
        print("zoom: Fallback calculated factors: \(factors)")
        return factors
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
