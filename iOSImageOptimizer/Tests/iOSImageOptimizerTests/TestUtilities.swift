import Foundation
import XCTest
import CoreGraphics
@testable import iOSImageOptimizer

class TestUtilities {
    
    // MARK: - Directory Management
    
    static func createTempDirectory(named name: String = "TestTemp") -> String {
        let tempDir = NSTemporaryDirectory()
        let testDir = (tempDir as NSString).appendingPathComponent("\(name)_\(UUID().uuidString)")
        
        do {
            try FileManager.default.createDirectory(atPath: testDir, withIntermediateDirectories: true)
            return testDir
        } catch {
            XCTFail("Failed to create temp directory: \(error)")
            return tempDir
        }
    }
    
    static func cleanupTempDirectory(_ path: String) {
        try? FileManager.default.removeItem(atPath: path)
    }
    
    static func getFixturesPath() -> String {
        let bundle = Bundle(for: TestUtilities.self)
        guard let path = bundle.path(forResource: "Fixtures", ofType: nil) else {
            XCTFail("Could not find Fixtures directory in test bundle")
            return ""
        }
        return path
    }
    
    // MARK: - Mock Project Creation
    
    enum ProjectStructure {
        case basic
        case complex
        case empty
        case corrupted
        case custom([String: Any])
    }
    
    static func createMockProject(structure: ProjectStructure, in directory: String? = nil) -> String {
        let projectDir = directory ?? createTempDirectory(named: "MockProject")
        
        switch structure {
        case .basic:
            return createBasicProject(in: projectDir)
        case .complex:
            return createComplexProject(in: projectDir)
        case .empty:
            return createEmptyProject(in: projectDir)
        case .corrupted:
            return createCorruptedProject(in: projectDir)
        case .custom(let config):
            return createCustomProject(in: projectDir, config: config)
        }
    }
    
    private static func createBasicProject(in directory: String) -> String {
        let fm = FileManager.default
        
        // Create directory structure
        let imageDir = (directory as NSString).appendingPathComponent("Images")
        let sourceDir = (directory as NSString).appendingPathComponent("Sources")
        let assetDir = (directory as NSString).appendingPathComponent("Assets.xcassets/AppIcon.appiconset")
        
        try? fm.createDirectory(atPath: imageDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: sourceDir, withIntermediateDirectories: true)
        try? fm.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        // Create mock files
        createMockFile(at: "\(imageDir)/logo.png", content: mockImageData())
        createMockFile(at: "\(imageDir)/logo@2x.png", content: mockImageData())
        createMockFile(at: "\(imageDir)/unused_image.png", content: mockImageData())
        
        createMockSwiftFile(at: "\(sourceDir)/ViewController.swift", imageReferences: ["logo", "background"])
        createMockAssetCatalog(at: "\(assetDir)/Contents.json", images: ["AppIcon"])
        
        return directory
    }
    
    private static func createComplexProject(in directory: String) -> String {
        let fm = FileManager.default
        
        // Create complex directory structure
        let dirs = [
            "Sources", "Resources", "Images", "Tests",
            "Assets.xcassets/AppIcon.appiconset",
            "Assets.xcassets/LaunchImage.launchimage",
            "Assets.xcassets/TestImageSet.imageset"
        ]
        
        for dir in dirs {
            let fullPath = (directory as NSString).appendingPathComponent(dir)
            try? fm.createDirectory(atPath: fullPath, withIntermediateDirectories: true)
        }
        
        // Create mock files with complex references
        createMockSwiftFile(
            at: "\(directory)/Sources/ComplexViewController.swift",
            imageReferences: ["header_image", "button_theme", "dynamic_index"]
        )
        
        createMockObjectiveCFile(
            at: "\(directory)/Sources/ObjectiveC.m",
            imageReferences: ["objc_header", "objc_button"]
        )
        
        createMockStringsFile(
            at: "\(directory)/Resources/Localizable.strings",
            imageReferences: ["welcome_banner", "error_icon"]
        )
        
        createMockInfoPlist(
            at: "\(directory)/Info.plist",
            imageReferences: ["AppIcon", "LaunchImage"]
        )
        
        return directory
    }
    
