//
//  MCameraMedia.swift of MijickCamera
//
//  Created by Tomasz Kurylik. Sending ❤️ from Kraków!
//    - Mail: tomasz.kurylik@mijick.com
//    - GitHub: https://github.com/FulcrumOne
//    - Medium: https://medium.com/@mijick
//
//  Copyright ©2024 Mijick. All rights reserved.


import SwiftUI

public struct MCameraMedia: Sendable {
    let image: UIImage?
    let video: URL?
  
  // New properties for filter support
    let originalImage: UIImage?
    let appliedFilterNames: [String]
  let filterIntensity: Double

    init?(data: Any?) {
      if let image = data as? UIImage {
        self.image = image
        self.video = nil
        self.originalImage = nil
        self.appliedFilterNames = []
        self.filterIntensity = 100
      }
      else if let video = data as? URL {
        self.video = video
        self.image = nil
        self.originalImage = nil
        self.appliedFilterNames = []
        self.filterIntensity = 100.0
      }
        else { return nil }
    }
  
  // New initializer for images with filter support
  init?(originalImage: UIImage?, filteredImage: UIImage?, appliedFilterNames: [String] = [], filterIntensity: Double = 100.0) {
      self.originalImage = originalImage
      self.image = filteredImage
      self.video = nil
      self.appliedFilterNames = appliedFilterNames
    self.filterIntensity = filterIntensity
  }
  
  // New initializer for video (keeping existing behavior)
  init?(videoURL: URL) {
      self.video = videoURL
      self.image = nil
      self.originalImage = nil
      self.appliedFilterNames = []
    self.filterIntensity = 100.0
  }
}

// MARK: Equatable
extension MCameraMedia: Equatable {
  public static func == (lhs: MCameraMedia, rhs: MCameraMedia) -> Bool {
    lhs.image == rhs.image &&
    lhs.video == rhs.video &&
    lhs.originalImage == rhs.originalImage &&
    lhs.appliedFilterNames == rhs.appliedFilterNames &&
    lhs.filterIntensity == rhs.filterIntensity
  }
}
