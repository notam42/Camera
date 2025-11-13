//
//  CameraManager.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI
import AVKit

@MainActor public class CameraManager: NSObject, ObservableObject {
    @Published var attributes: CameraManagerAttributes = .init()

    // MARK: Input
    private(set) var captureSession: any CaptureSession
    private(set) var frontCameraInput: (any CaptureDeviceInput)?
    private(set) var backCameraInput: (any CaptureDeviceInput)?

    // MARK: Output
    private(set) var photoOutput: CameraManagerPhotoOutput = .init()
    private(set) var videoOutput: CameraManagerVideoOutput = .init()

    // MARK: UI Elements
    private(set) var cameraView: UIView!
    private(set) var cameraLayer: AVCaptureVideoPreviewLayer = .init()
    private(set) var cameraMetalView: CameraMetalView = .init()
    private(set) var cameraGridView: CameraGridView = .init()

    // MARK: Others
    private(set) var permissionsManager: CameraManagerPermissionsManager = .init()
    private(set) var motionManager: CameraManagerMotionManager = .init()
    private(set) var notificationCenterManager: CameraManagerNotificationCenter = .init()

    // MARK: Initializer
    init<CS: CaptureSession, CDI: CaptureDeviceInput>(captureSession: CS, captureDeviceInputType: CDI.Type) {
        self.captureSession = captureSession
        self.frontCameraInput = CDI.get(mediaType: .video, position: .front)
        self.backCameraInput = CDI.get(mediaType: .video, position: .back)
    }
}

// MARK: Initialize
extension CameraManager {
    func initialize(in view: UIView) {
        cameraView = view
    }
}

// MARK: Setup
extension CameraManager {
    func setup() async throws(MCameraError) {
        try await permissionsManager.requestAccess(parent: self)

        setupCameraLayer()
        try setupDeviceInputs()
        try setupDeviceOutput()
        try setupFrameRecorder()
        notificationCenterManager.setup(parent: self)
        motionManager.setup(parent: self)
        try cameraMetalView.setup(parent: self)
        cameraGridView.setup(parent: self)

        startSession()
    }
}
private extension CameraManager {
    func setupCameraLayer() {
        captureSession.sessionPreset = attributes.resolution

        cameraLayer.session = captureSession as? AVCaptureSession
        cameraLayer.videoGravity = .resizeAspectFill
        cameraLayer.isHidden = true
        cameraView.layer.addSublayer(cameraLayer)
    }
    func setupDeviceInputs() throws(MCameraError) {
        try captureSession.add(input: getCameraInput())
        if let audioInput = getAudioInput() { try captureSession.add(input: audioInput) }
    }
    func setupDeviceOutput() throws(MCameraError) {
        try photoOutput.setup(parent: self)
        try videoOutput.setup(parent: self)
    }
    func setupFrameRecorder() throws(MCameraError) {
        let captureVideoOutput = AVCaptureVideoDataOutput()
        captureVideoOutput.setSampleBufferDelegate(cameraMetalView, queue: .main)

        try captureSession.add(output: captureVideoOutput)
    }
    func startSession() { Task {
        guard let device = getCameraInput()?.device else { return }

        try await startCaptureSession()
        try setupDevice(device)
        
        // Set initial zoom to 1.0x BEFORE reading attributes to avoid timing issues
        setInitialZoomLevel()
        
        // Now reset attributes after zoom is properly set
        resetAttributes(device: device, preserveZoom: true)
        
        cameraMetalView.performCameraEntranceAnimation()
    }}
}

