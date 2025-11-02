//
//  CameraFilter.swift
//  MijickCamera
//
//  Created by Manuel Winter on 01.11.25.
//


//
//  CameraFilter.swift
//  SoundSlide
//
//  Created by Manuel Winter on 01.11.25.
//


import CoreImage
import UIKit

enum CameraFilter: String, CaseIterable, Identifiable {
    // No Filter
    case none = "Original"
    // Analog Photography Filters
    case vintageFilm = "Vintage Film"
    case polaroid = "Polaroid"
    case blackAndWhiteFilm = "B&W Film"
    case cinemaScope = "CinemaScope"
    
    // Fun Modern Filters
    case psychedelicSwirl = "Psychedelic"
    case vibrant = "Vibrant"
    case dreamy = "Dreamy"
    case sunset = "Sunset"
    case arctic = "Arctic"
    case neon = "Neon"
    case pastel = "Pastel"
    case goldenHour = "Golden Hour"
  
  /// Unique identifier for each filter
      
  var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .none: return "0"
        case .vintageFilm: return "📷"
        case .polaroid: return "🖼️"
        case .blackAndWhiteFilm: return "⬛"
        case .cinemaScope: return "🎬"
        case .psychedelicSwirl: return "🌀"
        case .vibrant: return "🌈"
        case .dreamy: return "✨"
        case .sunset: return "🌅"
        case .arctic: return "❄️"
        case .neon: return "💫"
        case .pastel: return "🎨"
        case .goldenHour: return "🌞"
        }
    }
    
    var filters: [CIFilter] {
        switch self {
        case .none:
          return []
        case .vintageFilm:
            return vintageFilmFilters()
        case .polaroid:
            return polaroidFilters()
        case .blackAndWhiteFilm:
            return blackAndWhiteFilmFilters()
        case .cinemaScope:
            return cinemaScopeFilters()
        case .psychedelicSwirl:
          return psychedelicSwirlFilters()
        case .vibrant:
            return vibrantFilters()
        case .dreamy:
            return dreamyFilters()
        case .sunset:
            return sunsetFilters()
        case .arctic:
            return arcticFilters()
        case .neon:
            return neonFilters()
        case .pastel:
            return pastelFilters()
        case .goldenHour:
            return goldenHourFilters()
        }
    }
    
    // MARK: - Analog Photography Filter Configurations
    
    private func vintageFilmFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Color adjustments
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(0.9, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.1, forKey: kCIInputBrightnessKey)
            colorControls.setValue(1.1, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        // Warm tone
        if let temp = CIFilter(name: "CITemperatureAndTint") {
            temp.setValue(CIVector(x: 6800, y: 0), forKey: "inputNeutral")
            temp.setValue(CIVector(x: 6500, y: 50), forKey: "inputTargetNeutral")
            filters.append(temp)
        }
        
        // Vignette
        if let vignette = CIFilter(name: "CIVignette") {
            vignette.setValue(1.5, forKey: kCIInputIntensityKey)
            vignette.setValue(0.8, forKey: kCIInputRadiusKey)
            filters.append(vignette)
        }
        
        return filters
    }
    
    private func polaroidFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // High contrast, slightly faded
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(0.85, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.15, forKey: kCIInputBrightnessKey)
            colorControls.setValue(1.3, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        // Cool cyan tint in shadows
        if let colorMatrix = CIFilter(name: "CIColorMatrix") {
            colorMatrix.setValue(CIVector(x: 1, y: 0, z: 0, w: 0), forKey: "inputRVector")
            colorMatrix.setValue(CIVector(x: 0, y: 1.05, z: 0, w: 0), forKey: "inputGVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0, z: 1.1, w: 0), forKey: "inputBVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0, z: 0, w: 1), forKey: "inputAVector")
            filters.append(colorMatrix)
        }
        
        return filters
    }
    
    private func blackAndWhiteFilmFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // B&W conversion
        if let noir = CIFilter(name: "CIPhotoEffectNoir") {
            filters.append(noir)
        }
        
        // Increase contrast
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(1.2, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        return filters
    }
    
    private func cinemaScopeFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Desaturated look
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(0.7, forKey: kCIInputSaturationKey)
            colorControls.setValue(1.2, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        // Teal shadows, orange highlights
        if let colorMatrix = CIFilter(name: "CIColorMatrix") {
            colorMatrix.setValue(CIVector(x: 1.1, y: 0, z: 0, w: 0), forKey: "inputRVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0.95, z: 0, w: 0), forKey: "inputGVector")
            colorMatrix.setValue(CIVector(x: 0, y: 0.05, z: 1, w: 0), forKey: "inputBVector")
            filters.append(colorMatrix)
        }
        
        // Strong vignette
        if let vignette = CIFilter(name: "CIVignette") {
            vignette.setValue(2.0, forKey: kCIInputIntensityKey)
            vignette.setValue(0.7, forKey: kCIInputRadiusKey)
            filters.append(vignette)
        }
        
        return filters
    }
    
    // MARK: - Fun Modern Filter Configurations
  
  private func psychedelicSwirlFilters() -> [CIFilter] {
          var filters: [CIFilter] = []
          
          // Extreme saturation boost
          if let colorControls = CIFilter(name: "CIColorControls") {
              colorControls.setValue(2.0, forKey: kCIInputSaturationKey)
              colorControls.setValue(1.4, forKey: kCIInputContrastKey)
              colorControls.setValue(0.1, forKey: kCIInputBrightnessKey)
              filters.append(colorControls)
          }
          
          // Twirl distortion for swirl effect
          if let twirl = CIFilter(name: "CITwirlDistortion") {
              twirl.setValue(CIVector(x: 0, y: 0), forKey: kCIInputCenterKey)
              twirl.setValue(300, forKey: kCIInputRadiusKey)
              twirl.setValue(3.14, forKey: "inputAngle")
              filters.append(twirl)
          }
          
          // Posterize for striped paint effect
          if let posterize = CIFilter(name: "CIColorPosterize") {
              posterize.setValue(8, forKey: "inputLevels")
              filters.append(posterize)
          }
          
          // Color curves adjustment for vibrant tones
          if let colorMatrix = CIFilter(name: "CIColorMatrix") {
              colorMatrix.setValue(CIVector(x: 1.3, y: 0, z: 0, w: 0), forKey: "inputRVector")
              colorMatrix.setValue(CIVector(x: 0, y: 1.3, z: 0, w: 0), forKey: "inputGVector")
              colorMatrix.setValue(CIVector(x: 0, y: 0, z: 1.3, w: 0), forKey: "inputBVector")
              filters.append(colorMatrix)
          }
          
          // Crystallize for texture
          if let crystallize = CIFilter(name: "CICrystallize") {
              crystallize.setValue(8, forKey: kCIInputRadiusKey)
              filters.append(crystallize)
          }
          
          // Edge work for line definition
          if let edges = CIFilter(name: "CILineOverlay") {
              edges.setValue(7.0, forKey: "inputNRNoiseLevel")
              edges.setValue(0.71, forKey: "inputNRSharpness")
              edges.setValue(0.5, forKey: "inputEdgeIntensity")
              edges.setValue(0.1, forKey: "inputThreshold")
              edges.setValue(1.0, forKey: "inputContrast")
              filters.append(edges)
          }
          
          return filters
      }
    
    private func vibrantFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Vibrance boost
        if let vibrance = CIFilter(name: "CIVibrance") {
            vibrance.setValue(1.2, forKey: "inputAmount")
            filters.append(vibrance)
        }
        
        // Enhanced saturation
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(1.3, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.05, forKey: kCIInputBrightnessKey)
            colorControls.setValue(1.1, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        return filters
    }
    
    private func dreamyFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Bloom effect
        if let bloom = CIFilter(name: "CIBloom") {
            bloom.setValue(0.7, forKey: kCIInputIntensityKey)
            bloom.setValue(15, forKey: kCIInputRadiusKey)
            filters.append(bloom)
        }
        
        // Slight brightness boost
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(0.1, forKey: kCIInputBrightnessKey)
            filters.append(colorControls)
        }
        
        return filters
    }
    
    private func sunsetFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Warm golden tone
        if let temp = CIFilter(name: "CITemperatureAndTint") {
            temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temp.setValue(CIVector(x: 4500, y: 150), forKey: "inputTargetNeutral")
            filters.append(temp)
        }
        
        // Boost saturation
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(1.2, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.1, forKey: kCIInputBrightnessKey)
            filters.append(colorControls)
        }
        
        // Soft vignette
        if let vignette = CIFilter(name: "CIVignette") {
            vignette.setValue(1.0, forKey: kCIInputIntensityKey)
            vignette.setValue(1.0, forKey: kCIInputRadiusKey)
            filters.append(vignette)
        }
        
        return filters
    }
    
    private func arcticFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Cool blue tone
        if let temp = CIFilter(name: "CITemperatureAndTint") {
            temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temp.setValue(CIVector(x: 8500, y: -100), forKey: "inputTargetNeutral")
            filters.append(temp)
        }
        
        // Increase contrast and saturation
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(1.15, forKey: kCIInputSaturationKey)
            colorControls.setValue(1.2, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        return filters
    }
    
    private func neonFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Extreme saturation and contrast
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(1.5, forKey: kCIInputSaturationKey)
            colorControls.setValue(1.3, forKey: kCIInputContrastKey)
            colorControls.setValue(0.05, forKey: kCIInputBrightnessKey)
            filters.append(colorControls)
        }
        
        // Edge glow
        if let edges = CIFilter(name: "CIEdges") {
            edges.setValue(1.5, forKey: kCIInputIntensityKey)
            filters.append(edges)
        }
        
        return filters
    }
    
    private func pastelFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Soft, desaturated look
        if let colorControls = CIFilter(name: "CIColorControls") {
            colorControls.setValue(0.7, forKey: kCIInputSaturationKey)
            colorControls.setValue(0.25, forKey: kCIInputBrightnessKey)
            colorControls.setValue(0.9, forKey: kCIInputContrastKey)
            filters.append(colorControls)
        }
        
        return filters
    }
    
    private func goldenHourFilters() -> [CIFilter] {
        var filters: [CIFilter] = []
        
        // Warm, glowing effect
        if let temp = CIFilter(name: "CITemperatureAndTint") {
            temp.setValue(CIVector(x: 6500, y: 0), forKey: "inputNeutral")
            temp.setValue(CIVector(x: 3800, y: 100), forKey: "inputTargetNeutral")
            filters.append(temp)
        }
        
        // Boost highlights
        if let highlight = CIFilter(name: "CIHighlightShadowAdjust") {
            highlight.setValue(1.2, forKey: "inputHighlightAmount")
            highlight.setValue(0.1, forKey: "inputShadowAmount")
            filters.append(highlight)
        }
        
        // Subtle bloom
        if let bloom = CIFilter(name: "CIBloom") {
            bloom.setValue(0.4, forKey: kCIInputIntensityKey)
            bloom.setValue(10, forKey: kCIInputRadiusKey)
            filters.append(bloom)
        }
        
        return filters
    }
}

// MARK: - Usage Example
/*
// Access filters array for any filter:
let filters = CameraFilter.vintageFilm.filters
model.filters = filters

// Get all available filters:
let allFilters = CameraFilter.allCases

// Use in a picker or collection view:
for filter in CameraFilter.allCases {
    print("\(filter.icon) \(filter.rawValue)")
    // Apply: model.filters = filter.filters
}
*/
