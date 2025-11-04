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
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 4) {
          ForEach(CameraFilter.allCases) { filter in
            createFilterTypeButton(filter: filter)
          }
            
        }
        .padding(8)
        //.background(Color(.mijickBackgroundPrimary50))
        //.mask(Capsule())

      }
      //.scrollIndicators(.hidden)
      .frame(height: 42)
    }
}}
private extension DefaultCameraScreen.CameraFilterSwitch {
  func createFilterTypeButton(filter: CameraFilter) -> some View {
    Button(
      icon: filter.icon,
      active: isFilterTypeButtonActive(filter: filter)
    ) {
          parent.setSelectedCameraFilter(filter)
        }
        .rotationEffect(parent.iconAngle)
    }
}

private extension DefaultCameraScreen.CameraFilterSwitch {
  func isFilterTypeButtonActive(filter: CameraFilter) -> Bool {
        // Compare filter arrays by their names since CIFilter doesn't conform to Equatable
//        let filterNames = filters.map { $0.name }
//        let currentFilterNames = parent.cameraFilters.map { $0.name }
    return filter == parent.selectedCameraFilter
    }
}


// MARK: Button
fileprivate struct Button: View {
    let icon: String//ImageResource
    let active: Bool
    let action: () -> ()

    var body: some View {
      SwiftUI.Button(
        action: action,
        label: createButtonLabel
      )
      .buttonStyle(ButtonScaleStyle())
    }
}
private extension Button {
    func createButtonLabel() -> some View {
      Text("\(icon)")
        .font(active ? .title : .callout)
      //Image(icon)
            //.resizable()
            .frame(width: iconSize, height: iconSize)
            .padding(8)
            //.background(active ? Color.yellow.opacity(0.3) : Color.clear)
            .border(active ? .white : .clear, width: 4.0)
            //.background(Color(.mijickBackgroundSecondary))
            
            //.mask(Circle())
    }
}
private extension Button {
    var iconSize: CGFloat { switch active {
        case true: 36//28
        case false: 32//20
    }}
    var iconColor: Color { switch active {
        case true: .init(.mijickBackgroundYellow)
        case false: .init(.mijickTextTertiary)
    }}
}

#Preview {
  ZStack {
    Color.yellow
    Text("Hi")
      .font(.title)
    //Image(icon)
          //.resizable()
          .frame(width: 36, height: 36)
          .padding(8)
          .border(.white, width: 4.0)
          //.background(active ? Color.yellow.opacity(0.3) : Color.clear)
          //.background(Color(.mijickBackgroundSecondary))
          
          //.mask(Circle())
  }
  
}
