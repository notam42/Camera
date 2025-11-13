//
//  FilmStock.swift
//  MijickCamera
//
//  Created by Manuel Winter on 09.11.25.
//


import Foundation
import Metal
import MetalKit
import UIKit

// MARK: - Film Stock Presets

enum FilmStock: String, CaseIterable {
    case kodachrome64 = "Kodachrome 64"
    case portra400 = "Kodak Portra 400"
    case cinestill800T = "CineStill 800T"
    case fuji400H = "Fujifilm Pro 400H"
    case ektachrome = "Kodak Ektachrome"
    case tri_x = "Kodak Tri-X (B&W)"
    
    var description: String {
        switch self {
        case .kodachrome64: return "Warm, saturated colors with rich reds"
        case .portra400: return "Soft pastels, lifted blacks, perfect skin tones"
        case .cinestill800T: return "Teal shadows, warm highlights, halation glow"
        case .fuji400H: return "Green-shifted, low contrast, dreamy look"
        case .ektachrome: return "Cool tones, high contrast, vivid blues"
        case .tri_x: return "Classic B&W with silver grain character"
        }
    }
}

// MARK: - LUT Generator

class FilmLUTGenerator {
    static let lutSize = 64 // 64x64x64 cube
    
    // Generate LUT data for a specific film stock
    static func generateLUT(for filmStock: FilmStock) -> Data {
        var cubeData = [Float]()
        let dimension = Float(lutSize - 1)
        
        for blue in 0..<lutSize {
            for green in 0..<lutSize {
                for red in 0..<lutSize {
                    var r = Float(red) / dimension
                    var g = Float(green) / dimension
                    var b = Float(blue) / dimension
                    
                    // Apply film-specific color transformations
                    switch filmStock {
                    case .kodachrome64:
                        (r, g, b) = applyKodachrome(r: r, g: g, b: b)
                    case .portra400:
                        (r, g, b) = applyPortra(r: r, g: g, b: b)
                    case .cinestill800T:
                        (r, g, b) = applyCineStill(r: r, g: g, b: b)
                    case .fuji400H:
                        (r, g, b) = applyFuji400H(r: r, g: g, b: b)
                    case .ektachrome:
                        (r, g, b) = applyEktachrome(r: r, g: g, b: b)
                    case .tri_x:
                        (r, g, b) = applyTriX(r: r, g: g, b: b)
                    }
                    
                    // Clamp values
                    r = clamp(r, min: 0, max: 1)
                    g = clamp(g, min: 0, max: 1)
                    b = clamp(b, min: 0, max: 1)
                    
                    cubeData.append(contentsOf: [r, g, b, 1.0])
                }
            }
        }
        
        return Data(bytes: &cubeData, count: cubeData.count * MemoryLayout<Float>.size)
    }
    
    // MARK: - Kodachrome 64
    // Characteristics: Warm, saturated, rich reds and blues, deep shadows
    private static func applyKodachrome(r: Float, g: Float, b: Float) -> (Float, Float, Float) {
        var r = r, g = g, b = b
        
        // 1. Increase overall saturation (15%)
        let luminance = 0.299 * r + 0.587 * g + 0.114 * b
        r = mix(luminance, r, t: 1.15)
        g = mix(luminance, g, t: 1.15)
        b = mix(luminance, b, t: 1.15)
        
        // 2. Boost reds (especially in midtones)
        if r > 0.3 && r < 0.8 {
            r = r * 1.12
        }
        
        // 3. Enrich blues
        if b > 0.4 {
            b = b * 1.08
        }
        
        // 4. Warm color shift
        r = r * 1.05
        b = b * 0.98
        
        // 5. Deepen shadows (no lifted blacks - Kodachrome has deep blacks)
        let shadowThreshold: Float = 0.15
        if luminance < shadowThreshold {
            let shadowFactor = pow(luminance / shadowThreshold, 1.2)
            r *= shadowFactor
            g *= shadowFactor
            b *= shadowFactor
        }
        
        // 6. Soft highlight rolloff
        r = softClip(r, threshold: 0.85)
        g = softClip(g, threshold: 0.85)
        b = softClip(b, threshold: 0.85)
        
        return (r, g, b)
    }
    
