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

    init?(data: Any?) {
      if let image = data as? UIImage {
        self.image = image
        self.video = nil
        self.originalImage = nil
        self.appliedFilterNames = []
      }
      else if let video = data as? URL {
        self.video = video
        self.image = nil
        self.originalImage = nil
        self.appliedFilterNames = []
      }
        else { return nil }
    }
  
  // New initializer for images with filter support
  init?(originalImage: UIImage?, filteredImage: UIImage?, appliedFilterNames: [String] = []) {
      self.originalImage = originalImage
      self.image = filteredImage
      self.video = nil
      self.appliedFilterNames = appliedFilterNames
  }
  
  // New initializer for video (keeping existing behavior)
  init?(videoURL: URL) {
      self.video = videoURL
      self.image = nil
      self.originalImage = nil
      self.appliedFilterNames = []
  }
}

// MARK: Equatable
extension MCameraMedia: Equatable {
  public static func == (lhs: MCameraMedia, rhs: MCameraMedia) -> Bool {
    lhs.image == rhs.image && lhs.video == rhs.video && lhs.originalImage == rhs.originalImage && lhs.appliedFilterNames == rhs.appliedFilterNames
  }
}