// MARK: - Initial Camera Setup
private extension CameraManager {
    /// Sets the initial zoom level to 1.0x (normal wide camera view) on app startup
    func setInitialZoomLevel() {
        guard let device = getCameraInput()?.device else {
            print("zoom: No device available for initial zoom setup")
            return
        }
        
        // Set initial zoom to 1.0x (normal wide camera view)
        let initialLogicalZoom: CGFloat = 1.0
        
        // CRITICAL: Set the attributes FIRST to prevent UI flicker
        attributes.zoomFactor = initialLogicalZoom
        
        print("zoom: Setting initial zoom to \(initialLogicalZoom)x")
        
        do {
            // Use the same zoom setting logic as the zoom buttons
            try performZoomOnDevice(initialLogicalZoom, device: device)
            
            print("zoom: Successfully set initial zoom to \(initialLogicalZoom)x")
        } catch {
            print("zoom: Failed to set initial zoom: \(error)")
            // Even if physical zoom setting fails, keep the logical zoom at 1.0x
        }
    }
}
private extension CameraManager {
    func setupDevice(_ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(attributes.cameraExposure.mode, duration: attributes.cameraExposure.duration, iso: attributes.cameraExposure.iso)
        device.setExposureTargetBias(attributes.cameraExposure.targetBias)
        device.setFrameRate(attributes.frameRate)
        device.setZoomFactor(attributes.zoomFactor)
        device.setLightMode(attributes.lightMode)
        device.hdrMode = attributes.hdrMode
        device.unlockForConfiguration()
    }
}

// MARK: Cancel
extension CameraManager {
    func cancel() {
        captureSession = captureSession.stopRunningAndReturnNewInstance()
        motionManager.reset()
        videoOutput.reset()
        notificationCenterManager.reset()
    }
}


// MARK: - LIVE ACTIONS



// MARK: Capture Output
extension CameraManager {
    func captureOutput() {
        guard !isChanging else { return }

        switch attributes.outputType {
            case .photo: photoOutput.capture()
            case .video: videoOutput.toggleRecording()
        }
    }
}

// MARK: Set Captured Media
extension CameraManager {
    func setCapturedMedia(_ capturedMedia: MCameraMedia?) { withAnimation(.mSpring) {
        attributes.capturedMedia = capturedMedia
    }}
}

// MARK: Set Camera Output
extension CameraManager {
    func setOutputType(_ outputType: CameraOutputType) {
        guard outputType != attributes.outputType, !isChanging else { return }
        attributes.outputType = outputType
    }
}

// MARK: Set Camera Position
extension CameraManager {
    func setCameraPosition(_ position: CameraPosition) async throws {
        guard position != attributes.cameraPosition, !isChanging else { return }

        await cameraMetalView.beginCameraFlipAnimation()
        try changeCameraInput(position)
        resetAttributesWhenChangingCamera(position)
        await cameraMetalView.finishCameraFlipAnimation()
    }
}
private extension CameraManager {
    func changeCameraInput(_ position: CameraPosition) throws {
        if let input = getCameraInput() { captureSession.remove(input: input) }
        try captureSession.add(input: getCameraInput(position))
    }
    func resetAttributesWhenChangingCamera(_ position: CameraPosition) {
        resetAttributes(device: getCameraInput(position)?.device, preserveZoom: true)
        attributes.cameraPosition = position
    }
}

// MARK: Set Camera Zoom
extension CameraManager {
  /*
    func setCameraZoomFactor(_ zoomFactor: CGFloat) throws {
        guard let device = getCameraInput()?.device, zoomFactor != attributes.zoomFactor, !isChanging else { return }

        try setDeviceZoomFactor(zoomFactor, device)
        attributes.zoomFactor = device.videoZoomFactor
    }
   */
  
