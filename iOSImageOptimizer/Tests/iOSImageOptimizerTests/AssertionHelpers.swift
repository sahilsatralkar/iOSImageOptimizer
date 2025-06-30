import XCTest
import Foundation
import CoreGraphics
@testable import iOSImageOptimizer

// MARK: - XCTestCase Extensions for Custom Assertions

extension XCTestCase {
    
    // MARK: - ImageAsset Assertions
    
    func assertImageAsset(
        _ asset: ImageAsset,
        hasName expectedName: String,
        type expectedType: ImageAsset.ImageType,
        size expectedSize: Int64? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(asset.name, expectedName, "Image asset name mismatch", file: file, line: line)
        XCTAssertEqual(asset.type, expectedType, "Image asset type mismatch", file: file, line: line)
        
        if let expectedSize = expectedSize {
            XCTAssertEqual(asset.size, expectedSize, "Image asset size mismatch", file: file, line: line)
        }
    }
    
    func assertImageAsset(
        _ asset: ImageAsset,
        hasDimensions expectedDimensions: CGSize,
        scale expectedScale: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertNotNil(asset.dimensions, "Image asset should have dimensions", file: file, line: line)
        
        if let dimensions = asset.dimensions {
            XCTAssertEqual(dimensions.width, expectedDimensions.width, accuracy: 0.1, 
                          "Image width mismatch", file: file, line: line)
            XCTAssertEqual(dimensions.height, expectedDimensions.height, accuracy: 0.1, 
                          "Image height mismatch", file: file, line: line)
        }
        
        if let expectedScale = expectedScale {
            XCTAssertEqual(asset.scale, expectedScale, "Image scale mismatch", file: file, line: line)
        }
    }
    
    func assertImageAsset(
        _ asset: ImageAsset,
        hasColorProfile expectedProfile: String?,
        isInterlaced expectedInterlaced: Bool? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(asset.colorProfile, expectedProfile, "Color profile mismatch", file: file, line: line)
        
        if let expectedInterlaced = expectedInterlaced {
            XCTAssertEqual(asset.isInterlaced, expectedInterlaced, "Interlaced state mismatch", file: file, line: line)
        }
    }
    
    // MARK: - Apple Compliance Results Assertions
    
    func assertComplianceResults(
        _ results: AppleComplianceResults,
        hasScore expectedScore: Int,
        criticalIssues expectedCritical: Int,
        warningIssues expectedWarnings: Int? = nil,
        totalIssues expectedTotal: Int? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(results.complianceScore, expectedScore, "Compliance score mismatch", file: file, line: line)
        XCTAssertEqual(results.criticalIssues, expectedCritical, "Critical issues count mismatch", file: file, line: line)
        
        if let expectedWarnings = expectedWarnings {
            XCTAssertEqual(results.warningIssues, expectedWarnings, "Warning issues count mismatch", file: file, line: line)
        }
        
        if let expectedTotal = expectedTotal {
            XCTAssertEqual(results.totalIssues, expectedTotal, "Total issues count mismatch", file: file, line: line)
        }
        
        // Validate internal consistency
        let calculatedTotal = results.pngInterlacingIssues.count + 
                             results.colorProfileIssues.count + 
                             results.assetCatalogIssues.count + 
                             results.designQualityIssues.count
        XCTAssertEqual(results.totalIssues, calculatedTotal, 
                      "Total issues should equal sum of individual issue counts", file: file, line: line)
    }
    
    func assertComplianceResults(
        _ results: AppleComplianceResults,
        hasPNGIssues expectedPNG: Int,
        colorIssues expectedColor: Int,
        assetIssues expectedAsset: Int,
        designIssues expectedDesign: Int,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(results.pngInterlacingIssues.count, expectedPNG, 
                      "PNG interlacing issues count mismatch", file: file, line: line)
        XCTAssertEqual(results.colorProfileIssues.count, expectedColor, 
                      "Color profile issues count mismatch", file: file, line: line)
        XCTAssertEqual(results.assetCatalogIssues.count, expectedAsset, 
                      "Asset catalog issues count mismatch", file: file, line: line)
        XCTAssertEqual(results.designQualityIssues.count, expectedDesign, 
                      "Design quality issues count mismatch", file: file, line: line)
    }
    
