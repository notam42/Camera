//
//  Tests+CameraDeviceZoomFactors.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import Testing
import AVFoundation
@testable import MijickCamera

@MainActor @Suite("Camera Device Zoom Factors Tests") struct CameraDeviceZoomFactorsTests {
    var deviceManager: CameraDeviceManager = CameraDeviceManager()
}

// MARK: - Virtual Device Zoom Factor Tests
extension CameraDeviceZoomFactorsTests {
    
    @Test("iPhone 14 Pro Max Triple Camera Zoom Factors") func testIPhone14ProMaxZoomFactors() async throws {
        // Simulate iPhone 14 Pro Max triple camera system
        let mockDevice = MockTripleCameraDevice(
            deviceType: .builtInTripleCamera,
            position: .back,
            virtualDeviceSwitchOverVideoZoomFactors: [2.0, 6.0], // Typical 14 Pro Max values
            constituentDevices: [
                MockConstituentDevice(deviceType: .builtInUltraWideCamera),
                MockConstituentDevice(deviceType: .builtInWideAngleCamera),
                MockConstituentDevice(deviceType: .builtInTelephotoCamera)
            ],
            minZoom: 0.5,
            maxZoom: 15.0
        )
        
        let zoomFactors = deviceManager.calculateZoomFactorsForDevice(mockDevice)
        
        // Expected: [0.5, 1.0, 3.0] for ultra-wide, wide, telephoto
        #expect(zoomFactors.contains(0.5), "Should include 0.5x for ultra-wide")
        #expect(zoomFactors.contains(1.0), "Should include 1.0x for wide")
        #expect(zoomFactors.contains(3.0), "Should include 3.0x for telephoto")
        #expect(zoomFactors.count == 3, "Should have exactly 3 zoom factors")
        #expect(zoomFactors == [0.5, 1.0, 3.0], "Zoom factors should be [0.5, 1.0, 3.0]")
    }
    
    @Test("iPhone 13 Pro Dual Wide Camera Zoom Factors") func testIPhone13ProDualWideZoomFactors() async throws {
        // Simulate iPhone 13 Pro dual wide camera system
        let mockDevice = MockTripleCameraDevice(
            deviceType: .builtInDualWideCamera,
            position: .back,
            virtualDeviceSwitchOverVideoZoomFactors: [2.0], // Single switchover point
            constituentDevices: [
                MockConstituentDevice(deviceType: .builtInUltraWideCamera),
                MockConstituentDevice(deviceType: .builtInWideAngleCamera)
            ],
            minZoom: 0.5,
            maxZoom: 10.0
        )
        
        let zoomFactors = deviceManager.calculateZoomFactorsForDevice(mockDevice)
        
        // Expected: [0.5, 1.0] for ultra-wide and wide
        #expect(zoomFactors.contains(0.5), "Should include 0.5x for ultra-wide")
        #expect(zoomFactors.contains(1.0), "Should include 1.0x for wide")
        #expect(zoomFactors.count == 2, "Should have exactly 2 zoom factors")
        #expect(zoomFactors == [0.5, 1.0], "Zoom factors should be [0.5, 1.0]")
    }
    
    @Test("iPhone 12 Dual Camera Zoom Factors") func testIPhone12DualCameraZoomFactors() async throws {
        // Simulate iPhone 12 dual camera system (no ultra-wide)
        let mockDevice = MockTripleCameraDevice(
            deviceType: .builtInDualCamera,
            position: .back,
            virtualDeviceSwitchOverVideoZoomFactors: [2.0], // Single switchover point
            constituentDevices: [
                MockConstituentDevice(deviceType: .builtInWideAngleCamera),
                MockConstituentDevice(deviceType: .builtInTelephotoCamera)
            ],
            minZoom: 1.0,
            maxZoom: 10.0
        )
        
        let zoomFactors = deviceManager.calculateZoomFactorsForDevice(mockDevice)
        
        // Expected: [1.0, 2.0] for wide and telephoto
        #expect(zoomFactors.contains(1.0), "Should include 1.0x for wide")
        #expect(zoomFactors.contains(2.0), "Should include 2.0x for telephoto")
        #expect(!zoomFactors.contains(0.5), "Should NOT include 0.5x (no ultra-wide)")
        #expect(zoomFactors.count == 2, "Should have exactly 2 zoom factors")
    }
    
