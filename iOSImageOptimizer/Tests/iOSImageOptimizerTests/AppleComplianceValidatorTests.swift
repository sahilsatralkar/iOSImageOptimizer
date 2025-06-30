import XCTest
import Foundation
import CoreGraphics
@testable import iOSImageOptimizer

final class AppleComplianceValidatorTests: XCTestCase {
    
    var validator: AppleComplianceValidator!
    
    override func setUp() {
        super.setUp()
        validator = AppleComplianceValidator()
    }
    
    override func tearDown() {
        validator = nil
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testValidateImages_EmptyArray() {
        let results = validator.validateImages([])
        
        XCTAssertEqual(results.pngInterlacingIssues.count, 0, "Empty array should have no PNG issues")
        XCTAssertEqual(results.colorProfileIssues.count, 0, "Empty array should have no color profile issues")
        XCTAssertEqual(results.assetCatalogIssues.count, 0, "Empty array should have no asset catalog issues")
        XCTAssertEqual(results.designQualityIssues.count, 0, "Empty array should have no design quality issues")
        XCTAssertEqual(results.totalIssues, 0, "Total issues should be 0")
        XCTAssertEqual(results.criticalIssues, 0, "Critical issues should be 0")
        XCTAssertEqual(results.warningIssues, 0, "Warning issues should be 0")
        XCTAssertEqual(results.complianceScore, 100, "Compliance score should be 100 for no images")
    }
    
    func testValidateImages_PerfectImages() {
        let perfectImages = [
            createMockImageAsset(
                name: "perfect_image",
                path: "/project/Assets.xcassets/perfect_image.imageset/perfect_image.png",
                type: .assetCatalog(scale: "1x"),
                scale: 1,
                dimensions: CGSize(width: 44, height: 44),
                isInterlaced: false,
                colorProfile: "sRGB"
            ),
            createMockImageAsset(
                name: "perfect_image",
                path: "/project/Assets.xcassets/perfect_image.imageset/perfect_image@2x.png",
                type: .assetCatalog(scale: "2x"),
                scale: 2,
                dimensions: CGSize(width: 88, height: 88),
                isInterlaced: false,
                colorProfile: "sRGB"
            ),
            createMockImageAsset(
                name: "perfect_image",
                path: "/project/Assets.xcassets/perfect_image.imageset/perfect_image@3x.png",
                type: .assetCatalog(scale: "3x"),
                scale: 3,
                dimensions: CGSize(width: 132, height: 132),
                isInterlaced: false,
                colorProfile: "sRGB"
            )
        ]
        
        let results = validator.validateImages(perfectImages)
        
        XCTAssertEqual(results.totalIssues, 0, "Perfect images should have no issues")
        XCTAssertEqual(results.criticalIssues, 0, "Perfect images should have no critical issues")
        XCTAssertEqual(results.complianceScore, 100, "Perfect images should have 100% compliance score")
    }
    
    // MARK: - PNG Interlacing Tests
    
    func testValidatePNGInterlacing_InterlacedPNG() {
        let interlacedImage = createMockImageAsset(
            name: "interlaced_test",
            type: .png,
            dimensions: CGSize(width: 200, height: 200),
            isInterlaced: true
        )
        
        let issues = validator.validatePNGInterlacing([interlacedImage])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 interlaced PNG issue")
        
        let issue = issues[0]
        XCTAssertEqual(issue.image.name, "interlaced_test", "Issue should reference correct image")
        XCTAssertEqual(issue.performanceImpact, "Medium", "200x200 image should have medium performance impact")
        XCTAssertTrue(issue.recommendation.contains("de-interlaced"), "Should recommend de-interlacing")
    }
    
    func testValidatePNGInterlacing_NonInterlacedPNG() {
        let nonInterlacedImage = createMockImageAsset(
            name: "non_interlaced_test",
            type: .png,
            dimensions: CGSize(width: 100, height: 100),
            isInterlaced: false
        )
        
        let issues = validator.validatePNGInterlacing([nonInterlacedImage])
        
        XCTAssertEqual(issues.count, 0, "Non-interlaced PNG should have no issues")
    }
    
    func testValidatePNGInterlacing_AssetCatalogPNG() {
        let assetCatalogInterlaced = createMockImageAsset(
            name: "catalog_interlaced",
            type: .assetCatalog(scale: "1x"),
            dimensions: CGSize(width: 100, height: 100),
            isInterlaced: true
        )
        
        let issues = validator.validatePNGInterlacing([assetCatalogInterlaced])
        
        XCTAssertEqual(issues.count, 1, "Asset catalog interlaced PNG should be flagged")
        XCTAssertEqual(issues[0].performanceImpact, "Medium", "100x100 image should have medium impact")
    }
    
    func testValidatePNGInterlacing_PerformanceImpactLevels() {
        let smallImage = createMockImageAsset(
            name: "small_interlaced",
            type: .png,
            dimensions: CGSize(width: 100, height: 100), // 10,000 pixels
            isInterlaced: true
        )
        
        let mediumImage = createMockImageAsset(
            name: "medium_interlaced",
            type: .png,
            dimensions: CGSize(width: 500, height: 500), // 250,000 pixels
            isInterlaced: true
        )
        
        let largeImage = createMockImageAsset(
            name: "large_interlaced",
            type: .png,
            dimensions: CGSize(width: 2000, height: 2000), // 4,000,000 pixels
            isInterlaced: true
        )
        
        let issues = validator.validatePNGInterlacing([smallImage, mediumImage, largeImage])
        
        XCTAssertEqual(issues.count, 3, "Should find 3 interlaced PNG issues")
        XCTAssertEqual(issues[0].performanceImpact, "Medium", "Small image should have medium impact")
        XCTAssertEqual(issues[1].performanceImpact, "High", "Medium image should have high impact")
        XCTAssertEqual(issues[2].performanceImpact, "Critical", "Large image should have critical impact")
    }
    
    func testValidatePNGInterlacing_NonPNGImages() {
        let jpegImage = createMockImageAsset(name: "test_jpeg", type: .jpeg, isInterlaced: true)
        let pdfImage = createMockImageAsset(name: "test_pdf", type: .pdf, isInterlaced: true)
        let svgImage = createMockImageAsset(name: "test_svg", type: .svg, isInterlaced: true)
        
        let issues = validator.validatePNGInterlacing([jpegImage, pdfImage, svgImage])
        
        XCTAssertEqual(issues.count, 0, "Non-PNG images should not be checked for interlacing")
    }
    
    // MARK: - Color Profile Tests
    
    func testValidateColorProfiles_MissingProfile() {
        let imageWithoutProfile = createMockImageAsset(
            name: "no_profile",
            type: .png,
            colorProfile: nil
        )
        
        let issues = validator.validateColorProfiles([imageWithoutProfile])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 missing color profile issue")
        
        let issue = issues[0]
        XCTAssertEqual(issue.image.name, "no_profile", "Issue should reference correct image")
        if case .missing = issue.issueType {} else {
            XCTFail("Issue type should be missing")
        }
        XCTAssertTrue(issue.recommendation.contains("sRGB"), "Should recommend sRGB profile")
    }
    
    func testValidateColorProfiles_RecommendedProfiles() {
        let sRGBImage = createMockImageAsset(name: "srgb_image", type: .png, colorProfile: "sRGB")
        let displayP3Image = createMockImageAsset(name: "p3_image", type: .png, colorProfile: "Display P3")
        let rgbImage = createMockImageAsset(name: "rgb_image", type: .png, colorProfile: "RGB")
        
        let issues = validator.validateColorProfiles([sRGBImage, displayP3Image, rgbImage])
        
        XCTAssertEqual(issues.count, 0, "Recommended color profiles should have no issues")
    }
    
    func testValidateColorProfiles_IncompatibleProfile() {
        let cmykImage = createMockImageAsset(
            name: "cmyk_image",
            type: .png,
            colorProfile: "CMYK"
        )
        
        let issues = validator.validateColorProfiles([cmykImage])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 incompatible color profile issue")
        
        let issue = issues[0]
        if case .incompatible(let current, let recommended) = issue.issueType {
            XCTAssertEqual(current, "CMYK", "Should identify current profile")
            XCTAssertEqual(recommended, "sRGB", "Should recommend sRGB")
        } else {
            XCTFail("Issue type should be incompatible")
        }
    }
    
    func testValidateColorProfiles_OutdatedProfile() {
        let adobeRGBImage = createMockImageAsset(
            name: "adobe_rgb_image",
            type: .png,
            colorProfile: "Adobe RGB"
        )
        
        let issues = validator.validateColorProfiles([adobeRGBImage])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 outdated color profile issue")
        
        let issue = issues[0]
        if case .outdated(let current) = issue.issueType {
            XCTAssertEqual(current, "Adobe RGB", "Should identify outdated profile")
        } else {
            XCTFail("Issue type should be outdated")
        }
        XCTAssertTrue(issue.recommendation.contains("modern"), "Should recommend modern profile")
    }
    
    func testValidateColorProfiles_MultipleIssues() {
        let missingProfile = createMockImageAsset(name: "missing", type: .png, colorProfile: nil)
        let incompatibleProfile = createMockImageAsset(name: "incompatible", type: .png, colorProfile: "CMYK")
        let outdatedProfile = createMockImageAsset(name: "outdated", type: .png, colorProfile: "ProPhoto RGB")
        
        let issues = validator.validateColorProfiles([missingProfile, incompatibleProfile, outdatedProfile])
        
        XCTAssertEqual(issues.count, 3, "Should find 3 different color profile issues")
        
        let issueTypes = issues.map { $0.issueType }
        let hasMissing = issueTypes.contains { if case .missing = $0 { return true }; return false }
        let hasIncompatible = issueTypes.contains { if case .incompatible = $0 { return true }; return false }
        let hasOutdated = issueTypes.contains { if case .outdated = $0 { return true }; return false }
        
        XCTAssertTrue(hasMissing, "Should have missing profile issue")
        XCTAssertTrue(hasIncompatible, "Should have incompatible profile issue")
        XCTAssertTrue(hasOutdated, "Should have outdated profile issue")
    }
    
    // MARK: - Asset Catalog Organization Tests
    
    func testValidateAssetCatalogOrganization_StandaloneImagesShouldBeInCatalog() {
        let iconImage = createMockImageAsset(
            name: "app_icon",
            path: "/project/Images/app_icon.png",
            type: .png
        )
        
        let buttonImage = createMockImageAsset(
            name: "submit_button",
            path: "/project/Resources/submit_button.png",
            type: .png
        )
        
        let issues = validator.validateAssetCatalogOrganization([iconImage, buttonImage])
        
        XCTAssertEqual(issues.count, 2, "Should find 2 issues for standalone UI images")
        
        for issue in issues {
            if case .shouldBeInCatalog = issue.issueType {} else {
                XCTFail("Issue type should be shouldBeInCatalog")
            }
            XCTAssertTrue(issue.recommendation.contains("Asset Catalog"), "Should recommend asset catalog")
        }
    }
    
    func testValidateAssetCatalogOrganization_MissingScaleVariants() {
        let onlyHighResImage = createMockImageAsset(
            name: "incomplete_icon",
            path: "/project/Assets.xcassets/incomplete_icon.imageset/incomplete_icon@3x.png",
            type: .assetCatalog(scale: "3x"),
            scale: 3
        )
        
        let issues = validator.validateAssetCatalogOrganization([onlyHighResImage])
        
        // The implementation creates both missing scale variant AND orphaned scale issues for a single @3x image
        XCTAssertEqual(issues.count, 2, "Should find missing scale variant issue and orphaned scale issue")
        
        // Check that we have both issue types
        let issueTypes = issues.map { $0.issueType }
        let hasMissingVariant = issueTypes.contains { if case .missingScaleVariant = $0 { return true }; return false }
        let hasOrphanedScale = issueTypes.contains { if case .orphanedScale = $0 { return true }; return false }
        
        XCTAssertTrue(hasMissingVariant, "Should have missing scale variant issue")
        XCTAssertTrue(hasOrphanedScale, "Should have orphaned scale issue")
        
        // Check the missing scale variant issue details
        if let missingVariantIssue = issues.first(where: { if case .missingScaleVariant = $0.issueType { return true }; return false }) {
            if case .missingScaleVariant(let missing) = missingVariantIssue.issueType {
                XCTAssertEqual(missing.sorted(), ["@1x", "@2x"], "Should be missing @1x and @2x variants")
            }
        }
    }
    
    func testValidateAssetCatalogOrganization_OrphanedScale() {
        let orphanedHighRes = createMockImageAsset(
            name: "orphaned_icon",
            path: "/project/Assets.xcassets/orphaned_icon.imageset/orphaned_icon@2x.png",
            type: .assetCatalog(scale: "2x"),
            scale: 2
        )
        
        let issues = validator.validateAssetCatalogOrganization([orphanedHighRes])
        
        // The implementation creates both missing scale variant AND orphaned scale issues for a single @2x image
        XCTAssertEqual(issues.count, 2, "Should find missing scale variant issue and orphaned scale issue")
        
        // Check that we have both issue types
        let issueTypes = issues.map { $0.issueType }
        let hasMissingVariant = issueTypes.contains { if case .missingScaleVariant = $0 { return true }; return false }
        let hasOrphanedScale = issueTypes.contains { if case .orphanedScale = $0 { return true }; return false }
        
        XCTAssertTrue(hasMissingVariant, "Should have missing scale variant issue")
        XCTAssertTrue(hasOrphanedScale, "Should have orphaned scale issue")
        
        // Check the orphaned scale issue details
        if let orphanedIssue = issues.first(where: { if case .orphanedScale = $0.issueType { return true }; return false }) {
            if case .orphanedScale(let scale) = orphanedIssue.issueType {
                XCTAssertEqual(scale, "@2x", "Should identify @2x as orphaned")
            }
            XCTAssertTrue(orphanedIssue.recommendation.contains("@1x"), "Should recommend adding @1x variant")
        }
    }
    
    func testValidateAssetCatalogOrganization_CompleteScaleSet() {
        let baseImage = createMockImageAsset(
            name: "complete_icon",
            path: "/project/Assets.xcassets/complete_icon.imageset/complete_icon.png",
            type: .assetCatalog(scale: "1x"),
            scale: 1
        )
        
        let retinaImage = createMockImageAsset(
            name: "complete_icon",
            path: "/project/Assets.xcassets/complete_icon.imageset/complete_icon@2x.png",
            type: .assetCatalog(scale: "2x"),
            scale: 2
        )
        
        let superRetinaImage = createMockImageAsset(
            name: "complete_icon",
            path: "/project/Assets.xcassets/complete_icon.imageset/complete_icon@3x.png",
            type: .assetCatalog(scale: "3x"),
            scale: 3
        )
        
        let issues = validator.validateAssetCatalogOrganization([baseImage, retinaImage, superRetinaImage])
        
        XCTAssertEqual(issues.count, 0, "Complete scale set should have no issues")
    }
    
    func testValidateAssetCatalogOrganization_NonUIImagesShouldNotBeInCatalog() {
        let documentImage = createMockImageAsset(
            name: "user_document",
            path: "/project/Documents/user_document.pdf",
            type: .pdf
        )
        
        let photoImage = createMockImageAsset(
            name: "vacation_photo",
            path: "/project/Photos/vacation_photo.jpg",
            type: .jpeg
        )
        
        let issues = validator.validateAssetCatalogOrganization([documentImage, photoImage])
        
        XCTAssertEqual(issues.count, 0, "Non-UI images should not be flagged for asset catalog organization")
    }
    
    // MARK: - Design Quality Tests
    
    func testValidateDesignQuality_NonIntegerScaling() {
        let badScalingImage = createMockImageAsset(
            name: "bad_scaling",
            type: .assetCatalog(scale: "2x"),
            scale: 2,
            dimensions: CGSize(width: 45, height: 45) // Should be 44x44 for perfect 2x scaling
        )
        
        let issues = validator.validateDesignQuality([badScalingImage])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 non-integer scaling issue")
        
        let issue = issues[0]
        XCTAssertEqual(issue.issueType, .nonIntegerScaling, "Issue type should be non-integer scaling")
        XCTAssertEqual(issue.impact, "May cause blurry rendering", "Should describe blurring impact")
        XCTAssertTrue(issue.recommendation.contains("whole numbers"), "Should recommend whole number scaling")
    }
    
    func testValidateDesignQuality_PerfectScaling() {
        let perfectScalingImage = createMockImageAsset(
            name: "perfect_scaling",
            type: .assetCatalog(scale: "2x"),
            scale: 2,
            dimensions: CGSize(width: 88, height: 88) // Perfect 2x scaling of 44x44
        )
        
        let issues = validator.validateDesignQuality([perfectScalingImage])
        
        XCTAssertEqual(issues.count, 0, "Perfect scaling should have no issues")
    }
    
    func testValidateDesignQuality_TooSmallForHighRes() {
        let tinyImage = createMockImageAsset(
            name: "tiny_icon",
            type: .png,
            dimensions: CGSize(width: 16, height: 16)
        )
        
        let issues = validator.validateDesignQuality([tinyImage])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 too-small issue")
        
        let issue = issues[0]
        XCTAssertEqual(issue.issueType, .tooSmallForHighRes, "Issue type should be too small")
        XCTAssertTrue(issue.impact.contains("pixelated"), "Should describe pixelation impact")
        XCTAssertTrue(issue.recommendation.contains("44×44"), "Should recommend minimum size")
    }
    
    func testValidateDesignQuality_LargeEnoughForHighRes() {
        let appropriateSizeImage = createMockImageAsset(
            name: "good_size_icon",
            type: .png,
            dimensions: CGSize(width: 44, height: 44)
        )
        
        let issues = validator.validateDesignQuality([appropriateSizeImage])
        
        XCTAssertEqual(issues.count, 0, "Appropriately sized image should have no issues")
    }
    
    func testValidateDesignQuality_InefficientDimensions() {
        let hugeImage = createMockImageAsset(
            name: "huge_image",
            type: .png,
            dimensions: CGSize(width: 3000, height: 2000) // 6 megapixels
        )
        
        let issues = validator.validateDesignQuality([hugeImage])
        
        XCTAssertEqual(issues.count, 1, "Should find 1 inefficient dimensions issue")
        
        let issue = issues[0]
        XCTAssertEqual(issue.issueType, .inefficientDimensions, "Issue type should be inefficient dimensions")
        XCTAssertTrue(issue.impact.contains("memory"), "Should describe memory impact")
        XCTAssertTrue(issue.impact.contains("6.0MP"), "Should show megapixel count")
        XCTAssertTrue(issue.recommendation.contains("reducing dimensions"), "Should recommend size reduction")
    }
    
    func testValidateDesignQuality_MultipleIssues() {
        let problematicImage = createMockImageAsset(
            name: "problematic",
            type: .assetCatalog(scale: "2x"),
            scale: 2,
            dimensions: CGSize(width: 15, height: 15) // Too small AND bad scaling
        )
        
        let issues = validator.validateDesignQuality([problematicImage])
        
        XCTAssertEqual(issues.count, 2, "Should find multiple design quality issues")
        
        let issueTypes = issues.map { $0.issueType }
        XCTAssertTrue(issueTypes.contains(.nonIntegerScaling), "Should have non-integer scaling issue")
        XCTAssertTrue(issueTypes.contains(.tooSmallForHighRes), "Should have too-small issue")
    }
    
    // MARK: - Compliance Scoring Tests
    
    func testComplianceScore_NoCriticalIssues() {
        let goodImage = createMockImageAsset(
            name: "good_icon",
            path: "/project/Icons/good_icon.png", // Standalone but not UI-related name
            type: .png,
            dimensions: CGSize(width: 100, height: 100),
            isInterlaced: false,
            colorProfile: "sRGB"
        )
        
        let results = validator.validateImages([goodImage])
        
        // Might have warning issues (like asset catalog organization) but no critical ones
        XCTAssertEqual(results.criticalIssues, 0, "Should have no critical issues")
        XCTAssertGreaterThanOrEqual(results.complianceScore, 70, "Score should be reasonably high with only warnings")
    }
    
    func testComplianceScore_ManyCriticalIssues() {
        let badImages = [
            createMockImageAsset(
                name: "bad1",
                type: .png,
                dimensions: CGSize(width: 2000, height: 2000), // Too large
                isInterlaced: true, // Critical PNG issue
                colorProfile: nil // Missing color profile
            ),
            createMockImageAsset(
                name: "bad2",
                type: .png,
                dimensions: CGSize(width: 20, height: 20), // Too small
                isInterlaced: false,
                colorProfile: nil // Missing color profile
            )
        ]
        
        let results = validator.validateImages(badImages)
        
        XCTAssertGreaterThan(results.criticalIssues, 3, "Should have multiple critical issues")
        XCTAssertLessThan(results.complianceScore, 50, "Score should be low with many critical issues")
    }
    
    func testComplianceScore_EdgeCases() {
        // Test with single image having maximum issues
        let worstImage = createMockImageAsset(
            name: "app_icon", // Will trigger asset catalog issue
            type: .png,
            dimensions: CGSize(width: 3000, height: 3000), // Huge and inefficient
            isInterlaced: true, // PNG interlacing issue
            colorProfile: nil // Missing color profile
        )
        
        let results = validator.validateImages([worstImage])
        
        XCTAssertGreaterThan(results.totalIssues, 2, "Should have multiple issues")
        XCTAssertGreaterThan(results.criticalIssues, 1, "Should have critical issues")
        XCTAssertGreaterThanOrEqual(results.complianceScore, 0, "Score should not go below 0")
        XCTAssertLessThanOrEqual(results.complianceScore, 100, "Score should not exceed 100")
    }
    
    // MARK: - Integration Tests
    
    func testValidateImages_CompleteWorkflow() {
        let mixedImages = [
            // Perfect asset catalog image
            createMockImageAsset(
                name: "perfect_icon",
                path: "/project/Assets.xcassets/perfect_icon.imageset/perfect_icon@2x.png",
                type: .assetCatalog(scale: "2x"),
                scale: 2,
                dimensions: CGSize(width: 88, height: 88),
                isInterlaced: false,
                colorProfile: "sRGB"
            ),
            
            // Problematic standalone image
            createMockImageAsset(
                name: "problematic_button",
                path: "/project/Images/problematic_button.png",
                type: .png,
                dimensions: CGSize(width: 100, height: 100),
                isInterlaced: true,
                colorProfile: "CMYK"
            ),
            
            // Missing color profile
            createMockImageAsset(
                name: "no_profile",
                type: .jpeg,
                dimensions: CGSize(width: 200, height: 200),
                colorProfile: nil
            )
        ]
        
        let results = validator.validateImages(mixedImages)
        
        XCTAssertGreaterThan(results.totalIssues, 0, "Should find issues in mixed image set")
        XCTAssertGreaterThan(results.pngInterlacingIssues.count, 0, "Should find PNG interlacing issues")
        XCTAssertGreaterThan(results.colorProfileIssues.count, 0, "Should find color profile issues")
        XCTAssertGreaterThan(results.assetCatalogIssues.count, 0, "Should find asset catalog issues")
        
        // Verify issue categorization
        XCTAssertEqual(results.totalIssues, 
                      results.pngInterlacingIssues.count + 
                      results.colorProfileIssues.count + 
                      results.assetCatalogIssues.count + 
                      results.designQualityIssues.count,
                      "Total issues should sum correctly")
        
        XCTAssertEqual(results.criticalIssues + results.warningIssues, results.totalIssues,
                      "Critical and warning issues should sum to total")
        
        XCTAssertGreaterThanOrEqual(results.complianceScore, 0, "Compliance score should be valid")
        XCTAssertLessThanOrEqual(results.complianceScore, 100, "Compliance score should not exceed 100")
    }
    
    // MARK: - Performance Tests
    
    func testValidateImages_LargeImageSet() {
        var largeImageSet: [ImageAsset] = []
        
        // Create 100 images with various issues
        for i in 1...100 {
            let image = createMockImageAsset(
                name: "test_image_\(i)",
                type: i % 2 == 0 ? .png : .jpeg,
                dimensions: CGSize(width: 100 + i, height: 100 + i),
                isInterlaced: i % 3 == 0,
                colorProfile: i % 4 == 0 ? nil : "sRGB"
            )
            largeImageSet.append(image)
        }
        
        // Measure performance using XCTPerformance
        measure {
            let results = validator.validateImages(largeImageSet)
            XCTAssertGreaterThan(results.totalIssues, 0, "Should find issues in large image set")
        }
    }
    
    // MARK: - Helper Methods
    
    private func createMockImageAsset(
        name: String = "test_image",
        path: String = "/test/test_image.png",
        size: Int64 = 1024,
        type: ImageAsset.ImageType = .png,
        scale: Int? = 1,
        dimensions: CGSize? = CGSize(width: 100, height: 100),
        isInterlaced: Bool? = false,
        colorProfile: String? = "sRGB"
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
}