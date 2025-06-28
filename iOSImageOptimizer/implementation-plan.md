# iOSImageOptimizer MVP - Weekend Project Plan

## MVP Scope (Completable in 1 Weekend)

### Core Features
1. **Scan** - Find all images in an iOS project
2. **Analyze** - Detect unused images and oversized images
3. **Report** - Generate a simple report with findings

### What We're Building
A CLI tool that answers two critical questions:
- Which images in my project are never used?
- Which images are larger than they need to be?

## Project Setup (30 minutes)

### 1. Create Project Structure
```bash
mkdir iOSImageOptimizer
cd iOSImageOptimizer
swift package init --type executable
```

### 2. Update Package.swift
```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "iOSImageOptimizer",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/JohnSundell/Files", from: "4.0.0"),
        .package(url: "https://github.com/onevcat/Rainbow", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "iOSImageOptimizer",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "Files",
                "Rainbow"
            ]
        )
    ]
)
```

## Implementation Plan

### Step 1: CLI Structure (30 minutes)

```swift
// Sources/iOSImageOptimizer/main.swift
import ArgumentParser
import Foundation
import Files
import Rainbow

@main
struct IOSImageOptimizer: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ios-image-optimizer",
        abstract: "Find unused and oversized images in iOS projects"
    )
    
    @Argument(help: "Path to iOS project directory")
    var projectPath: String
    
    @Flag(name: .shortAndLong, help: "Show detailed output")
    var verbose = false
    
    @Flag(name: .shortAndLong, help: "Export findings to JSON")
    var json = false
    
    mutating func run() throws {
        print("🔍 Analyzing iOS project at: \(projectPath)".cyan)
        
        let analyzer = ProjectAnalyzer(projectPath: projectPath, verbose: verbose)
        let report = try analyzer.analyze()
        
        if json {
            try report.exportJSON()
        } else {
            report.printToConsole()
        }
    }
}
```

### Step 2: Image Scanner (1 hour)

```swift
// Sources/iOSImageOptimizer/ImageScanner.swift
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
                size: Int64(file.size ?? 0),
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
                            size: Int64(file.size ?? 0),
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
    
    private func imageType(for extension: String) -> ImageAsset.ImageType? {
        switch extension.lowercased() {
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
}
```

### Step 3: Usage Detector (1.5 hours)

```swift
// Sources/iOSImageOptimizer/UsageDetector.swift
import Foundation
import Files

class UsageDetector {
    private let projectPath: String
    private let verbose: Bool
    
    init(projectPath: String, verbose: Bool = false) {
        self.projectPath = projectPath
        self.verbose = verbose
    }
    
    func findUsedImageNames() throws -> Set<String> {
        var usedImages = Set<String>()
        
        let folder = try Folder(path: projectPath)
        
        // Scan Swift files
        for file in folder.files.recursive where file.extension == "swift" {
            let content = try file.readAsString()
            usedImages.formUnion(findImageReferences(in: content, fileType: .swift))
        }
        
        // Scan Objective-C files
        for file in folder.files.recursive where file.extension == "m" || file.extension == "mm" {
            let content = try file.readAsString()
            usedImages.formUnion(findImageReferences(in: content, fileType: .objectiveC))
        }
        
        // Scan Storyboards and XIBs
        for file in folder.files.recursive where file.extension == "storyboard" || file.extension == "xib" {
            let content = try file.readAsString()
            usedImages.formUnion(findImageReferences(in: content, fileType: .interfaceBuilder))
        }
        
        if verbose {
            print("Found \(usedImages.count) unique image references")
        }
        
        return usedImages
    }
    
    private enum FileType {
        case swift, objectiveC, interfaceBuilder
    }
    
    private func findImageReferences(in content: String, fileType: FileType) -> Set<String> {
        var references = Set<String>()
        
        let patterns: [String]
        
        switch fileType {
        case .swift:
            patterns = [
                #"UIImage\s*\(\s*named:\s*"([^"]+)""#,                    // UIImage(named: "...")
                #"Image\s*\(\s*"([^"]+)""#,                               // SwiftUI Image("...")
                #"UIImage\s*\(\s*systemName:\s*"([^"]+)""#,              // SF Symbols
                #"#imageLiteral\s*\(\s*resourceName:\s*"([^"]+)""#       // Image literals
            ]
            
        case .objectiveC:
            patterns = [
                #"\[UIImage\s+imageNamed:\s*@"([^"]+)""#,                // [UIImage imageNamed:@"..."]
                #"imageWithContentsOfFile:[^"]*@"([^"]+)""#              // imageWithContentsOfFile
            ]
            
        case .interfaceBuilder:
            patterns = [
                #"image="([^"]+)""#,                                      // image="..."
                #"imageName="([^"]+)""#,                                  // imageName="..."
                #"<image[^>]+name="([^"]+)""#                            // <image name="...">
            ]
        }
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [])
            let matches = regex?.matches(in: content, options: [], range: NSRange(content.startIndex..., in: content)) ?? []
            
            for match in matches {
                if let range = Range(match.range(at: 1), in: content) {
                    let imageName = String(content[range])
                    references.insert(imageName)
                }
            }
        }
        
        return references
    }
}
```

