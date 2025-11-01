//
//  DefaultCameraScreen+CameraFilterSwitch.swift
//  MijickCamera
//
//  Created by Manuel Winter on 01.11.25.
//

import SwiftUI

extension DefaultCameraScreen { struct CameraFilterSwitch: View {
    let parent: DefaultCameraScreen


    var body: some View {
        HStack(spacing: 4) {
          ForEach(CameraFilter.allCases, id: \.self) { filter in
            createFilterTypeButton(filter: filter)
          }
            
        }
        .padding(8)
        .background(Color(.mijickBackgroundPrimary50))
        .mask(Capsule())
    }
}}
private extension DefaultCameraScreen.CameraFilterSwitch {
  func createFilterTypeButton(filter: CameraFilter) -> some View {
    Button(icon: filter.icon, active: isFilterTypeButtonActive(filters: filter.filters)) {
          parent.setCameraFilters(filter.filters)
        }
        .rotationEffect(parent.iconAngle)
    }
}

private extension DefaultCameraScreen.CameraFilterSwitch {
//    func getFilterTypeButtonIcon(_ filter: CameraFilter) -> ImageResource { switch outputType {
//        case .photo: return .mijickIconPhoto
//        case .video: return .mijickIconVideo
//    }}
    func isFilterTypeButtonActive(filters: [CIFilter]) -> Bool {
      filters == parent.cameraFilters
    }
}


// MARK: Button
fileprivate struct Button: View {
    let icon: String//ImageResource
    let active: Bool
    let action: () -> ()


    var body: some View {
        SwiftUI.Button(action: action, label: createButtonLabel).buttonStyle(ButtonScaleStyle())
    }
}
private extension Button {
    func createButtonLabel() -> some View {
      Text("\(icon)")
      //Image(icon)
            //.resizable()
            .frame(width: iconSize, height: iconSize)
            .foregroundColor(iconColor)
            .padding(8)
            .background(Color(.mijickBackgroundSecondary))
            .mask(Circle())
    }
}
private extension Button {
    var iconSize: CGFloat { switch active {
        case true: 28
        case false: 20
    }}
    var iconColor: Color { switch active {
        case true: .init(.mijickBackgroundYellow)
        case false: .init(.mijickTextTertiary)
    }}
}
