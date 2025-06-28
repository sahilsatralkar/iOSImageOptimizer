import Foundation
import Files

struct ImageAsset {
    let name: String
    let path: String
    let size: Int64
    let type: ImageType
    let scale: Int?
    
    enum ImageType {
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
            
            let asset = ImageAsset(
                name: file.nameExcludingExtension,
                path: file.path,
                size: getFileSize(file),
                type: imageType,
                scale: extractScale(from: file.name)
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
                        let asset = ImageAsset(
                            name: assetName,
                            path: file.path,
                            size: getFileSize(file),
                            type: .assetCatalog(scale: "\(scale)x"),
                            scale: scale
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
}