  // Simplified approach - work with whatever camera system is actually available
  func setCameraZoomFactor(_ zoomFactor: CGFloat) throws {
      guard let sessionDevice = getCameraInput()?.device, zoomFactor != attributes.zoomFactor, !isChanging else { return }

      print("zoom: Attempting to set zoom to \(zoomFactor)")
      print("zoom: Current session device zoom: \(sessionDevice.videoZoomFactor)")
      
      // CRITICAL FIX: Use the same device discovery approach as the UI
      let currentPosition = attributes.cameraPosition
      let avCapturePosition: AVCaptureDevice.Position = currentPosition == .back ? .back : .front
      
      let deviceTypes: [AVCaptureDevice.DeviceType] = [
          .builtInTripleCamera,
          .builtInDualWideCamera,
          .builtInDualCamera,
          .builtInWideAngleCamera,
      ]
      
      let discoverySession = AVCaptureDevice.DiscoverySession(
          deviceTypes: deviceTypes,
          mediaType: .video,
          position: avCapturePosition
      )
      
      guard let actualDevice = discoverySession.devices.first else {
          print("zoom: No device found in discovery, using session device")
          let clampedZoom = max(min(zoomFactor, sessionDevice.maxAvailableVideoZoomFactor), sessionDevice.minAvailableVideoZoomFactor)
          try setDeviceZoomFactor(clampedZoom, sessionDevice)
          attributes.zoomFactor = zoomFactor
          return
      }
      
      print("zoom: Found actual device: \(actualDevice.deviceType.rawValue)")
      print("zoom: Session device: \((sessionDevice as? AVCaptureDevice)?.deviceType.rawValue ?? "unknown")")
      
      // Check if session device matches the discovered device
      if let sessionAVDevice = sessionDevice as? AVCaptureDevice,
         sessionAVDevice.uniqueID != actualDevice.uniqueID {
          print("zoom: DEVICE MISMATCH! Session is using wrong device.")
          print("zoom: Session: \(sessionAVDevice.deviceType.rawValue) (\(sessionAVDevice.uniqueID))")
          print("zoom: Should be: \(actualDevice.deviceType.rawValue) (\(actualDevice.uniqueID))")
          
          // Try to switch the session to use the correct device
          try switchToCorrectDevice(actualDevice)
          
          // Get the new session device after switching
          guard let newSessionDevice = getCameraInput()?.device else {
              throw MCameraError.cannotSetupInput
          }
          
          print("zoom: Successfully switched to correct device")
          try performZoomOnDevice(zoomFactor, device: newSessionDevice)
      } else {
          // Session device is correct, proceed with zoom
          print("zoom: Session device is correct, setting zoom")
          try performZoomOnDevice(zoomFactor, device: sessionDevice)
      }
      
      attributes.zoomFactor = zoomFactor
      print("zoom: Final device zoom factor: \(sessionDevice.videoZoomFactor)")
  }
  
  private func switchToCorrectDevice(_ targetDevice: AVCaptureDevice) throws {
      let currentPosition = attributes.cameraPosition
      
      // Remove current input
      if let currentInput = getCameraInput() {
          captureSession.remove(input: currentInput)
      }
      
      // Create input with target device
      let newInput = try AVCaptureDeviceInput(device: targetDevice)
      try captureSession.add(input: newInput)
      
      // Update stored input reference
      switch currentPosition {
      case .back:
          backCameraInput = newInput
      case .front:
          frontCameraInput = newInput
      }
  }
  
  private func performZoomOnDevice(_ zoomFactor: CGFloat, device: any CaptureDevice) throws {
      guard let avDevice = device as? AVCaptureDevice else {
          let clampedZoom = max(min(zoomFactor, device.maxAvailableVideoZoomFactor), device.minAvailableVideoZoomFactor)
          try setDeviceZoomFactor(clampedZoom, device)
          return
      }
      
      print("zoom: Setting zoom on: \(avDevice.deviceType.rawValue)")
      print("zoom: Device limits - Min: \(avDevice.minAvailableVideoZoomFactor), Max: \(avDevice.maxAvailableVideoZoomFactor)")
      
      // Check if this device supports virtual camera switching (multi-camera system)
      let supportsVirtualSwitching = !avDevice.virtualDeviceSwitchOverVideoZoomFactors.isEmpty
      print("zoom: Supports virtual switching: \(supportsVirtualSwitching)")
      
      if supportsVirtualSwitching {
          print("zoom: Virtual switchover factors: \(avDevice.virtualDeviceSwitchOverVideoZoomFactors)")
          
          // CRITICAL FIX: Convert logical zoom to physical zoom for virtual devices
          let physicalZoom = convertLogicalToPhysicalZoom(zoomFactor, device: avDevice)
          print("zoom: Converting logical \(zoomFactor) to physical \(physicalZoom)")
          
          // Validate that the physical zoom is within device limits
          let deviceMin = avDevice.minAvailableVideoZoomFactor
          let deviceMax = avDevice.maxAvailableVideoZoomFactor
          
          if physicalZoom < deviceMin || physicalZoom > deviceMax {
              print("zoom: ERROR - Physical zoom \(physicalZoom) is outside device range [\(deviceMin), \(deviceMax)]")
              throw MCameraError.cannotSetupInput
          }
          
          print("zoom: Setting physical zoom \(physicalZoom) on virtual camera system")
          
          try avDevice.lockForConfiguration()
          avDevice.videoZoomFactor = physicalZoom
          avDevice.unlockForConfiguration()
          
          print("zoom: Successfully set physical zoom to \(physicalZoom)")
          print("zoom: Actual device zoom factor: \(avDevice.videoZoomFactor)")
      } else {
          print("zoom: Single camera device - using clamped zoom")
          let clampedZoom = max(min(zoomFactor, avDevice.maxAvailableVideoZoomFactor), avDevice.minAvailableVideoZoomFactor)
          print("zoom: Clamped zoom: \(clampedZoom)")
          try setDeviceZoomFactor(clampedZoom, device)
      }
  }
  