    @Test("Single Camera Fallback Zoom Factors") func testSingleCameraZoomFactors() async throws {
        // Simulate older iPhone with single wide camera
        let mockDevice = MockSingleCameraDevice(
            deviceType: .builtInWideAngleCamera,
            position: .back,
            minZoom: 1.0,
            maxZoom: 5.0
        )
        
        let zoomFactors = deviceManager.calculateZoomFactorsForDevice(mockDevice)
        
        // Expected standard factors within device limits
        #expect(zoomFactors.contains(1.0), "Should include 1.0x")
        #expect(zoomFactors.contains(2.0), "Should include 2.0x")
        #expect(zoomFactors.contains(3.0), "Should include 3.0x")
        #expect(zoomFactors.contains(5.0), "Should include 5.0x")
        #expect(!zoomFactors.contains(0.5), "Should NOT include 0.5x (device doesn't support it)")
        #expect(zoomFactors.sorted() == [1.0, 2.0, 3.0, 5.0], "Should have standard zoom factors")
    }
    
    @Test("Front Camera Zoom Factors") func testFrontCameraZoomFactors() async throws {
        // Simulate front camera (typically single camera)
        let mockDevice = MockSingleCameraDevice(
            deviceType: .builtInWideAngleCamera,
            position: .front,
            minZoom: 1.0,
            maxZoom: 3.0
        )
        
        let zoomFactors = deviceManager.calculateZoomFactorsForDevice(mockDevice)
        
        // Front cameras typically have limited zoom
        #expect(zoomFactors.contains(1.0), "Should include 1.0x")
        #expect(zoomFactors.contains(2.0), "Should include 2.0x")
        #expect(zoomFactors.contains(3.0), "Should include 3.0x")
        #expect(!zoomFactors.contains(5.0), "Should NOT include 5.0x (exceeds max)")
        #expect(zoomFactors.count <= 3, "Front camera should have limited zoom factors")
    }
}

// MARK: - Edge Case Tests
extension CameraDeviceZoomFactorsTests {
    
    @Test("Device with Very Limited Zoom Range") func testLimitedZoomRange() async throws {
        let zoomFactors = deviceManager.calculateZoomFactorsForTestDevice(
            virtualSwitchOverFactors: [],
            constituentDevices: [],
            minZoom: 1.0,
            maxZoom: 1.5
        )
        
        // Should only include 1.0x since 2.0x exceeds max
        #expect(zoomFactors == [1.0], "Should only include 1.0x for limited zoom range")
    }
    
    @Test("Device with No Virtual Switchover Factors") func testNoVirtualSwitchoverFactors() async throws {
        let zoomFactors = deviceManager.calculateZoomFactorsForTestDevice(
            virtualSwitchOverFactors: [], // Empty array
            constituentDevices: [
                (deviceType: .builtInUltraWideCamera, index: 0),
                (deviceType: .builtInWideAngleCamera, index: 1),
                (deviceType: .builtInTelephotoCamera, index: 2)
            ],
            minZoom: 0.5,
            maxZoom: 15.0
        )
        
        // Should fallback to standard zoom calculation
        #expect(zoomFactors.contains(0.5), "Should include 0.5x from standard fallback")
        #expect(zoomFactors.contains(1.0), "Should include 1.0x from standard fallback")
        #expect(zoomFactors.contains(2.0), "Should include 2.0x from standard fallback")
    }
    