    private static func createEmptyProject(in directory: String) -> String {
        // Just create the directory, no content
        return directory
    }
    
    private static func createCorruptedProject(in directory: String) -> String {
        let fm = FileManager.default
        
        // Create some structure
        let assetDir = (directory as NSString).appendingPathComponent("Assets.xcassets/Corrupted.imageset")
        try? fm.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        // Create corrupted JSON
        createMockFile(at: "\(assetDir)/Contents.json", content: "{ invalid json content")
        
        // Create corrupted Swift file
        createMockFile(at: "\(directory)/Corrupted.swift", content: "class Incomplete {")
        
        return directory
    }
    
    private static func createCustomProject(in directory: String, config: [String: Any]) -> String {
        // Implementation for custom project creation based on config
        return directory
    }
    
    // MARK: - Mock File Creation
    
    static func createMockFile(at path: String, content: String) {
        try? content.write(toFile: path, atomically: true, encoding: .utf8)
    }
    
    static func createMockFile(at path: String, content: Data) {
        try? content.write(to: URL(fileURLWithPath: path))
    }
    
    static func createMockSwiftFile(at path: String, imageReferences: [String]) {
        var content = """
        import UIKit
        
        class MockViewController: UIViewController {
            override func viewDidLoad() {
                super.viewDidLoad()
        
        """
        
        for (index, ref) in imageReferences.enumerated() {
            if ref.contains("\\(") {
                // Handle string interpolation
                content += """
                        
                        for i in 1...5 {
                            let image\(index) = UIImage(named: "\(ref)")
                        }
                """
            } else {
                content += """
                        
                        let image\(index) = UIImage(named: "\(ref)")
                """
            }
        }
        
        content += """
            }
        }
        """
        
        createMockFile(at: path, content: content)
    }
    
    static func createMockObjectiveCFile(at path: String, imageReferences: [String]) {
        var content = """
        #import <UIKit/UIKit.h>
        
        @implementation MockObjectiveCClass
        
        - (void)setupImages {
        
        """
        
        for (index, ref) in imageReferences.enumerated() {
            content += "    UIImage *image\(index) = [UIImage imageNamed:@\"\(ref)\"];\n"
        }
        
        content += """
        }
        
        @end
        """
        
        createMockFile(at: path, content: content)
    }
    
    static func createMockStringsFile(at path: String, imageReferences: [String]) {
        var content = ""
        
        for (index, ref) in imageReferences.enumerated() {
            content += "\"image_key_\(index)\" = \"\(ref)\";\n"
        }
        
        createMockFile(at: path, content: content)
    }
    
