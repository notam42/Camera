//
//  DefaultCameraScreen+BottomBar.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

extension DefaultCameraScreen { struct BottomBar: View {
    let parent: DefaultCameraScreen


    var body: some View {
        ZStack(alignment: .top) {
          if shouldShowFilterIntensitySlider {
            createFilterIntensitySlider()
              .offset(y: shouldShowFilterIntensitySlider ? -136 : -80) // Above filter selector
              .transition(.opacity.combined(with: .move(edge: .bottom)))
              .animation(.easeInOut(duration: 0.3), value: shouldShowFilterIntensitySlider)
          }


          createFilterTypeSwitch()

          createButtons()
        }
        .frame(maxWidth: .infinity)
        .padding(.bottom, 44)
        .padding(.horizontal, 32)
    }
}}

private extension DefaultCameraScreen.BottomBar {
  var shouldShowFilterIntensitySlider: Bool {
    isFilterTypeSwitchActive && !parent.cameraFilters.isEmpty
  }
  
  @ViewBuilder func createFilterIntensitySlider() -> some View {
      VStack(spacing: 4) {
          HStack {
              Text("0%")
                  .font(.caption2)
                  .foregroundColor(.secondary)
              
              Spacer()
              
              Text("\(Int(parent.filterIntensity))%")
                  .font(.caption)
                  .fontWeight(.medium)
                  .foregroundColor(.primary)
              
              Spacer()
              
              Text("100%")
                  .font(.caption2)
                  .foregroundColor(.secondary)
          }
          
          Slider(value: Binding(
              get: { parent.filterIntensity },
              set: { parent.setFilterIntensity($0) }
          ), in: 0...100, step: 1)
          .accentColor(.yellow)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .background(Color.black.opacity(0.3))
      .cornerRadius(12)
      .frame(maxWidth: .infinity)
    //.transition(.opacity.combined(with: .move(edge: .bottom)))
  }
  
  
  
    @ViewBuilder func createFilterTypeSwitch() -> some View { if isFilterTypeSwitchActive {
        DefaultCameraScreen.CameraFilterSwitch(parent: parent)
            .offset(y: -80)
    }}
    func createButtons() -> some View {
        ZStack {
            createLightButton()
            createCaptureButton()
            createChangeCameraPositionButton()
        }.frame(height: 72)
    }
}

//private extension DefaultCameraScreen.BottomBar {
//    @ViewBuilder func createOutputTypeSwitch() -> some View { if isOutputTypeSwitchActive {
//        DefaultCameraScreen.CameraOutputSwitch(parent: parent)
//            .offset(y: -80)
//    }}
//    func createButtons() -> some View {
//        ZStack {
//            createLightButton()
//            createCaptureButton()
//            createChangeCameraPositionButton()
//        }.frame(height: 72)
//    }
//}
private extension DefaultCameraScreen.BottomBar {
    @ViewBuilder func createLightButton() -> some View { if isLightButtonActive {
        BottomButton(
            icon: .mijickIconLight,
            iconColor: lightButtonIconColor,
            backgroundColor: .init(.mijickBackgroundSecondary),
            rotationAngle: parent.iconAngle,
            action: changeLightMode
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .transition(.scale)
    }}
    @ViewBuilder func createCaptureButton() -> some View { if isCaptureButtonActive {
        DefaultCameraScreen.CaptureButton(
            outputType: parent.cameraOutputType,
            isRecording: parent.isRecording,
            action: parent.captureOutput
        )
        .transition(.scale)
    }}
    @ViewBuilder func createChangeCameraPositionButton() -> some View { if isChangeCameraPositionButtonActive {
        BottomButton(
            icon: .mijickIconChangeCamera,
            iconColor: changeCameraPositionButtonIconColor,
            backgroundColor: .init(.mijickBackgroundSecondary),
            rotationAngle: parent.iconAngle,
            action: changeCameraPosition
        )
        .frame(maxWidth: .infinity, alignment: .trailing)
        .transition(.scale)
    }}
}

private extension DefaultCameraScreen.BottomBar {
    func changeLightMode() {
        do { try parent.setLightMode(parent.lightMode.next()) }
        catch {}
    }
    func changeCameraPosition() { Task {
        do { try await parent.setCameraPosition(parent.cameraPosition.next()) }
        catch {}
    }}
}

private extension DefaultCameraScreen.BottomBar {
    var lightButtonIconColor: Color { switch parent.lightMode {
        case .on: .init(.mijickBackgroundYellow)
        case .off: .init(.mijickBackgroundInverted)
    }}
    var changeCameraPositionButtonIconColor: Color { .init(.mijickBackgroundInverted) }
}
private extension DefaultCameraScreen.BottomBar {
    var isOutputTypeSwitchActive: Bool { parent.config.cameraOutputSwitchAllowed && parent.cameraManager.captureSession.isRunning && !parent.isRecording }
    var isFilterTypeSwitchActive: Bool { parent.config.cameraFilterSwitchAllowed && parent.cameraManager.captureSession.isRunning && !parent.isRecording }
    var isLightButtonActive: Bool { parent.config.lightButtonAllowed && parent.hasLight && parent.cameraManager.captureSession.isRunning && !parent.isRecording }
    var isCaptureButtonActive: Bool { parent.config.captureButtonAllowed && parent.cameraManager.captureSession.isRunning }
    var isChangeCameraPositionButtonActive: Bool { parent.config.cameraPositionButtonAllowed && parent.cameraManager.captureSession.isRunning && !parent.isRecording }
}
