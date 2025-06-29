import Foundation
import Files
import CoreGraphics
import ImageIO

struct ImageAsset: Encodable {
    let name: String
    let path: String
    let size: Int64
    let type: ImageType
    let scale: Int?
    let dimensions: CGSize?
    let isInterlaced: Bool?
    let colorProfile: String?
    
    enum ImageType: Equatable, Encodable {
        case png, jpeg, pdf, svg
        case assetCatalog(scale: String)
    }
}

class ImageScanner {
    private let projectPath: String
    
    init(projectPath: String) {
        self.projectPath = projectPath
    }
    
    func scanForImages() throws -> [ImageAsset] {
        var images: [ImageAsset] = []
        
        let folder = try Folder(path: projectPath)
        
        // Scan for standalone images
        images.append(contentsOf: try scanStandaloneImages(in: folder))
        
        // Scan asset catalogs
        images.append(contentsOf: try scanAssetCatalogs(in: folder))
        
        return images
    }
    
    private func scanStandaloneImages(in folder: Folder) throws -> [ImageAsset] {
        var images: [ImageAsset] = []
        
        for file in folder.files.recursive {
            guard let imageType = imageType(for: file.extension ?? "") else { continue }
            
            // Skip images in .xcassets
            if file.path.contains(".xcassets") { continue }
            
            let metadata = getImageMetadata(at: file.path, type: imageType)
            let asset = ImageAsset(
                name: file.nameExcludingExtension,
                path: file.path,
                size: getFileSize(file),
                type: imageType,
                scale: extractScale(from: file.name),
                dimensions: metadata.dimensions,
                isInterlaced: metadata.isInterlaced,
                colorProfile: metadata.colorProfile
            )
            images.append(asset)
        }
        
        return images
    }
    
    private func scanAssetCatalogs(in folder: Folder) throws -> [ImageAsset] {
        var images: [ImageAsset] = []
        
        for subfolder in folder.subfolders.recursive {
            if subfolder.name.hasSuffix(".xcassets") {
                images.append(contentsOf: try scanAssetCatalog(subfolder))
            }
        }
        
        return images
    }
    
    private func scanAssetCatalog(_ catalog: Folder) throws -> [ImageAsset] {
        var images: [ImageAsset] = []
        
        for imageSet in catalog.subfolders.recursive {
            if imageSet.name.hasSuffix(".imageset") {
                let assetName = imageSet.name.replacingOccurrences(of: ".imageset", with: "")
                
                for file in imageSet.files {
                    if let imageType = imageType(for: file.extension ?? "") {
                        let scale = extractScale(from: file.name) ?? 1
                        let metadata = getImageMetadata(at: file.path, type: imageType)
                        let asset = ImageAsset(
                            name: assetName,
                            path: file.path,
                            size: getFileSize(file),
                            type: .assetCatalog(scale: "\(scale)x"),
                            scale: scale,
                            dimensions: metadata.dimensions,
                            isInterlaced: metadata.isInterlaced,
                            colorProfile: metadata.colorProfile
                        )
                        images.append(asset)
                    }
                }
            }
        }
        
        return images
    }
    
    private func imageType(for fileExtension: String) -> ImageAsset.ImageType? {
        switch fileExtension.lowercased() {
        case "png": return .png
        case "jpg", "jpeg": return .jpeg
        case "pdf": return .pdf
        case "svg": return .svg
        default: return nil
        }
    }
    
    private func extractScale(from filename: String) -> Int? {
        if filename.contains("@3x") { return 3 }
        if filename.contains("@2x") { return 2 }
        return 1
    }
    
    private func getFileSize(_ file: File) -> Int64 {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: file.path)
            return attributes[.size] as? Int64 ?? 0
        } catch {
            return 0
        }
    }
    
    // MARK: - Image Metadata Reading
    
    private struct ImageMetadata {
        let dimensions: CGSize?
        let isInterlaced: Bool?
        let colorProfile: String?
    }
    
    private func getImageMetadata(at path: String, type: ImageAsset.ImageType) -> ImageMetadata {
        let dimensions = getImageDimensions(at: path)
        let isInterlaced = type == .png ? checkPNGInterlacing(at: path) : nil
        let colorProfile = readColorProfile(at: path)
        
        return ImageMetadata(
            dimensions: dimensions,
            isInterlaced: isInterlaced,
            colorProfile: colorProfile
        )
    }
    
    private func getImageDimensions(at path: String) -> CGSize? {
        guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }
        
        guard let width = imageProperties[kCGImagePropertyPixelWidth] as? NSNumber,
              let height = imageProperties[kCGImagePropertyPixelHeight] as? NSNumber else {
            return nil
        }
        
        return CGSize(width: width.doubleValue, height: height.doubleValue)
    }
    
    private func checkPNGInterlacing(at path: String) -> Bool? {
        guard let data = NSData(contentsOfFile: path),
              data.length >= 33 else {
            return nil
        }
        
        // PNG interlace method is at byte 28 in the IHDR chunk
        // PNG signature (8 bytes) + IHDR length (4) + "IHDR" (4) + width (4) + height (4) + bit depth (1) + color type (1) + compression (1) + filter (1) + interlace (1)
        var interlaceMethod: UInt8 = 0
        data.getBytes(&interlaceMethod, range: NSRange(location: 28, length: 1))
        
        return interlaceMethod == 1 // 1 = interlaced, 0 = non-interlaced
    }
    
    private func readColorProfile(at path: String) -> String? {
        guard let imageSource = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil),
              let imageProperties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as? [CFString: Any] else {
            return nil
        }
        
        // Check for color profile information
        if let colorModel = imageProperties[kCGImagePropertyColorModel] as? String {
            return colorModel
        }
        
        // Check for ICC profile (use a string key since the constant might not be available)
        if let profileDescription = imageProperties["ProfileDescription" as CFString] as? String {
            return profileDescription
        }
        
        // Check for embedded color space
        if imageProperties[kCGImagePropertyHasAlpha] != nil {
            return "RGB" // Basic fallback
        }
        
        return nil
    }
}