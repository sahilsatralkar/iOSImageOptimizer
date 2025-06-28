import Foundation
import Rainbow

struct AnalysisReport {
    let totalImages: Int
    let unusedImages: [ImageAsset]
    let oversizedImages: [OversizedImage]
    let totalSize: Int64
    let wastedSize: Int64
    
    struct OversizedImage {
        let asset: ImageAsset
        let reason: String
        let potentialSaving: Int64
    }
    
    func printToConsole() {
        print("\n📊 " + "Analysis Complete".bold)
        print("=" * 50)
        
        print("\n📈 " + "Summary:".bold)
        print("  Total images: \(totalImages)")
        print("  Unused images: \(unusedImages.count)".red)
        print("  Oversized images: \(oversizedImages.count)".yellow)
        print("  Total image size: \(formatBytes(totalSize))")
        print("  Potential savings: \(formatBytes(wastedSize))".green)
        
        if !unusedImages.isEmpty {
            print("\n🗑️  " + "Unused Images:".bold.red)
            for image in unusedImages.prefix(10) {
                print("  ❌ \(image.name) (\(formatBytes(image.size)))")
                print("     Path: \(image.path)")
            }
            if unusedImages.count > 10 {
                print("  ... and \(unusedImages.count - 10) more")
            }
        }
        
        if !oversizedImages.isEmpty {
            print("\n⚠️  " + "Oversized Images:".bold.yellow)
            for oversized in oversizedImages.prefix(10) {
                print("  ⚡ \(oversized.asset.name)")
                print("     \(oversized.reason)")
                print("     Potential saving: \(formatBytes(oversized.potentialSaving))".dim)
            }
            if oversizedImages.count > 10 {
                print("  ... and \(oversizedImages.count - 10) more")
            }
        }
        
    }
    
    func exportJSON() throws {
        let jsonData = try JSONEncoder().encode(self)
        print(String(data: jsonData, encoding: .utf8) ?? "{}")
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

extension AnalysisReport: Encodable {}
extension AnalysisReport.OversizedImage: Encodable {}

class ProjectAnalyzer {
    private let projectPath: String
    private let verbose: Bool
    
    // Size thresholds
    private let maxImageSize: Int64 = 500 * 1024  // 500KB
    private let max1xSize: Int64 = 100 * 1024     // 100KB for 1x
    private let max2xSize: Int64 = 200 * 1024     // 200KB for 2x
    private let max3xSize: Int64 = 400 * 1024     // 400KB for 3x
    
    init(projectPath: String, verbose: Bool = false) {
        self.projectPath = projectPath
        self.verbose = verbose
    }
    
    func analyze() throws -> AnalysisReport {
        // Step 1: Find all images
        if verbose { print("Scanning for images...") }
        let scanner = ImageScanner(projectPath: projectPath)
        let allImages = try scanner.scanForImages()
        
        if verbose { print("Found \(allImages.count) images") }
        
        // Step 2: Find used images
        if verbose { print("Detecting image usage...") }
        let detector = UsageDetector(projectPath: projectPath, verbose: verbose)
        let usedImageNames = try detector.findUsedImageNames()
        
        // Step 3: Identify unused images
        let unusedImages = allImages.filter { image in
            !usedImageNames.contains(image.name)
        }
        
        // Step 4: Identify oversized images
        let oversizedImages = findOversizedImages(in: allImages)
        
        // Step 5: Calculate metrics
        let totalSize = allImages.reduce(0) { $0 + $1.size }
        let wastedSize = unusedImages.reduce(0) { $0 + $1.size } + 
                        oversizedImages.reduce(0) { $0 + $1.potentialSaving }
        
        return AnalysisReport(
            totalImages: allImages.count,
            unusedImages: unusedImages,
            oversizedImages: oversizedImages,
            totalSize: totalSize,
            wastedSize: wastedSize
        )
    }
    
    private func findOversizedImages(in images: [ImageAsset]) -> [AnalysisReport.OversizedImage] {
        var oversized: [AnalysisReport.OversizedImage] = []
        
        for image in images {
            // Check against scale-specific thresholds
            let threshold: Int64
            let scale = image.scale ?? 1
            
            switch scale {
            case 1: threshold = max1xSize
            case 2: threshold = max2xSize
            case 3: threshold = max3xSize
            default: threshold = maxImageSize
            }
            
            if image.size > threshold {
                let potentialSaving = image.size - threshold
                let reason = "Image exceeds \(scale)x size limit (\(formatBytes(image.size)) > \(formatBytes(threshold)))"
                
                oversized.append(AnalysisReport.OversizedImage(
                    asset: image,
                    reason: reason,
                    potentialSaving: potentialSaving
                ))
            }
        }
        
        return oversized
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}