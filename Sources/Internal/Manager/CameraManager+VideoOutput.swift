//
//  CameraManager+VideoOutput.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


@preconcurrency import AVKit
import SwiftUI
import MijickTimer

@MainActor class CameraManagerVideoOutput: NSObject {
    private(set) weak var parent: CameraManager!
    private(set) var output: AVCaptureMovieFileOutput = .init()
    private(set) var timer: MTimer = .init(.camera)
    private(set) var recordingTime: MTime = .zero
    private(set) var firstRecordedFrame: UIImage?
}

// MARK: Setup
extension CameraManagerVideoOutput {
    func setup(parent: CameraManager) throws(MCameraError) {
        self.parent = parent
        try parent.captureSession.add(output: output)
    }
}

// MARK: Reset
extension CameraManagerVideoOutput {
    func reset() {
        timer.reset()
    }
}


// MARK: - CAPTURE VIDEO



// MARK: Toggle
extension CameraManagerVideoOutput {
    func toggleRecording() { switch output.isRecording {
        case true: stopRecording()
        case false: startRecording()
    }}
}

// MARK: Start Recording
private extension CameraManagerVideoOutput {
    func startRecording() {
        guard let url = prepareUrlForVideoRecording() else { return }

        configureOutput()
        storeLastFrame()
        output.startRecording(to: url, recordingDelegate: self)
        startRecordingTimer()
        parent.objectWillChange.send()
    }
}
private extension CameraManagerVideoOutput {
    func prepareUrlForVideoRecording() -> URL? {
        FileManager.prepareURLForVideoOutput()
    }
    func configureOutput() {
        guard let connection = output.connection(with: .video), connection.isVideoMirroringSupported else { return }

        connection.isVideoMirrored = parent.attributes.mirrorOutput ? parent.attributes.cameraPosition != .front : parent.attributes.cameraPosition == .front
        connection.videoOrientation = parent.attributes.deviceOrientation
    }
    func storeLastFrame() {
        guard let texture = parent.cameraMetalView.currentDrawable?.texture,
              let ciImage = CIImage(mtlTexture: texture, options: nil),
              let cgImage = parent.cameraMetalView.ciContext.createCGImage(ciImage, from: ciImage.extent)
        else { return }

        firstRecordedFrame = UIImage(cgImage: cgImage, scale: 1.0, orientation: parent.attributes.deviceOrientation.toImageOrientation())
    }
    func startRecordingTimer() { try? timer
        .publish(every: 1) { [self] in
            recordingTime = $0
            parent.objectWillChange.send()
        }
        .start()
    }
}

// MARK: Stop Recording
private extension CameraManagerVideoOutput {
    func stopRecording() {
        presentLastFrame()
        output.stopRecording()
        timer.reset()
    }
}
private extension CameraManagerVideoOutput {
    func presentLastFrame() {
        let firstRecordedFrame = MCameraMedia(data: firstRecordedFrame)
        parent.setCapturedMedia(firstRecordedFrame)
    }
}

// MARK: Receive Data
extension CameraManagerVideoOutput: @preconcurrency AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: (any Error)?) { Task {
        let videoURL = outputFileURL
        let capturedVideo = MCameraMedia(data: videoURL)

        await Task.sleep(seconds: Animation.duration)
        parent.setCapturedMedia(capturedVideo)
    }}
}
// MARK: - HELPERS
fileprivate extension MTimerID {
    static let camera: MTimerID = .init(rawValue: "mijick-camera")
}