### Step 4: Project Analyzer (1 hour)

```swift
// Sources/iOSImageOptimizer/ProjectAnalyzer.swift
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
        
        print("\n✨ " + "Recommendations:".bold.green)
        if wastedSize > 0 {
            print("  → Run 'ios-image-optimizer clean' to remove unused images")
            print("  → Run 'ios-image-optimizer optimize' to resize oversized images")
        } else {
            print("  → Your project is well optimized! 🎉")
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
```

### Step 5: Helper Extensions (30 minutes)

```swift
// Sources/iOSImageOptimizer/Extensions.swift
import Foundation

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

extension ImageAsset: Encodable {
    enum CodingKeys: String, CodingKey {
        case name, path, size, type, scale
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encode(scale, forKey: .scale)
        
        let typeString: String
        switch type {
        case .png: typeString = "png"
        case .jpeg: typeString = "jpeg"
        case .pdf: typeString = "pdf"
        case .svg: typeString = "svg"
        case .assetCatalog(let scale): typeString = "assetCatalog-\(scale)"
        }
        try container.encode(typeString, forKey: .type)
    }
}
```

## Build and Test (30 minutes)

### Build the project
```bash
swift build -c release
```

### Test on a sample project
```bash
.build/release/ios-image-optimizer /path/to/your/ios/project
```

### Install globally (optional)
```bash
cp .build/release/ios-image-optimizer /usr/local/bin/
```

## Sample Output

```
🔍 Analyzing iOS project at: /Users/you/MyApp
📊 Analysis Complete
==================================================

📈 Summary:
  Total images: 342
  Unused images: 47
  Oversized images: 23
  Total image size: 45.3 MB
  Potential savings: 12.8 MB

🗑️  Unused Images:
  ❌ old_logo (234 KB)
  ❌ test_background (1.2 MB)
  ❌ unused_icon (45 KB)
  ... and 44 more

⚠️  Oversized Images:
  ⚡ splash_screen
     Image exceeds 3x size limit (2.1 MB > 400 KB)
     Potential saving: 1.7 MB
  ⚡ hero_background
     Image exceeds 2x size limit (890 KB > 200 KB)
     Potential saving: 690 KB
  ... and 21 more

✨ Recommendations:
  → Run 'ios-image-optimizer clean' to remove unused images
  → Run 'ios-image-optimizer optimize' to resize oversized images
```

## Next Steps (After MVP)

Once you have this working, you can add:
1. **Clean command** - Actually remove unused images (with backup)
2. **Optimize command** - Resize oversized images
3. **Watch mode** - Monitor changes in real-time
4. **Better detection** - Handle more edge cases
5. **SF Symbol suggestions** - Find replaceable icons

## Tips for the Weekend

1. **Start with the scanner** - Get it finding images first
2. **Test on your own projects** - Real data helps find edge cases
3. **Don't over-engineer** - Focus on working code over perfect code
4. **Add features incrementally** - Each step should produce value

This MVP gives you a working tool that provides immediate value. You'll be able to find unused and oversized images in any iOS project, which alone can save significant app size!