  /// Converts logical zoom factor (UI) to physical zoom factor (device) for virtual devices
  private func convertLogicalToPhysicalZoom(_ logicalZoom: CGFloat, device: AVCaptureDevice) -> CGFloat {
      // For virtual devices, we need to map logical zoom to physical zoom
      // Based on your debug output: virtualDeviceSwitchOverVideoZoomFactors: [2]
      // This means:
      // - Physical 1.0 = Ultra-wide camera (logical 0.5x)
      // - Physical 2.0 = Wide camera (logical 1.0x)
      // - Physical 4.0+ = Telephoto zoom (logical 2.0x+)
      
      if device.virtualDeviceSwitchOverVideoZoomFactors.isEmpty {
          return logicalZoom
      }
      
      let zoomFactors = [1.0] + device.virtualDeviceSwitchOverVideoZoomFactors.map { CGFloat($0.floatValue) }
      
      // Find the main wide-angle camera index
      guard let mainIndex = device.constituentDevices.firstIndex(where: { $0.deviceType == .builtInWideAngleCamera }) else {
          return logicalZoom
      }
      
      let mainZoomFactor = zoomFactors[mainIndex]
      
      // Convert logical to physical: physical = logical * mainZoomFactor
      let physicalZoom = logicalZoom * mainZoomFactor
      
      print("zoom: Logical \(logicalZoom) × main factor \(mainZoomFactor) = physical \(physicalZoom)")
      return physicalZoom
  }
}
private extension CameraManager {
    func setDeviceZoomFactor(_ zoomFactor: CGFloat, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setZoomFactor(zoomFactor)
        device.unlockForConfiguration()
    }
}

// MARK: Set Camera Focus
extension CameraManager {
    func setCameraFocus(at touchPoint: CGPoint) throws {
        guard let device = getCameraInput()?.device, !isChanging else { return }

        let focusPoint = convertTouchPointToFocusPoint(touchPoint)
        try setDeviceCameraFocus(focusPoint, device)
        cameraMetalView.performCameraFocusAnimation(touchPoint: touchPoint)
    }
}
private extension CameraManager {
    func convertTouchPointToFocusPoint(_ touchPoint: CGPoint) -> CGPoint { .init(
        x: touchPoint.y / cameraView.frame.height,
        y: 1 - touchPoint.x / cameraView.frame.width
    )}
    func setDeviceCameraFocus(_ focusPoint: CGPoint, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setFocusPointOfInterest(focusPoint)
        device.setExposurePointOfInterest(focusPoint)
        device.unlockForConfiguration()
    }
}

// MARK: Set Flash Mode
extension CameraManager {
    func setFlashMode(_ flashMode: CameraFlashMode) {
        guard let device = getCameraInput()?.device, device.hasFlash, flashMode != attributes.flashMode, !isChanging else { return }
        attributes.flashMode = flashMode
    }
}

// MARK: Set Light Mode
extension CameraManager {
    func setLightMode(_ lightMode: CameraLightMode) throws {
        guard let device = getCameraInput()?.device, device.hasTorch, lightMode != attributes.lightMode, !isChanging else { return }

        try setDeviceLightMode(lightMode, device)
        attributes.lightMode = device.lightMode
    }
}
private extension CameraManager {
    func setDeviceLightMode(_ lightMode: CameraLightMode, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setLightMode(lightMode)
        device.unlockForConfiguration()
    }
}

