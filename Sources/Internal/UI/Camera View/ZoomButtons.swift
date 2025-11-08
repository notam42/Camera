//
//  ZoomButtons.swift of MijickCamera
//
//  Created by GitHub Copilot. Sending ❤️ from everywhere!
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

/// Individual zoom button that displays zoom factor and handles selection
struct ZoomButton: View {
    let factor: CGFloat
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(formatZoomFactor(factor))
                .font(.system(size: 14, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .black : Color(.mijickTextPrimary))
                .frame(width: 44, height: 32)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                      .fill(isSelected ? Color(.mijickBackgroundYellow) : Color(.mijickBackgroundPrimary50))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                          isSelected ? Color.clear : Color(.mijickBackgroundPrimary80).opacity(0.3),
                            lineWidth: 1
                        )
                )
        }
        .scaleEffect(isSelected ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
    
    /// Formats zoom factor for display (0.5×, 1×, 2×, etc.)
    private func formatZoomFactor(_ factor: CGFloat) -> String {
        if factor < 1 {
            return String(format: "%.1f×", factor)
        } else if factor.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(factor))×"
        } else {
            return String(format: "%.1f×", factor)
        }
    }
}

/// Horizontal row of zoom buttons that appear above the camera controls
struct ZoomButtonsView: View {
    let zoomFactors: [CGFloat]
    let currentZoomFactor: CGFloat
    let onZoomChange: (CGFloat) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            ForEach(zoomFactors, id: \.self) { factor in
                ZoomButton(
                    factor: factor,
                    isSelected: abs(currentZoomFactor - factor) < 0.1
                ) {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        onZoomChange(factor)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
//        .background(
//            Capsule()
//              .fill(Color.black.opacity(0.8))
//                //.backdrop(.ultraThinMaterial)
//        )
    }
}

/// Container view that manages zoom buttons visibility and positioning
struct CameraZoomControls: View {
    let zoomFactors: [CGFloat]
    let currentZoomFactor: CGFloat
    let onZoomChange: (CGFloat) -> Void
    
    @State private var showZoomButtons = true
    @State private var hideTimer: Timer?
    
    var body: some View {
        VStack {
            Spacer()
            
            if showZoomButtons && !zoomFactors.isEmpty {
                ZoomButtonsView(
                    zoomFactors: zoomFactors,
                    currentZoomFactor: currentZoomFactor,
                    onZoomChange: { factor in
                        onZoomChange(factor)
                        resetHideTimer()
                    }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 120) // Position above camera controls
            }
        }
        .onAppear {
            resetHideTimer()
        }
        .onTapGesture {
            // Show zoom buttons on tap and reset timer
            withAnimation(.easeInOut(duration: 0.2)) {
                showZoomButtons = true
            }
            resetHideTimer()
        }
    }
    
    /// Resets the timer that hides zoom buttons after inactivity
    private func resetHideTimer() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: false) { _ in
          Task { @MainActor in
                withAnimation(.easeInOut(duration: 0.2)) {
                    showZoomButtons = false
                }
            }
        }
    }
}

#if DEBUG
/// Preview for zoom buttons
struct ZoomButtons_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            CameraZoomControls(
                zoomFactors: [0.5, 1.0, 2.0, 5.0],
                currentZoomFactor: 1.0,
                onZoomChange: { _ in }
            )
        }
    }
}
#endif