    // MARK: - Analysis Report Assertions
    
    func assertAnalysisReport(
        _ report: AnalysisReport,
        totalImages expectedTotal: Int,
        unusedImages expectedUnused: Int,
        totalSize expectedTotalSize: Int64? = nil,
        potentialSavings expectedSavings: Int64? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertEqual(report.totalImages, expectedTotal, "Total images count mismatch", file: file, line: line)
        XCTAssertEqual(report.unusedImages.count, expectedUnused, "Unused images count mismatch", file: file, line: line)
        
        if let expectedTotalSize = expectedTotalSize {
            XCTAssertEqual(report.totalSize, expectedTotalSize, "Total size mismatch", file: file, line: line)
        }
        
        if let expectedSavings = expectedSavings {
            XCTAssertEqual(report.totalPotentialSavings, expectedSavings, 
                          "Potential savings mismatch", file: file, line: line)
        }
        
        // Validate internal consistency
        XCTAssertEqual(report.unusedImageSize, report.unusedImages.reduce(0) { $0 + $1.size },
                      "Unused image size should equal sum of individual unused image sizes", file: file, line: line)
        XCTAssertEqual(report.totalPotentialSavings, report.unusedImageSize,
                      "Total potential savings should equal unused image size", file: file, line: line)
    }
    
    // MARK: - Collection Assertions
    
    func assertContains<T: Equatable>(
        _ collection: [T],
        _ expectedItem: T,
        message: String = "Collection should contain expected item",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(collection.contains(expectedItem), message, file: file, line: line)
    }
    
    func assertContains(
        _ collection: [String],
        itemMatching pattern: String,
        message: String = "Collection should contain item matching pattern",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let matches = collection.filter { $0.range(of: pattern, options: .regularExpression) != nil }
        XCTAssertFalse(matches.isEmpty, "\(message). Pattern: \(pattern)", file: file, line: line)
    }
    
    func assertContains(
        _ collection: [ImageAsset],
        imageNamed expectedName: String,
        message: String = "Collection should contain image with expected name",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let matches = collection.filter { $0.name == expectedName }
        XCTAssertFalse(matches.isEmpty, "\(message). Expected name: \(expectedName)", file: file, line: line)
    }
    
    func assertDoesNotContain(
        _ collection: [ImageAsset],
        imageNamed unexpectedName: String,
        message: String = "Collection should not contain image with unexpected name",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let matches = collection.filter { $0.name == unexpectedName }
        XCTAssertTrue(matches.isEmpty, "\(message). Unexpected name: \(unexpectedName)", file: file, line: line)
    }
    
    // MARK: - File System Assertions
    