    static func createMockInfoPlist(at path: String, imageReferences: [String]) {
        var content = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIdentifier</key>
            <string>com.test.mock</string>
        
        """
        
        for (index, ref) in imageReferences.enumerated() {
            content += """
                <key>CustomImageKey\(index)</key>
                <string>\(ref)</string>
        
        """
        }
        
        content += """
        </dict>
        </plist>
        """
        
        createMockFile(at: path, content: content)
    }
    
    static func createMockAssetCatalog(at path: String, images: [String]) {
        let contentsData: [String: Any] = [
            "images": images.enumerated().map { index, name in
                [
                    "filename": "\(name)@\(index + 1)x.png",
                    "idiom": "universal",
                    "scale": "\(index + 1)x"
                ]
            },
            "info": [
                "author": "xcode",
                "version": 1
            ]
        ]
        
        if let jsonData = try? JSONSerialization.data(withJSONObject: contentsData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            createMockFile(at: path, content: jsonString)
        }
    }
    
    // MARK: - Mock Image Data
    
    static func mockImageData(format: String = "PNG") -> Data {
        // Create minimal valid image data for testing
        switch format {
        case "PNG":
            return mockPNGData()
        case "JPEG":
            return mockJPEGData()
        default:
            return Data()
        }
    }
    
    private static func mockPNGData() -> Data {
        // Minimal PNG header for testing
        let pngSignature: [UInt8] = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]
        return Data(pngSignature)
    }
    
    private static func mockJPEGData() -> Data {
        // Minimal JPEG header for testing
        let jpegSignature: [UInt8] = [0xFF, 0xD8, 0xFF, 0xE0]
        return Data(jpegSignature)
    }
    
    // MARK: - Test Data Generators
    
    static func createMockImageAsset(
        name: String = "test.png",
        path: String = "/test/test.png",
        size: Int64 = 1024,
        type: ImageAsset.ImageType = .png,
        scale: Int? = 1,
        dimensions: CGSize? = CGSize(width: 100, height: 100),
        isInterlaced: Bool? = false,
        colorProfile: String? = nil
    ) -> ImageAsset {
        return ImageAsset(
            name: name,
            path: path,
            size: size,
            type: type,
            scale: scale,
            dimensions: dimensions,
            isInterlaced: isInterlaced,
            colorProfile: colorProfile
        )
    }
    
    static func createMockAppleComplianceResults(
        pngIssues: Int = 0,
        colorIssues: Int = 0,
        assetIssues: Int = 0,
        designIssues: Int = 0,
        score: Int = 100
    ) -> AppleComplianceResults {
        return AppleComplianceResults(
            pngInterlacingIssues: Array(repeating: createMockPNGIssue(), count: pngIssues),
            colorProfileIssues: Array(repeating: createMockColorProfileIssue(), count: colorIssues),
            assetCatalogIssues: Array(repeating: createMockAssetCatalogIssue(), count: assetIssues),
            designQualityIssues: Array(repeating: createMockDesignQualityIssue(), count: designIssues),
            complianceScore: score,
            criticalIssues: pngIssues + colorIssues,
            warningIssues: assetIssues + designIssues,
            totalIssues: pngIssues + colorIssues + assetIssues + designIssues
        )
    }
    
    static func createMockPNGIssue() -> PNGInterlacingIssue {
        return PNGInterlacingIssue(
            image: createMockImageAsset(),
            performanceImpact: "Medium",
            recommendation: "Convert to de-interlaced PNG"
        )
    }
    
    static func createMockColorProfileIssue() -> ColorProfileIssue {
        return ColorProfileIssue(
            image: createMockImageAsset(),
            issueType: .missing,
            recommendation: "Add sRGB color profile"
        )
    }
    
    static func createMockAssetCatalogIssue() -> AssetCatalogIssue {
        return AssetCatalogIssue(
            image: createMockImageAsset(),
            issueType: .shouldBeInCatalog,
            recommendation: "Move to Asset Catalog"
        )
    }
    
    static func createMockDesignQualityIssue() -> DesignQualityIssue {
        return DesignQualityIssue(
            image: createMockImageAsset(),
            issueType: .tooSmallForHighRes,
            impact: "May appear pixelated",
            recommendation: "Increase size to at least 44×44 points"
        )
    }
}

// MARK: - Test Extensions

extension XCTestCase {
    
    func withTempDirectory<T>(_ block: (String) throws -> T) rethrows -> T {
        let tempDir = TestUtilities.createTempDirectory()
        defer { TestUtilities.cleanupTempDirectory(tempDir) }
        return try block(tempDir)
    }
    
    func withMockProject<T>(structure: TestUtilities.ProjectStructure, _ block: (String) throws -> T) rethrows -> T {
        return try withTempDirectory { tempDir in
            let projectPath = TestUtilities.createMockProject(structure: structure, in: tempDir)
            return try block(projectPath)
        }
    }
}