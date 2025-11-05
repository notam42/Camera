//
//  DefaultCameraScreen+ZoomButtons.swift
//  MijickCamera
//
//  Created by Manuel Winter on 04.11.25.
//


import SwiftUI
import AVFoundation

extension DefaultCameraScreen {
    struct ZoomButtons: View {
        let parent: DefaultCameraScreen
        @State private var availableZoomFactors: [CGFloat] = []
        
        var body: some View {
            HStack(spacing: 8) {
                ForEach(availableZoomFactors, id: \.self) { zoomFactor in
                    createZoomButton(for: zoomFactor)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            .cornerRadius(20)
            .onAppear {
                updateAvailableZoomFactors()
            }
            .onChange(of: parent.cameraManager.attributes.cameraPosition) { _ in
                updateAvailableZoomFactors()
            }
        }
    }
}

private extension DefaultCameraScreen.ZoomButtons {
    func createZoomButton(for zoomFactor: CGFloat) -> some View {
        Button(action: {
            try? parent.setZoomFactor(zoomFactor)
        }) {
          if #available(iOS 15.0, *) {
            Text(formatZoomFactor(zoomFactor))
              .font(.body)
              .foregroundStyle(isSelectedZoom(zoomFactor) ? .yellow : .white)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                Capsule()
                  .fill(isSelectedZoom(zoomFactor) ? .secondary : Color.clear)
              )
          } else {
            // Fallback on earlier versions
            Text(formatZoomFactor(zoomFactor))
              .font(.body)
              .foregroundColor(isSelectedZoom(zoomFactor) ? .yellow : .white)
              .padding(.horizontal, 12)
              .padding(.vertical, 6)
              .background(
                Capsule()
                  .fill(isSelectedZoom(zoomFactor) ? .secondary : Color.clear)
              )
          }
        }
        .buttonStyle(ButtonScaleStyle())
    }
    
    func formatZoomFactor(_ factor: CGFloat) -> String {
        if factor < 1.0 {
            return String(format: "%.1fx", factor)
        } else {
            return String(format: "%.0fx", factor)
        }
    }
    
    func isSelectedZoom(_ factor: CGFloat) -> Bool {
        abs(parent.cameraManager.attributes.zoomFactor - factor) < 0.1
    }
    
    func updateAvailableZoomFactors() {
        guard let device = parent.cameraManager.getCameraInput()?.device else { return }
        
        var factors: [CGFloat] = []
        
        // Add ultra-wide (0.5x) if available
        if device.minAvailableVideoZoomFactor <= 0.5 {
            factors.append(0.5)
        }
        
        // Always add 1x
        factors.append(1.0)
        
        // Add 2x if available
        if device.maxAvailableVideoZoomFactor >= 2.0 {
            factors.append(2.0)
        }
        
      
        // For devices with more zoom capability, add additional levels
        if device.maxAvailableVideoZoomFactor >= 5.0 {
            factors.append(5.0)
        }
        
        availableZoomFactors = factors
    }
}