// MARK: Set Mirror Output
extension CameraManager {
    func setMirrorOutput(_ mirrorOutput: Bool) {
        guard mirrorOutput != attributes.mirrorOutput, !isChanging else { return }
        attributes.mirrorOutput = mirrorOutput
    }
}

// MARK: Set Grid Visibility
extension CameraManager {
    func setGridVisibility(_ isGridVisible: Bool) {
        guard isGridVisible != attributes.isGridVisible, !isChanging else { return }
        cameraGridView.setVisibility(isGridVisible)
    }
}

// MARK: Set Camera Filters
extension CameraManager {
    func setCameraFilters(_ cameraFilters: [CIFilter]) {
        guard cameraFilters != attributes.cameraFilters, !isChanging else { return }
        attributes.cameraFilters = cameraFilters
    }
}

extension CameraManager {
  func setSelectedCameraFilter(_ filter: CameraFilter) {
    guard filter != attributes.selectedCameraFilter, !isChanging else { return }
    attributes.selectedCameraFilter = filter
    attributes.cameraFilters = filter.filters
  }
}

// MARK: Set Filter Intensity
extension CameraManager {
    func setFilterIntensity(_ intensity: Double) {
        let clampedIntensity = max(0.0, min(100.0, intensity))
        guard clampedIntensity != attributes.filterIntensity, !isChanging else { return }
        attributes.filterIntensity = clampedIntensity
    }
}

// MARK: Set Exposure Mode
extension CameraManager {
    func setExposureMode(_ exposureMode: AVCaptureDevice.ExposureMode) throws {
        guard let device = getCameraInput()?.device, exposureMode != attributes.cameraExposure.mode, !isChanging else { return }

        try setDeviceExposureMode(exposureMode, device)
        attributes.cameraExposure.mode = device.exposureMode
    }
}
private extension CameraManager {
    func setDeviceExposureMode(_ exposureMode: AVCaptureDevice.ExposureMode, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(exposureMode, duration: attributes.cameraExposure.duration, iso: attributes.cameraExposure.iso)
        device.unlockForConfiguration()
    }
}

// MARK: Set Exposure Duration
extension CameraManager {
    func setExposureDuration(_ exposureDuration: CMTime) throws {
        guard let device = getCameraInput()?.device, exposureDuration != attributes.cameraExposure.duration, !isChanging else { return }

        try setDeviceExposureDuration(exposureDuration, device)
        attributes.cameraExposure.duration = device.exposureDuration
    }
}
private extension CameraManager {
    func setDeviceExposureDuration(_ exposureDuration: CMTime, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(.custom, duration: exposureDuration, iso: attributes.cameraExposure.iso)
        device.unlockForConfiguration()
    }
}

// MARK: Set ISO
extension CameraManager {
    func setISO(_ iso: Float) throws {
        guard let device = getCameraInput()?.device, iso != attributes.cameraExposure.iso, !isChanging else { return }

        try setDeviceISO(iso, device)
        attributes.cameraExposure.iso = device.iso
    }
}
private extension CameraManager {
    func setDeviceISO(_ iso: Float, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureMode(.custom, duration: attributes.cameraExposure.duration, iso: iso)
        device.unlockForConfiguration()
    }
}

// MARK: Set Exposure Target Bias
extension CameraManager {
    func setExposureTargetBias(_ exposureTargetBias: Float) throws {
        guard let device = getCameraInput()?.device, exposureTargetBias != attributes.cameraExposure.targetBias, !isChanging else { return }

        try setDeviceExposureTargetBias(exposureTargetBias, device)
        attributes.cameraExposure.targetBias = device.exposureTargetBias
    }
}
private extension CameraManager {
    func setDeviceExposureTargetBias(_ exposureTargetBias: Float, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setExposureTargetBias(exposureTargetBias)
        device.unlockForConfiguration()
    }
}

// MARK: Set HDR Mode
extension CameraManager {
    func setHDRMode(_ hdrMode: CameraHDRMode) throws {
        guard let device = getCameraInput()?.device, hdrMode != attributes.hdrMode, !isChanging else { return }

        try setDeviceHDRMode(hdrMode, device)
        attributes.hdrMode = hdrMode
    }
}
private extension CameraManager {
    func setDeviceHDRMode(_ hdrMode: CameraHDRMode, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.hdrMode = hdrMode
        device.unlockForConfiguration()
    }
}

