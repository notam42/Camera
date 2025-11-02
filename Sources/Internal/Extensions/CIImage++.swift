//
//  CIImage++.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

// MARK: Applying Filters
extension CIImage {
    func applyingFilters(_ filters: [CIFilter]) -> CIImage {
        var ciImage = self
        filters.forEach {
            $0.setValue(ciImage, forKey: kCIInputImageKey)
            ciImage = $0.outputImage ?? ciImage
        }
        return ciImage
    }
  
  /// Applies filter with intensity
  func applyingFilters(_ filters: [CIFilter], intensity: Double) -> CIImage {
      guard !filters.isEmpty, intensity > 0 else { return self }
      
      let filteredImage = applyingFilters(filters)
      let normalizedIntensity = intensity / 100.0
      
      // Blend original and filtered image based on intensity
      if let blendFilter = CIFilter(name: "CISourceOverCompositing") {
          blendFilter.setValue(self, forKey: kCIInputBackgroundImageKey)
          blendFilter.setValue(filteredImage.applyingFilter("CIColorMatrix", parameters: [
              "inputAVector": CIVector(x: 0, y: 0, z: 0, w: CGFloat(normalizedIntensity))
          ]), forKey: kCIInputImageKey)
          return blendFilter.outputImage ?? self
      }
      
      // Fallback: simple linear interpolation using CIMix
      if let mixFilter = CIFilter(name: "CIColorMatrix") {
          let weight = CGFloat(normalizedIntensity)
          mixFilter.setValue(filteredImage, forKey: kCIInputImageKey)
          mixFilter.setValue(CIVector(x: weight, y: weight, z: weight, w: 1.0), forKey: "inputRVector")
          mixFilter.setValue(CIVector(x: weight, y: weight, z: weight, w: 1.0), forKey: "inputGVector")
          mixFilter.setValue(CIVector(x: weight, y: weight, z: weight, w: 1.0), forKey: "inputBVector")
          mixFilter.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
          
          if let output = mixFilter.outputImage {
              return output
          }
      }
      
      return intensity >= 100 ? filteredImage : self
  }
}
