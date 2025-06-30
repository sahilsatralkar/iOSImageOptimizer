import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

class MockImageGenerator {
    
    // MARK: - Image Creation
    
    static func createPNGWithMetadata(
        dimensions: CGSize,
        colorProfile: String? = nil,
        interlaced: Bool = false,
        scale: Int = 1
    ) -> Data {
        let width = Int(dimensions.width)
        let height = Int(dimensions.height)
        
        // Create a simple bitmap context
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return createMinimalPNGData()
        }
        
        // Fill with a test pattern
        context.setFillColor(CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        
        // Add some pattern based on scale
        context.setFillColor(CGColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 1.0))
        let patternSize = width / (scale * 4)
        for i in 0..<scale {
            let x = i * patternSize
            context.fill(CGRect(x: x, y: 0, width: patternSize, height: height))
        }
        
        guard let cgImage = context.makeImage() else {
            return createMinimalPNGData()
        }
        
        // Convert to PNG data with metadata
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        ) else {
            return createMinimalPNGData()
        }
        
        var properties: [CFString: Any] = [:]
        
        // Add PNG-specific properties
        var pngProperties: [CFString: Any] = [:]
        if interlaced {
            pngProperties[kCGImagePropertyPNGInterlaceType] = 1
        }
        properties[kCGImagePropertyPNGDictionary] = pngProperties
        
        // Add color profile if specified
        if let profile = colorProfile {
            switch profile.lowercased() {
            case "srgb":
                properties[kCGImagePropertyColorModel] = kCGImagePropertyColorModelRGB
            case "display p3":
                properties[kCGImagePropertyColorModel] = kCGImagePropertyColorModelRGB
            case "adobe rgb":
                properties[kCGImagePropertyColorModel] = kCGImagePropertyColorModelRGB
            default:
                break
            }
        }
        
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
    
    static func createJPEGWithEXIF(
        dimensions: CGSize,
        quality: Float = 0.8,
        colorProfile: String? = nil
    ) -> Data {
        let width = Int(dimensions.width)
        let height = Int(dimensions.height)
        
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else {
            return createMinimalJPEGData()
        }
        
        // Create a gradient pattern
        let colors = [
            CGColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0),
            CGColor(red: 0.0, green: 0.0, blue: 1.0, alpha: 1.0)
        ]
        
        guard let gradient = CGGradient(
            colorsSpace: CGColorSpaceCreateDeviceRGB(),
            colors: colors as CFArray,
            locations: [0.0, 1.0]
        ) else {
            return createMinimalJPEGData()
        }
        
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: 0, y: 0),
            end: CGPoint(x: width, y: height),
            options: []
        )
        
        guard let cgImage = context.makeImage() else {
            return createMinimalJPEGData()
        }
        
        let mutableData = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(
            mutableData,
            UTType.jpeg.identifier as CFString,
            1,
            nil
        ) else {
            return createMinimalJPEGData()
        }
        
        let properties: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: quality
        ]
        
        CGImageDestinationAddImage(destination, cgImage, properties as CFDictionary)
        CGImageDestinationFinalize(destination)
        
        return mutableData as Data
    }
    
    static func createCorruptedImage(format: String = "PNG") -> Data {
        switch format.uppercased() {
        case "PNG":
            // PNG with invalid header
            var data = createMinimalPNGData()
            data[1] = 0x00 // Corrupt the PNG signature
            return data
        case "JPEG":
            // JPEG with invalid header
            var data = createMinimalJPEGData()
            data[0] = 0x00 // Corrupt the JPEG marker
            return data
        default:
            return Data([0x00, 0x01, 0x02, 0x03]) // Random invalid data
        }
    }
    
    static func createLargeImage(megapixels: Double = 2.0) -> Data {
        let totalPixels = megapixels * 1_000_000
        let aspectRatio = 16.0 / 9.0
        let width = sqrt(totalPixels * aspectRatio)
        let height = width / aspectRatio
        
        return createPNGWithMetadata(
            dimensions: CGSize(width: width, height: height),
            colorProfile: "sRGB",
            interlaced: false
        )
    }
    
    static func createSmallImage(size: CGSize = CGSize(width: 16, height: 16)) -> Data {
        return createPNGWithMetadata(
            dimensions: size,
            colorProfile: "sRGB",
            interlaced: false
        )
    }
    
    // MARK: - Minimal Image Data
    
    private static func createMinimalPNGData() -> Data {
        // Minimal valid PNG file (1x1 pixel)
        let pngData: [UInt8] = [
            0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, // PNG signature
            0x00, 0x00, 0x00, 0x0D, // IHDR chunk length
            0x49, 0x48, 0x44, 0x52, // IHDR
            0x00, 0x00, 0x00, 0x01, // Width: 1
            0x00, 0x00, 0x00, 0x01, // Height: 1
            0x08, 0x02, 0x00, 0x00, 0x00, // Bit depth, color type, compression, filter, interlace
            0x90, 0x77, 0x53, 0xDE, // CRC
            0x00, 0x00, 0x00, 0x0C, // IDAT chunk length
            0x49, 0x44, 0x41, 0x54, // IDAT
            0x08, 0x99, 0x01, 0x01, 0x00, 0x00, 0x00, 0xFF, 0xFF, 0x00, 0x00, 0x00, 0x02, 0x00, 0x01, // Compressed data
            0x00, 0x00, 0x00, 0x00, // IEND chunk length
            0x49, 0x45, 0x4E, 0x44, // IEND
            0xAE, 0x42, 0x60, 0x82  // CRC
        ]
        return Data(pngData)
    }
    
    private static func createMinimalJPEGData() -> Data {
        // Minimal valid JPEG file
        let jpegData: [UInt8] = [
            0xFF, 0xD8, // SOI (Start of Image)
            0xFF, 0xE0, // APP0
            0x00, 0x10, // Length of APP0 segment
            0x4A, 0x46, 0x49, 0x46, 0x00, // "JFIF\0"
            0x01, 0x01, // Version 1.1
            0x01, // Units (0=no units, 1=dots/inch, 2=dots/cm)
            0x00, 0x48, // X density
            0x00, 0x48, // Y density
            0x00, 0x00, // Thumbnail width/height
            0xFF, 0xD9  // EOI (End of Image)
        ]
        return Data(jpegData)
    }
    
    // MARK: - Asset Catalog Images
    
    static func createAssetCatalogImageSet(
        name: String,
        scales: [Int] = [1, 2, 3],
        in directory: String
    ) {
        let imageSetDir = (directory as NSString).appendingPathComponent("\(name).imageset")
        try? FileManager.default.createDirectory(atPath: imageSetDir, withIntermediateDirectories: true)
        
        var images: [[String: Any]] = []
        
        for scale in scales {
            let filename = scale == 1 ? "\(name).png" : "\(name)@\(scale)x.png"
            let imagePath = (imageSetDir as NSString).appendingPathComponent(filename)
            
            // Create image file
            let imageData = createPNGWithMetadata(
                dimensions: CGSize(width: 60 * scale, height: 60 * scale),
                scale: scale
            )
            try? imageData.write(to: URL(fileURLWithPath: imagePath))
            
            // Add to Contents.json
            images.append([
                "filename": filename,
                "idiom": "universal",
                "scale": "\(scale)x"
            ])
        }
        
        let contentsData: [String: Any] = [
            "images": images,
            "info": [
                "author": "xcode",
                "version": 1
            ]
        ]
        
        let contentsPath = (imageSetDir as NSString).appendingPathComponent("Contents.json")
        if let jsonData = try? JSONSerialization.data(withJSONObject: contentsData, options: .prettyPrinted) {
            try? jsonData.write(to: URL(fileURLWithPath: contentsPath))
        }
    }
    
    static func createAppIconSet(in directory: String) {
        let iconSetDir = (directory as NSString).appendingPathComponent("AppIcon.appiconset")
        try? FileManager.default.createDirectory(atPath: iconSetDir, withIntermediateDirectories: true)
        
        let iconSizes = [
            ("20x20", 2, "iphone"),
            ("20x20", 3, "iphone"),
            ("29x29", 2, "iphone"),
            ("29x29", 3, "iphone"),
            ("40x40", 2, "iphone"),
            ("40x40", 3, "iphone"),
            ("60x60", 2, "iphone"),
            ("60x60", 3, "iphone")
        ]
        
        var images: [[String: Any]] = []
        
        for (size, scale, idiom) in iconSizes {
            let filename = "AppIcon\(size)@\(scale)x.png"
            let imagePath = (iconSetDir as NSString).appendingPathComponent(filename)
            
            let sizeComponents = size.components(separatedBy: "x")
            let width = Double(sizeComponents[0]) ?? 20
            let height = Double(sizeComponents[1]) ?? 20
            
            let imageData = createPNGWithMetadata(
                dimensions: CGSize(width: width * Double(scale), height: height * Double(scale)),
                scale: scale
            )
            try? imageData.write(to: URL(fileURLWithPath: imagePath))
            
            images.append([
                "filename": filename,
                "idiom": idiom,
                "scale": "\(scale)x",
                "size": size
            ])
        }
        
        let contentsData: [String: Any] = [
            "images": images,
            "info": [
                "author": "xcode",
                "version": 1
            ]
        ]
        
        let contentsPath = (iconSetDir as NSString).appendingPathComponent("Contents.json")
        if let jsonData = try? JSONSerialization.data(withJSONObject: contentsData, options: .prettyPrinted) {
            try? jsonData.write(to: URL(fileURLWithPath: contentsPath))
        }
    }
    
    // MARK: - File Utilities
    
    static func writeImageToFile(
        _ data: Data,
        at path: String,
        createDirectories: Bool = true
    ) {
        if createDirectories {
            let directory = (path as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        }
        
        try? data.write(to: URL(fileURLWithPath: path))
    }
    
    static func createImageWithProperties(
        name: String,
        format: String,
        dimensions: CGSize,
        colorProfile: String? = nil,
        isInterlaced: Bool = false,
        scale: Int = 1
    ) -> Data {
        switch format.uppercased() {
        case "PNG":
            return createPNGWithMetadata(
                dimensions: dimensions,
                colorProfile: colorProfile,
                interlaced: isInterlaced,
                scale: scale
            )
        case "JPEG", "JPG":
            return createJPEGWithEXIF(
                dimensions: dimensions,
                colorProfile: colorProfile
            )
        default:
            return createMinimalPNGData()
        }
    }
}