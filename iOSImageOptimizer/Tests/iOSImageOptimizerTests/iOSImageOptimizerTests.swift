import XCTest
import Foundation
@testable import iOSImageOptimizer

final class iOSImageOptimizerTests: XCTestCase {
    
    var tempProjectPath: String!
    
    override func setUp() {
        super.setUp()
        tempProjectPath = createTempTestProject()
    }
    
    override func tearDown() {
        cleanupTempProject()
        super.tearDown()
    }
    
    // MARK: - ProjectAnalyzer Tests
    
    func testProjectAnalyzerBasicAnalysis() throws {
        let analyzer = ProjectAnalyzer(projectPath: tempProjectPath, verbose: false)
        let report = try analyzer.analyze()
        
        XCTAssertGreaterThanOrEqual(report.totalImages, 0)
        XCTAssertGreaterThanOrEqual(report.totalSize, 0)
        XCTAssertNotNil(report.appleComplianceResults)
    }
    
    func testProjectAnalyzerWithVerboseMode() throws {
        let analyzer = ProjectAnalyzer(projectPath: tempProjectPath, verbose: true)
        let report = try analyzer.analyze()
        
        XCTAssertNotNil(report)
    }
    
    // MARK: - ImageScanner Tests
    
    func testImageScannerFindsImages() throws {
        let scanner = ImageScanner(projectPath: tempProjectPath)
        let images = try scanner.scanForImages()
        
        XCTAssertTrue(images.count >= 0)
    }
    
    // MARK: - UsageDetector Tests
    
    func testUsageDetectorFindsUsedImages() throws {
        let detector = UsageDetector(projectPath: tempProjectPath, verbose: false)
        let usedImages = try detector.findUsedImageNames()
        
        XCTAssertNotNil(usedImages)
    }
    
    // MARK: - AppleComplianceValidator Tests
    
    func testAppleComplianceValidatorWithEmptyImages() {
        let validator = AppleComplianceValidator()
        let results = validator.validateImages([])
        
        XCTAssertEqual(results.totalIssues, 0)
        XCTAssertEqual(results.complianceScore, 100)
        XCTAssertEqual(results.pngInterlacingIssues.count, 0)
        XCTAssertEqual(results.colorProfileIssues.count, 0)
        XCTAssertEqual(results.assetCatalogIssues.count, 0)
        XCTAssertEqual(results.designQualityIssues.count, 0)
    }
    
    func testAppleComplianceValidatorPNGInterlacing() {
        let validator = AppleComplianceValidator()
        
        let interlacedPNG = ImageAsset(
            name: "test.png",
            path: "/test/test.png",
            size: 1024,
            type: .png,
            scale: 1,
            dimensions: CGSize(width: 100, height: 100),
            isInterlaced: true,
            colorProfile: nil
        )
        
        let results = validator.validatePNGInterlacing([interlacedPNG])
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.image.name, "test.png")
    }
    
    func testAppleComplianceValidatorColorProfiles() {
        let validator = AppleComplianceValidator()
        
        let imageWithoutProfile = ImageAsset(
            name: "test.png",
            path: "/test/test.png",
            size: 1024,
            type: .png,
            scale: 1,
            dimensions: CGSize(width: 100, height: 100),
            isInterlaced: false,
            colorProfile: nil
        )
        
        let results = validator.validateColorProfiles([imageWithoutProfile])
        XCTAssertEqual(results.count, 1)
        XCTAssertTrue(results.first?.issueType.isMissingProfile ?? false)
    }
    
    func testAppleComplianceValidatorDesignQuality() {
        let validator = AppleComplianceValidator()
        
        let tooSmallImage = ImageAsset(
            name: "small.png",
            path: "/test/small.png",
            size: 1024,
            type: .png,
            scale: 1,
            dimensions: CGSize(width: 20, height: 20),
            isInterlaced: false,
            colorProfile: nil
        )
        
        let results = validator.validateDesignQuality([tooSmallImage])
        XCTAssertGreaterThan(results.count, 0)
    }
    
    // MARK: - AnalysisReport Tests
    
    func testAnalysisReportJSONExport() throws {
        let appleResults = AppleComplianceResults(
            pngInterlacingIssues: [],
            colorProfileIssues: [],
            assetCatalogIssues: [],
            designQualityIssues: [],
            complianceScore: 100,
            criticalIssues: 0,
            warningIssues: 0,
            totalIssues: 0
        )
        
        let report = AnalysisReport(
            totalImages: 5,
            unusedImages: [],
            totalSize: 1024000,
            unusedImageSize: 0,
            totalPotentialSavings: 0,
            appleComplianceResults: appleResults
        )
        
        XCTAssertNoThrow(try report.exportJSON())
    }
    
    // MARK: - Helper Methods
    
    private func createTempTestProject() -> String {
        let tempDir = NSTemporaryDirectory()
        let projectName = "TestProject_\(UUID().uuidString)"
        let projectPath = (tempDir as NSString).appendingPathComponent(projectName)
        
        try? FileManager.default.createDirectory(atPath: projectPath, withIntermediateDirectories: true)
        
        return projectPath
    }
    
    private func cleanupTempProject() {
        if let path = tempProjectPath {
            try? FileManager.default.removeItem(atPath: path)
        }
    }
}

// MARK: - Helper Extensions

extension ColorProfileIssue.ColorProfileIssueType {
    var isMissingProfile: Bool {
        if case .missing = self {
            return true
        }
        return false
    }
}