// MARK: Set Resolution
extension CameraManager {
    func setResolution(_ resolution: AVCaptureSession.Preset) {
        guard resolution != attributes.resolution, resolution != attributes.resolution, !isChanging else { return }

        captureSession.sessionPreset = resolution
        attributes.resolution = resolution
    }
}

// MARK: Set Frame Rate
extension CameraManager {
    func setFrameRate(_ frameRate: Int32) throws {
        guard let device = getCameraInput()?.device, frameRate != attributes.frameRate, !isChanging else { return }

        try setDeviceFrameRate(frameRate, device)
        attributes.frameRate = device.activeVideoMaxFrameDuration.timescale
    }
}
private extension CameraManager {
    func setDeviceFrameRate(_ frameRate: Int32, _ device: any CaptureDevice) throws {
        try device.lockForConfiguration()
        device.setFrameRate(frameRate)
        device.unlockForConfiguration()
    }
}


// MARK: - HELPERS



// MARK: Attributes
extension CameraManager {
    var hasFlash: Bool { getCameraInput()?.device.hasFlash ?? false }
    var hasLight: Bool { getCameraInput()?.device.hasTorch ?? false }
}
private extension CameraManager {
    var isChanging: Bool { cameraMetalView.isAnimating }
}

// MARK: Methods
extension CameraManager {
  /*
   // OLD
    func resetAttributes(device: (any CaptureDevice)?) {
        guard let device else { return }

        var newAttributes = attributes
        newAttributes.cameraExposure.mode = device.exposureMode
        newAttributes.cameraExposure.duration = device.exposureDuration
        newAttributes.cameraExposure.iso = device.iso
        newAttributes.cameraExposure.targetBias = device.exposureTargetBias
        newAttributes.frameRate = device.activeVideoMaxFrameDuration.timescale
        newAttributes.zoomFactor = device.videoZoomFactor
        newAttributes.lightMode = device.lightMode
        newAttributes.hdrMode = device.hdrMode

        attributes = newAttributes
    }
   */
  
  // NEW
  func resetAttributes(
    device: (any CaptureDevice)?,
    preserveZoom: Bool = false
  ) {
      guard let device else { return }
    
      let currentZoomFactor = attributes.zoomFactor

      var newAttributes = attributes
      newAttributes.cameraExposure.mode = device.exposureMode
      newAttributes.cameraExposure.duration = device.exposureDuration
      newAttributes.cameraExposure.iso = device.iso
      newAttributes.cameraExposure.targetBias = device.exposureTargetBias
      newAttributes.frameRate = device.activeVideoMaxFrameDuration.timescale
    
    if preserveZoom {
      newAttributes.zoomFactor = currentZoomFactor
    } else {
      // Use logical zoom factor instead of physical
      newAttributes.zoomFactor = DeviceCapabilities.getLogicalZoomFactor(from: device)
    }
      
      newAttributes.lightMode = device.lightMode
      newAttributes.hdrMode = device.hdrMode

      attributes = newAttributes
  }
  
  
    func getCameraInput(_ position: CameraPosition? = nil) -> (any CaptureDeviceInput)? { switch position ?? attributes.cameraPosition {
        case .front: frontCameraInput
        case .back: backCameraInput
    }}
    
    /// Gets audio input for video recording if audio is enabled
    func getAudioInput() -> (any CaptureDeviceInput)? {
        guard attributes.isAudioSourceAvailable else { return nil }
        let deviceInputType = type(of: frontCameraInput ?? backCameraInput!)
        return deviceInputType.get(mediaType: .audio, position: nil)
    }
    
    /// Starts the capture session asynchronously
    func startCaptureSession() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                // Access captureSession on main actor to avoid isolation warning
                let session = self.captureSession
                
                // Move to background queue for the actual session start
                DispatchQueue.global(qos: .userInitiated).async {
                    session.startRunning()
                    DispatchQueue.main.async {
                        continuation.resume()
                    }
                }
            }
        }
    }
}