    // MARK: - Portra 400
    // Characteristics: Soft pastels, lifted blacks, beautiful skin tones, low contrast
    private static func applyPortra(r: Float, g: Float, b: Float) -> (Float, Float, Float) {
        var r = r, g = g, b = b
        
        // 1. Lift blacks significantly (classic Portra look)
        let lift: Float = 0.08
        r = r * (1 - lift) + lift
        g = g * (1 - lift) + lift
        b = b * (1 - lift) + lift
        
        // 2. Reduce contrast
        let midpoint: Float = 0.5
        r = midpoint + (r - midpoint) * 0.85
        g = midpoint + (g - midpoint) * 0.85
        b = midpoint + (b - midpoint) * 0.85
        
        // 3. Slight desaturation for pastel look
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        r = mix(lum, r, t: 0.88)
        g = mix(lum, g, t: 0.88)
        b = mix(lum, b, t: 0.88)
        
        // 4. Warm skin tones (boost red-orange in midtones)
        let skinToneBoost = r > g && r > b && r > 0.3 && r < 0.7
        if skinToneBoost {
            r = r * 1.06
            g = g * 1.02
        }
        
        // 5. Soften highlights
        r = softClip(r, threshold: 0.80)
        g = softClip(g, threshold: 0.80)
        b = softClip(b, threshold: 0.80)
        
        // 6. Slight magenta shift in shadows
        if lum < 0.3 {
            r = r * 1.02
            b = b * 1.02
            g = g * 0.99
        }
        
        return (r, g, b)
    }
    
    // MARK: - CineStill 800T
    // Characteristics: Teal shadows, warm highlights, halation, cinematic
    private static func applyCineStill(r: Float, g: Float, b: Float) -> (Float, Float, Float) {
        var r = r, g = g, b = b
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        
        // 1. Teal/cyan shift in shadows
        if lum < 0.4 {
            let shadowAmount = (0.4 - lum) / 0.4
            b = b + shadowAmount * 0.12
            g = g + shadowAmount * 0.08
            r = r - shadowAmount * 0.02
        }
        
        // 2. Warm shift in highlights
        if lum > 0.6 {
            let highlightAmount = (lum - 0.6) / 0.4
            r = r + highlightAmount * 0.08
            g = g + highlightAmount * 0.03
            b = b - highlightAmount * 0.05
        }
        
        // 3. Lift blacks slightly (not as much as Portra)
        let lift: Float = 0.04
        r = r * (1 - lift) + lift
        g = g * (1 - lift) + lift
        b = b * (1 - lift) + lift
        
        // 4. Increase contrast in midtones
        let midpoint: Float = 0.5
        if lum > 0.3 && lum < 0.7 {
            r = midpoint + (r - midpoint) * 1.12
            g = midpoint + (g - midpoint) * 1.12
            b = midpoint + (b - midpoint) * 1.12
        }
        
        // 5. Halation effect (glow in highlights) - simulated by softening
        r = softClip(r, threshold: 0.75)
        g = softClip(g, threshold: 0.75)
        b = softClip(b, threshold: 0.75)
        
        return (r, g, b)
    }
    
    // MARK: - Fuji 400H
    // Characteristics: Green shift, low contrast, dreamy, soft
    private static func applyFuji400H(r: Float, g: Float, b: Float) -> (Float, Float, Float) {
        var r = r, g = g, b = b
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        
        // 1. Signature green shift
        g = g * 1.08
        r = r * 0.98
        b = b * 0.96
        
        // 2. Low contrast
        let midpoint: Float = 0.5
        r = midpoint + (r - midpoint) * 0.75
        g = midpoint + (g - midpoint) * 0.75
        b = midpoint + (b - midpoint) * 0.75
        
        // 3. Lift blacks
        let lift: Float = 0.10
        r = r * (1 - lift) + lift
        g = g * (1 - lift) + lift
        b = b * (1 - lift) + lift
        
        // 4. Desaturate overall
        r = mix(lum, r, t: 0.85)
        g = mix(lum, g, t: 0.85)
        b = mix(lum, b, t: 0.85)
        
        // 5. Soft, creamy highlights
        r = softClip(r, threshold: 0.70)
        g = softClip(g, threshold: 0.70)
        b = softClip(b, threshold: 0.70)
        
        return (r, g, b)
    }
    
