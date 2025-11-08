//
//  MCameraScreen+ZoomButtons.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

// MARK: - Zoom Buttons Integration
public extension MCameraScreen {
    /**
     Creates zoom buttons view that displays available zoom factors for the current camera.
     
     The zoom buttons automatically appear and hide based on user interaction, similar to Apple's Camera app.
     When a zoom button is tapped, the camera smoothly transitions to that zoom level.

     ## Usage
     ```swift
     struct CustomCameraScreen: MCameraScreen {
        @ObservedObject var cameraManager: CameraManager
        let namespace: Namespace.ID
        let closeMCameraAction: () -> ()

        var body: some View {
            ZStack {
                createCameraOutputView()
                createZoomButtons()
            }
        }
     }
     ```
     */
    func createZoomButtons() -> some View {
        CameraZoomControls(
            zoomFactors: cameraManager.availableZoomFactors,
            currentZoomFactor: zoomFactor,
            onZoomChange: { factor in
                cameraManager.setZoomFactorSmooth(factor)
            }
        )
        .onAppear {
            // Initialize camera device discovery when zoom buttons appear
            cameraManager.setupCameraDeviceDiscovery()
        }
        .onChange(of: cameraPosition) { _ in
            // Update current camera device when position changes
            cameraManager.updateCurrentCameraDevice()
        }
    }
    
    /**
     Creates a simple horizontal row of zoom buttons without auto-hide functionality.
     
     This is useful when you want the zoom buttons to be always visible or control their visibility manually.

     ## Usage
     ```swift
     VStack {
         createCameraOutputView()
         createSimpleZoomButtons()
             .padding(.bottom, 20)
     }
     ```
     */
    func createSimpleZoomButtons() -> some View {
        ZoomButtonsView(
            zoomFactors: cameraManager.availableZoomFactors,
            currentZoomFactor: zoomFactor,
            onZoomChange: { factor in
                cameraManager.setZoomFactorSmooth(factor)
            }
        )
        .onAppear {
            cameraManager.setupCameraDeviceDiscovery()
        }
    }
}

// MARK: - Camera Information Access
public extension MCameraScreen {
    /// Current zoom factor of the camera
    //var zoomFactor: CGFloat { cameraManager.attributes.zoomFactor }
    
    /// Current camera position (front/back)
    //var cameraPosition: CameraPosition { cameraManager.attributes.cameraPosition }
    
    /// Available zoom factors for the current camera
    var availableZoomFactors: [CGFloat] { cameraManager.availableZoomFactors }
    
    /// Whether the current device supports ultra-wide camera (0.5x)
    var supportsUltraWide: Bool { cameraManager.supportsUltraWide }
    
    /// Whether the current device supports telephoto camera (3x or higher)
    var supportsTelephoto: Bool { cameraManager.supportsTelephoto }
    
    /// Maximum available zoom factor for the current camera
    var maxZoomFactor: CGFloat { cameraManager.maxZoomFactor }
    
    /// Minimum available zoom factor for the current camera
    var minZoomFactor: CGFloat { cameraManager.minZoomFactor }
}