    @Test("Device with High Maximum Zoom") func testHighMaximumZoom() async throws {
        let zoomFactors = deviceManager.calculateZoomFactorsForTestDevice(
            virtualSwitchOverFactors: [],
            constituentDevices: [],
            minZoom: 1.0,
            maxZoom: 25.0
        )
        
        // Should include all standard factors within range
        #expect(zoomFactors.contains(1.0), "Should include 1.0x")
        #expect(zoomFactors.contains(2.0), "Should include 2.0x")
        #expect(zoomFactors.contains(3.0), "Should include 3.0x")
        #expect(zoomFactors.contains(5.0), "Should include 5.0x")
        #expect(zoomFactors.count == 4, "Should not include factors beyond 5.0x")
    }
}

// MARK: - Mock Camera Devices Protocol
protocol MockCaptureDevice {
    var deviceType: AVCaptureDevice.DeviceType { get }
    var position: AVCaptureDevice.Position { get }
    var virtualDeviceSwitchOverVideoZoomFactors: [NSNumber] { get }
    var constituentDevices: [MockCaptureDevice] { get }
    var minAvailableVideoZoomFactor: CGFloat { get }
    var maxAvailableVideoZoomFactor: CGFloat { get }
    var uniqueID: String { get }
}

// MARK: - Mock Camera Device Implementations
extension CameraDeviceZoomFactorsTests {
    
    /// Mock virtual camera device (e.g., triple camera)
    struct MockTripleCameraDevice: MockCaptureDevice {
        let deviceType: AVCaptureDevice.DeviceType
        let position: AVCaptureDevice.Position
        let virtualDeviceSwitchOverVideoZoomFactors: [NSNumber]
        let constituentDevices: [MockCaptureDevice]
        let minAvailableVideoZoomFactor: CGFloat
        let maxAvailableVideoZoomFactor: CGFloat
        let uniqueID: String
        
        init(deviceType: AVCaptureDevice.DeviceType,
             position: AVCaptureDevice.Position,
             virtualDeviceSwitchOverVideoZoomFactors: [CGFloat],
             constituentDevices: [MockCaptureDevice],
             minZoom: CGFloat,
             maxZoom: CGFloat) {
            self.deviceType = deviceType
            self.position = position
            self.virtualDeviceSwitchOverVideoZoomFactors = virtualDeviceSwitchOverVideoZoomFactors.map { NSNumber(value: $0) }
            self.constituentDevices = constituentDevices
            self.minAvailableVideoZoomFactor = minZoom
            self.maxAvailableVideoZoomFactor = maxZoom
            self.uniqueID = "mock-\(deviceType.rawValue)-\(position.rawValue)"
        }
    }
    
    /// Mock single camera device
    struct MockSingleCameraDevice: MockCaptureDevice {
        let deviceType: AVCaptureDevice.DeviceType
        let position: AVCaptureDevice.Position
        let virtualDeviceSwitchOverVideoZoomFactors: [NSNumber] = []
        let constituentDevices: [MockCaptureDevice] = []
        let minAvailableVideoZoomFactor: CGFloat
        let maxAvailableVideoZoomFactor: CGFloat
        let uniqueID: String
        
        init(deviceType: AVCaptureDevice.DeviceType,
             position: AVCaptureDevice.Position,
             minZoom: CGFloat,
             maxZoom: CGFloat) {
            self.deviceType = deviceType
            self.position = position
            self.minAvailableVideoZoomFactor = minZoom
            self.maxAvailableVideoZoomFactor = maxZoom
            self.uniqueID = "mock-single-\(deviceType.rawValue)-\(position.rawValue)"
        }
    }
    
    /// Mock constituent device for virtual cameras
    struct MockConstituentDevice: MockCaptureDevice {
        let deviceType: AVCaptureDevice.DeviceType
        let position: AVCaptureDevice.Position = .unspecified
        let virtualDeviceSwitchOverVideoZoomFactors: [NSNumber] = []
        let constituentDevices: [MockCaptureDevice] = []
        let minAvailableVideoZoomFactor: CGFloat = 1.0
        let maxAvailableVideoZoomFactor: CGFloat = 1.0
        let uniqueID: String
        
        init(deviceType: AVCaptureDevice.DeviceType) {
            self.deviceType = deviceType
            self.uniqueID = "mock-constituent-\(deviceType.rawValue)"
        }
    }
}