    // MARK: - Ektachrome
    // Characteristics: Cool tones, high contrast, vivid blues, punchy
    private static func applyEktachrome(r: Float, g: Float, b: Float) -> (Float, Float, Float) {
        var r = r, g = g, b = b
        let lum = 0.299 * r + 0.587 * g + 0.114 * b
        
        // 1. Cool color shift
        b = b * 1.08
        r = r * 0.96
        
        // 2. Increase contrast
        let midpoint: Float = 0.5
        r = midpoint + (r - midpoint) * 1.25
        g = midpoint + (g - midpoint) * 1.25
        b = midpoint + (b - midpoint) * 1.25
        
        // 3. Boost saturation
        r = mix(lum, r, t: 1.20)
        g = mix(lum, g, t: 1.20)
        b = mix(lum, b, t: 1.20)
        
        // 4. Vivid blues
        if b > 0.5 && b > r && b > g {
            b = b * 1.15
        }
        
        // 5. Minimal black lift (Ektachrome has deep blacks)
        let lift: Float = 0.02
        r = r * (1 - lift) + lift
        g = g * (1 - lift) + lift
        b = b * (1 - lift) + lift
        
        // 6. Hard highlight clip (slide film characteristic)
        r = hardClip(r, threshold: 0.95)
        g = hardClip(g, threshold: 0.95)
        b = hardClip(b, threshold: 0.95)
        
        return (r, g, b)
    }
    
    // MARK: - Tri-X (Black & White)
    // Characteristics: Silver grain, high contrast, deep blacks, film noir
    private static func applyTriX(r: Float, g: Float, b: Float) -> (Float, Float, Float) {
        var lum = 0.299 * r + 0.587 * g + 0.114 * b
        
        // 1. High contrast characteristic
        let midpoint: Float = 0.5
        lum = midpoint + (lum - midpoint) * 1.35
        
        // 2. Crush blacks slightly
        if lum < 0.15 {
            lum = lum * 0.7
        }
        
        // 3. Slight S-curve for film look
        lum = appleSCurve(lum)
        
        // 4. Subtle warm tone (silver halide has slight warmth)
        let r = lum * 1.01
        let g = lum * 1.00
        let b = lum * 0.98
        
        return (r, g, b)
    }
    
    // MARK: - Helper Functions
    
    private static func clamp(_ value: Float, min: Float, max: Float) -> Float {
        return Swift.max(min, Swift.min(max, value))
    }
    
    private static func mix(_ a: Float, _ b: Float, t: Float) -> Float {
        return a * (1 - t) + b * t
    }
    
    // Soft highlight compression (film rolloff)
    private static func softClip(_ value: Float, threshold: Float) -> Float {
        if value > threshold {
            let excess = value - threshold
            let compressed = excess / (1 + excess * 2)
            return threshold + compressed * (1 - threshold)
        }
        return value
    }
    
    // Hard highlight clip (slide film)
    private static func hardClip(_ value: Float, threshold: Float) -> Float {
        if value > threshold {
            let excess = value - threshold
            return threshold + excess * 0.3
        }
        return value
    }
    
    // S-curve for contrast
    private static func appleSCurve(_ value: Float) -> Float {
        return value * value * (3.0 - 2.0 * value) // Smoothstep
    }
}

// MARK: - Metal Shader Code

let metalShaderSource = """
#include <metal_stdlib>
using namespace metal;

kernel void applyLUT(texture2d<float, access::read> inputTexture [[texture(0)]],
                     texture3d<float, access::sample> lutTexture [[texture(1)]],
                     texture2d<float, access::write> outputTexture [[texture(2)]],
                     constant float &intensity [[buffer(0)]],
                     uint2 gid [[thread_position_in_grid]]) {
    
    // Check bounds
    if (gid.x >= inputTexture.get_width() || gid.y >= inputTexture.get_height()) {
        return;
    }
    
    // Read input pixel
    float4 color = inputTexture.read(gid);
    
    // Sample the 3D LUT
    constexpr sampler lutSampler(coord::normalized,
                                  address::clamp_to_edge,
                                  filter::linear);
    
    // Use RGB values as 3D coordinates into the LUT
    float3 lutCoord = color.rgb;
    float3 gradedColor = lutTexture.sample(lutSampler, lutCoord).rgb;
    
    // Blend between original and graded based on intensity
    float3 finalColor = mix(color.rgb, gradedColor, intensity);
    
    // Write output
    outputTexture.write(float4(finalColor, color.a), gid);
}
"""

// MARK: - Metal LUT Processor

class MetalLUTProcessor {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    private var lutTextures: [FilmStock: MTLTexture] = [:]
    