    func assertFileExists(
        at path: String,
        message: String = "File should exist at path",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), 
                     "\(message): \(path)", file: file, line: line)
    }
    
    func assertDirectoryExists(
        at path: String,
        message: String = "Directory should exist at path",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        XCTAssertTrue(exists && isDirectory.boolValue, 
                     "\(message): \(path)", file: file, line: line)
    }
    
    func assertFileSize(
        at path: String,
        expectedSize: Int64,
        tolerance: Int64 = 0,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            let actualSize = attributes[.size] as? Int64 ?? 0
            
            if tolerance == 0 {
                XCTAssertEqual(actualSize, expectedSize, "File size mismatch at \(path)", file: file, line: line)
            } else {
                let difference = abs(actualSize - expectedSize)
                XCTAssertLessThanOrEqual(difference, tolerance, 
                                       "File size \(actualSize) not within tolerance \(tolerance) of expected \(expectedSize)", 
                                       file: file, line: line)
            }
        } catch {
            XCTFail("Failed to get file attributes for \(path): \(error)", file: file, line: line)
        }
    }
    
    // MARK: - JSON Assertions
    
    func assertValidJSON(
        _ data: Data,
        message: String = "Data should be valid JSON",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            _ = try JSONSerialization.jsonObject(with: data, options: [])
        } catch {
            XCTFail("\(message): \(error)", file: file, line: line)
        }
    }
    
    func assertJSONContains(
        _ data: Data,
        key: String,
        expectedValue: Any,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
                XCTFail("JSON should be a dictionary", file: file, line: line)
                return
            }
            
            guard let actualValue = json[key] else {
                XCTFail("JSON should contain key '\(key)'", file: file, line: line)
                return
            }
            
            // Use string comparison for flexibility
            let actualString = String(describing: actualValue)
            let expectedString = String(describing: expectedValue)
            XCTAssertEqual(actualString, expectedString, 
                          "JSON value mismatch for key '\(key)'", file: file, line: line)
        } catch {
            XCTFail("Failed to parse JSON: \(error)", file: file, line: line)
        }
    }
    
    // MARK: - Performance Assertions
    
    func assertPerformance(
        description: String = "Performance test",
        expectedDuration: TimeInterval,
        tolerance: TimeInterval = 0.1,
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () throws -> Void
    ) rethrows {
        let startTime = CFAbsoluteTimeGetCurrent()
        try block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        let difference = abs(duration - expectedDuration)
        XCTAssertLessThanOrEqual(difference, tolerance,
                               "\(description): Duration \(duration)s not within \(tolerance)s of expected \(expectedDuration)s",
                               file: file, line: line)
    }
    
    func assertFasterThan(
        _ maxDuration: TimeInterval,
        description: String = "Performance test",
        file: StaticString = #file,
        line: UInt = #line,
        _ block: () throws -> Void
    ) rethrows {
        let startTime = CFAbsoluteTimeGetCurrent()
        try block()
        let duration = CFAbsoluteTimeGetCurrent() - startTime
        
        XCTAssertLessThan(duration, maxDuration,
                         "\(description): Duration \(duration)s exceeded maximum \(maxDuration)s",
                         file: file, line: line)
    }
    
    // MARK: - Error Assertions
    
    func assertThrowsError<T>(
        _ expression: @autoclosure () throws -> T,
        expectedErrorType: Error.Type,
        message: String = "Expected specific error type",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        do {
            _ = try expression()
            XCTFail("\(message): Expected error of type \(expectedErrorType)", file: file, line: line)
        } catch {
            XCTAssertTrue(type(of: error) == expectedErrorType,
                         "\(message): Expected \(expectedErrorType), got \(type(of: error))",
                         file: file, line: line)
        }
    }
    
    func assertNoThrow<T>(
        _ expression: @autoclosure () throws -> T,
        message: String = "Expression should not throw",
        file: StaticString = #file,
        line: UInt = #line
    ) -> T? {
        do {
            return try expression()
        } catch {
            XCTFail("\(message): Unexpected error: \(error)", file: file, line: line)
            return nil
        }
    }
}

// MARK: - Custom Matcher Functions

func beEmpty<T: Collection>() -> (T) -> Bool {
    return { collection in
        return collection.isEmpty
    }
}

func haveCount<T: Collection>(_ expectedCount: Int) -> (T) -> Bool {
    return { collection in
        return collection.count == expectedCount
    }
}

func contain<T: Equatable>(_ expectedItem: T) -> ([T]) -> Bool {
    return { collection in
        return collection.contains(expectedItem)
    }
}

// MARK: - Test Result Validation Helpers

extension XCTestCase {
    
    func validateImageAssetArray(_ images: [ImageAsset], expectedCount: Int? = nil, file: StaticString = #file, line: UInt = #line) {
        if let expectedCount = expectedCount {
            XCTAssertEqual(images.count, expectedCount, "Image array count mismatch", file: file, line: line)
        }
        
        for image in images {
            XCTAssertFalse(image.name.isEmpty, "Image name should not be empty", file: file, line: line)
            XCTAssertFalse(image.path.isEmpty, "Image path should not be empty", file: file, line: line)
            XCTAssertGreaterThan(image.size, 0, "Image size should be positive", file: file, line: line)
        }
    }
    
    func validateUsedImageNames(_ names: Set<String>, expectedCount: Int? = nil, file: StaticString = #file, line: UInt = #line) {
        if let expectedCount = expectedCount {
            XCTAssertEqual(names.count, expectedCount, "Used image names count mismatch", file: file, line: line)
        }
        
        for name in names {
            XCTAssertFalse(name.isEmpty, "Image name should not be empty", file: file, line: line)
            XCTAssertFalse(name.contains("  "), "Image name should not contain double spaces", file: file, line: line)
        }
    }
}