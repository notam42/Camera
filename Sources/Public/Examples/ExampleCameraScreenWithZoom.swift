//
//  ExampleCameraScreenWithZoom.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

/// Example implementation showing how to use zoom buttons in a custom camera screen
struct ExampleCameraScreenWithZoom: MCameraScreen {
    @ObservedObject var cameraManager: CameraManager
    let namespace: Namespace.ID
    let closeMCameraAction: () -> ()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Camera preview
            createCameraOutputView()
                .ignoresSafeArea()
            
            // Camera UI overlay
            VStack {
                // Top controls
                createTopControls()
                
                Spacer()
                
                // Zoom buttons - automatically show/hide like Apple's Camera app
                createZoomButtons()
                
                // Bottom controls
                createBottomControls()
            }
        }
    }
}

// MARK: - UI Components
private extension ExampleCameraScreenWithZoom {
    /// Creates the top navigation bar with close and flash controls
    func createTopControls() -> some View {
        HStack {
            // Close button
            Button(action: closeMCameraAction) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
            
            Spacer()
            
            // Flash toggle button
            Button(action: toggleFlash) {
                Image(systemName: flashIcon)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
                    .background(Color.black.opacity(0.3))
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
    
    /// Creates the bottom controls with capture button and camera switch
    func createBottomControls() -> some View {
        HStack(spacing: 40) {
            // Camera position toggle
            Button(action: switchCamera) {
                Image(systemName: "arrow.triangle.2.circlepath.camera")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                    .frame(width: 44, height: 44)
            }
            
            // Capture button
            Button(action: captureOutput) {
                Circle()
                    .fill(Color.white)
                    .frame(width: 70, height: 70)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                            .frame(width: 80, height: 80)
                    )
            }
            
            // Media gallery (placeholder)
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
        .padding(.bottom, 34)
    }
}

// MARK: - Actions
private extension ExampleCameraScreenWithZoom {
    /// Toggles flash mode
    func toggleFlash() {
        let currentFlash = cameraManager.attributes.flashMode
        let newFlash: CameraFlashMode = currentFlash == .off ? .on : .off
        setFlashMode(newFlash)
    }
    
    /// Switches between front and back camera
    func switchCamera() {
        let newPosition: CameraPosition = cameraPosition == .back ? .front : .back
        Task {
            try? await setCameraPosition(newPosition)
        }
    }
    
    /// Icon name for current flash state
    var flashIcon: String {
        switch cameraManager.attributes.flashMode {
        case .off: return "bolt.slash"
        case .on: return "bolt.fill"
        case .auto: return "bolt.badge.automatic"
        }
    }
}

// MARK: - Alternative Implementation with Always-Visible Zoom Buttons
struct ExampleCameraScreenWithAlwaysVisibleZoom: MCameraScreen {
    @ObservedObject var cameraManager: CameraManager
    let namespace: Namespace.ID
    let closeMCameraAction: () -> ()
    
    var body: some View {
        VStack(spacing: 0) {
            // Camera preview
            createCameraOutputView()
            
            // Always-visible zoom buttons
            if !availableZoomFactors.isEmpty {
                createSimpleZoomButtons()
                    .padding(.vertical, 20)
                    .background(Color.black)
            }
            
            // Bottom controls
            HStack {
                Button("Close", action: closeMCameraAction)
                    .foregroundColor(.white)
                
                Spacer()
                
                Button("Capture", action: captureOutput)
                    .foregroundColor(.white)
                    .font(.headline)
                
                Spacer()
                
                Button("Switch", action: {
                    Task {
                        let newPosition: CameraPosition = cameraPosition == .back ? .front : .back
                        try? await setCameraPosition(newPosition)
                    }
                })
                .foregroundColor(.white)
            }
            .padding()
            .background(Color.black)
        }
    }
}

//#if DEBUG
///// Preview for the example camera screen
//struct ExampleCameraScreenWithZoom_Previews: PreviewProvider {
//    static var previews: some View {
//        // Note: This is just for UI preview - actual camera functionality requires device
//        ExampleCameraScreenWithZoom(
//            cameraManager: CameraManager(
//                captureSession: MockCaptureSession(),
//                captureDeviceInputType: MockCaptureDeviceInput.self
//            ),
//            namespace: Namespace().wrappedValue,
//            closeMCameraAction: {}
//        )
//    }
//}
//
//// Mock classes for preview
//private class MockCaptureSession: CaptureSession {
//    var isRunning: Bool = false
//    func startRunning() {}
//    func stopRunning() {}
//    func beginConfiguration() {}
//    func commitConfiguration() {}
//    func canAddInput(_ input: any CaptureInput) -> Bool { true }
//    func addInput(_ input: any CaptureInput) {}
//    func removeInput(_ input: any CaptureInput) {}
//    func canAddOutput(_ output: any CaptureOutput) -> Bool { true }
//    func addOutput(_ output: any CaptureOutput) {}
//    func removeOutput(_ output: any CaptureOutput) {}
//    var inputs: [any CaptureInput] = []
//    var outputs: [any CaptureOutput] = []
//}
//
//private class MockCaptureDeviceInput: CaptureDeviceInput {
//    var device: (any CaptureDevice)?
//    static func get(mediaType: AVMediaType, position: AVCaptureDevice.Position) -> (any CaptureDeviceInput)? {
//        return MockCaptureDeviceInput()
//    }
//}
//#endif