    init?() {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        // Compile shader
        do {
            let library = try device.makeLibrary(source: metalShaderSource, options: nil)
            guard let function = library.makeFunction(name: "applyLUT") else {
                return nil
            }
            self.pipelineState = try device.makeComputePipelineState(function: function)
        } catch {
            print("Failed to create pipeline state: \(error)")
            return nil
        }
        
        // Pre-generate all LUTs
        generateAllLUTs()
    }
    
    private func generateAllLUTs() {
        for filmStock in FilmStock.allCases {
            let lutData = FilmLUTGenerator.generateLUT(for: filmStock)
            if let texture = createLUTTexture(from: lutData) {
                lutTextures[filmStock] = texture
            }
        }
    }
    
    private func createLUTTexture(from data: Data) -> MTLTexture? {
        let size = FilmLUTGenerator.lutSize
        let descriptor = MTLTextureDescriptor()
        descriptor.textureType = .type3D
        descriptor.pixelFormat = .rgba32Float
        descriptor.width = size
        descriptor.height = size
        descriptor.depth = size
        descriptor.usage = [.shaderRead]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        let region = MTLRegionMake3D(0, 0, 0, size, size, size)
        let bytesPerRow = size * 4 * MemoryLayout<Float>.size
        let bytesPerImage = bytesPerRow * size
        
        data.withUnsafeBytes { ptr in
            texture.replace(region: region,
                          mipmapLevel: 0,
                          slice: 0,
                          withBytes: ptr.baseAddress!,
                          bytesPerRow: bytesPerRow,
                          bytesPerImage: bytesPerImage)
        }
        
        return texture
    }
    
    func applyLUT(to image: UIImage,
                  filmStock: FilmStock,
                  intensity: Float = 1.0) -> UIImage? {
        
        guard let cgImage = image.cgImage,
              let lutTexture = lutTextures[filmStock] else {
            return nil
        }
        
        // Create textures
        let textureLoader = MTKTextureLoader(device: device)
        guard let inputTexture = try? textureLoader.newTexture(cgImage: cgImage, options: nil) else {
            return nil
        }
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .rgba8Unorm,
            width: inputTexture.width,
            height: inputTexture.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderWrite, .shaderRead]
        
        guard let outputTexture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        // Create command buffer
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let commandEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return nil
        }
        
        commandEncoder.setComputePipelineState(pipelineState)
        commandEncoder.setTexture(inputTexture, index: 0)
        commandEncoder.setTexture(lutTexture, index: 1)
        commandEncoder.setTexture(outputTexture, index: 2)
        
        var intensityValue = intensity
        commandEncoder.setBytes(&intensityValue, length: MemoryLayout<Float>.size, index: 0)
        
        // Calculate thread groups
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (inputTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (inputTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        commandEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        commandEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // Convert to UIImage
        return textureToUIImage(texture: outputTexture)
    }
    
    private func textureToUIImage(texture: MTLTexture) -> UIImage? {
        let width = texture.width
        let height = texture.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let byteCount = bytesPerRow * height
        
        var pixelData = [UInt8](repeating: 0, count: byteCount)
        
        let region = MTLRegionMake2D(0, 0, width, height)
        texture.getBytes(&pixelData, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        guard let providerRef = CGDataProvider(data: Data(pixelData) as CFData) else {
            return nil
        }
        
        guard let cgImage = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: bytesPerRow,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
            provider: providerRef,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        ) else {
            return nil
        }
        
        return UIImage(cgImage: cgImage)
    }
}

// MARK: - Usage Example

/*
 Usage:
 
 guard let processor = MetalLUTProcessor() else {
     print("Failed to initialize Metal")
     return
 }
 
 let originalImage = UIImage(named: "photo")!
 
 // Apply Kodachrome look at full intensity
 if let kodachromeImage = processor.applyLUT(to: originalImage, 
                                             filmStock: .kodachrome64, 
                                             intensity: 1.0) {
     imageView.image = kodachromeImage
 }
 
 // Apply Portra look at 70% intensity
 if let portraImage = processor.applyLUT(to: originalImage, 
                                         filmStock: .portra400, 
                                         intensity: 0.7) {
     imageView.image = portraImage
 }
 
 // List all available film stocks
 for stock in FilmStock.allCases {
     print("\(stock.rawValue): \(stock.description)")
 }
 */