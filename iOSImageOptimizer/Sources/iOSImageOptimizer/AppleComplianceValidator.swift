import Foundation
import CoreGraphics

// MARK: - Issue Types

struct PNGInterlacingIssue: Encodable {
    let image: ImageAsset
    let performanceImpact: String
    let recommendation: String
}

struct ColorProfileIssue: Encodable {
    let image: ImageAsset
    let issueType: ColorProfileIssueType
    let recommendation: String
    
    enum ColorProfileIssueType: Encodable {
        case missing
        case incompatible(current: String, recommended: String)
        case outdated(current: String)
    }
}

struct AssetCatalogIssue: Encodable {
    let image: ImageAsset
    let issueType: AssetCatalogIssueType
    let recommendation: String
    
    enum AssetCatalogIssueType: Encodable {
        case shouldBeInCatalog
        case missingScaleVariant(missing: [String])
        case orphanedScale(scale: String)
        case incorrectNaming
    }
}

struct DesignQualityIssue: Encodable {
    let image: ImageAsset
    let issueType: DesignQualityIssueType
    let impact: String
    let recommendation: String
    
    enum DesignQualityIssueType: Encodable {
        case nonIntegerScaling
        case tooSmallForHighRes
        case dimensionMismatch
        case inefficientDimensions
    }
}

struct AppleComplianceResults: Encodable {
    let pngInterlacingIssues: [PNGInterlacingIssue]
    let colorProfileIssues: [ColorProfileIssue]
    let assetCatalogIssues: [AssetCatalogIssue]
    let designQualityIssues: [DesignQualityIssue]
    let complianceScore: Int
    let criticalIssues: Int
    let warningIssues: Int
    let totalIssues: Int
}

// MARK: - Apple Compliance Validator

class AppleComplianceValidator {
    
    func validateImages(_ images: [ImageAsset]) -> AppleComplianceResults {
        let pngInterlacingIssues = validatePNGInterlacing(images)
        let colorProfileIssues = validateColorProfiles(images)
        let assetCatalogIssues = validateAssetCatalogOrganization(images)
        let designQualityIssues = validateDesignQuality(images)
        
        let totalIssues = pngInterlacingIssues.count + colorProfileIssues.count + 
                         assetCatalogIssues.count + designQualityIssues.count
        
        let criticalIssues = countCriticalIssues(
            pngIssues: pngInterlacingIssues,
            colorIssues: colorProfileIssues,
            assetIssues: assetCatalogIssues,
            designIssues: designQualityIssues
        )
        
        let warningIssues = totalIssues - criticalIssues
        let complianceScore = calculateComplianceScore(
            totalImages: images.count,
            totalIssues: totalIssues,
            criticalIssues: criticalIssues
        )
        
        return AppleComplianceResults(
            pngInterlacingIssues: pngInterlacingIssues,
            colorProfileIssues: colorProfileIssues,
            assetCatalogIssues: assetCatalogIssues,
            designQualityIssues: designQualityIssues,
            complianceScore: complianceScore,
            criticalIssues: criticalIssues,
            warningIssues: warningIssues,
            totalIssues: totalIssues
        )
    }
    
    // MARK: - PNG Interlacing Validation
    
    func validatePNGInterlacing(_ images: [ImageAsset]) -> [PNGInterlacingIssue] {
        var issues: [PNGInterlacingIssue] = []
        
        for image in images {
            // Check if image is PNG (standalone or in asset catalog)
            let isPNG: Bool
            switch image.type {
            case .png:
                isPNG = true
            case .assetCatalog:
                isPNG = true // Asset catalog images can be PNG
            default:
                isPNG = false
            }
            
            guard isPNG else { continue }
            guard let isInterlaced = image.isInterlaced, isInterlaced else { continue }
            
            let performanceImpact = determinePerformanceImpact(for: image)
            let recommendation = "Convert to de-interlaced PNG for better iOS performance and memory usage"
            
            issues.append(PNGInterlacingIssue(
                image: image,
                performanceImpact: performanceImpact,
                recommendation: recommendation
            ))
        }
        
        return issues
    }
    
    private func determinePerformanceImpact(for image: ImageAsset) -> String {
        guard let dimensions = image.dimensions else { return "Unknown" }
        
        let pixelCount = dimensions.width * dimensions.height
        
        if pixelCount > 1_000_000 { // > 1 megapixel
            return "Critical"
        } else if pixelCount > 100_000 { // > 0.1 megapixel
            return "High"
        } else {
            return "Medium"
        }
    }
    
    // MARK: - Color Profile Validation
    
    func validateColorProfiles(_ images: [ImageAsset]) -> [ColorProfileIssue] {
        var issues: [ColorProfileIssue] = []
        
        for image in images {
            if let colorProfile = image.colorProfile {
                // Check if profile is compatible/recommended
                if !isRecommendedColorProfile(colorProfile) {
                    let recommended = getRecommendedColorProfile(for: image)
                    issues.append(ColorProfileIssue(
                        image: image,
                        issueType: .incompatible(current: colorProfile, recommended: recommended),
                        recommendation: "Use \(recommended) color profile for better iOS compatibility"
                    ))
                }
                
                // Check if profile is outdated
                if isOutdatedColorProfile(colorProfile) {
                    issues.append(ColorProfileIssue(
                        image: image,
                        issueType: .outdated(current: colorProfile),
                        recommendation: "Update to modern color profile (sRGB or Display P3)"
                    ))
                }
            } else {
                // Missing color profile
                issues.append(ColorProfileIssue(
                    image: image,
                    issueType: .missing,
                    recommendation: "Add sRGB color profile for consistent colors across devices"
                ))
            }
        }
        
        return issues
    }
    
    private func isRecommendedColorProfile(_ profile: String) -> Bool {
        let recommendedProfiles = ["RGB", "sRGB", "Display P3", "SRGB"]
        return recommendedProfiles.contains { profile.contains($0) }
    }
    
    private func getRecommendedColorProfile(for image: ImageAsset) -> String {
        // For most iOS images, sRGB is recommended
        return "sRGB"
    }
    
    private func isOutdatedColorProfile(_ profile: String) -> Bool {
        let outdatedProfiles = ["Adobe RGB", "ProPhoto RGB", "Generic RGB"]
        return outdatedProfiles.contains { profile.contains($0) }
    }
    
    // MARK: - Asset Catalog Organization Validation
    
    func validateAssetCatalogOrganization(_ images: [ImageAsset]) -> [AssetCatalogIssue] {
        var issues: [AssetCatalogIssue] = []
        
        let standaloneImages = images.filter { !$0.path.contains(".xcassets") }
        let assetCatalogImages = images.filter { $0.path.contains(".xcassets") }
        
        // Check standalone images that should be in asset catalogs
        for image in standaloneImages {
            if shouldBeInAssetCatalog(image) {
                issues.append(AssetCatalogIssue(
                    image: image,
                    issueType: .shouldBeInCatalog,
                    recommendation: "Move to Asset Catalog for better iOS optimization and management"
                ))
            }
        }
        
        // Check for missing scale variants in asset catalogs
        let imageGroups = Dictionary(grouping: assetCatalogImages) { $0.name }
        for (_, variants) in imageGroups {
            let availableScales = variants.compactMap { $0.scale }.sorted()
            let missingScales = findMissingScaleVariants(availableScales)
            
            if !missingScales.isEmpty {
                let missing = missingScales.map { "@\($0)x" }
                issues.append(AssetCatalogIssue(
                    image: variants.first!,
                    issueType: .missingScaleVariant(missing: missing),
                    recommendation: "Add missing scale variants: \(missing.joined(separator: ", ")) for optimal iOS display"
                ))
            }
            
            // Check for orphaned scale variants
            if variants.count == 1, let scale = variants.first?.scale, scale > 1 {
                issues.append(AssetCatalogIssue(
                    image: variants.first!,
                    issueType: .orphanedScale(scale: "@\(scale)x"),
                    recommendation: "Add @1x base variant for complete scale set"
                ))
            }
        }
        
        return issues
    }
    
    private func shouldBeInAssetCatalog(_ image: ImageAsset) -> Bool {
        let name = image.name.lowercased()
        let path = image.path.lowercased()
        
        // UI elements and app assets should typically be in asset catalogs
        return name.contains("icon") || name.contains("button") || 
               name.contains("background") || name.contains("ui") ||
               path.contains("assets") || image.name.contains("@")
    }
    
    private func findMissingScaleVariants(_ availableScales: [Int]) -> [Int] {
        let requiredScales = [1, 2, 3] // iOS requirements
        return requiredScales.filter { !availableScales.contains($0) }
    }
    
    // MARK: - Design Quality Validation
    
    func validateDesignQuality(_ images: [ImageAsset]) -> [DesignQualityIssue] {
        var issues: [DesignQualityIssue] = []
        
        for image in images {
            guard let dimensions = image.dimensions else { continue }
            
            // Check for non-integer scaling between variants
            if let scale = image.scale, scale > 1 {
                let expectedBaseWidth = dimensions.width / Double(scale)
                let expectedBaseHeight = dimensions.height / Double(scale)
                
                if expectedBaseWidth != floor(expectedBaseWidth) || expectedBaseHeight != floor(expectedBaseHeight) {
                    issues.append(DesignQualityIssue(
                        image: image,
                        issueType: .nonIntegerScaling,
                        impact: "May cause blurry rendering",
                        recommendation: "Ensure dimensions scale to whole numbers (current: \(Int(dimensions.width))×\(Int(dimensions.height)), expected: \(Int(expectedBaseWidth * Double(scale)))×\(Int(expectedBaseHeight * Double(scale))))"
                    ))
                }
            }
            
            // Check for images too small for high-resolution displays
            if dimensions.width < 44 && dimensions.height < 44 {
                issues.append(DesignQualityIssue(
                    image: image,
                    issueType: .tooSmallForHighRes,
                    impact: "May appear pixelated on high-resolution displays",
                    recommendation: "Increase size to at least 44×44 points for touch targets or 22×22 for small icons"
                ))
            }
            
            // Check for very large dimensions that might cause memory issues
            let pixelCount = dimensions.width * dimensions.height
            if pixelCount > 2_000_000 { // > 2 megapixels
                issues.append(DesignQualityIssue(
                    image: image,
                    issueType: .inefficientDimensions,
                    impact: "High memory usage (\(String(format: "%.1f", pixelCount / 1_000_000))MP)",
                    recommendation: "Consider reducing dimensions or using progressive loading for large images"
                ))
            }
        }
        
        return issues
    }
    
    // MARK: - Compliance Scoring
    
    private func countCriticalIssues(
        pngIssues: [PNGInterlacingIssue],
        colorIssues: [ColorProfileIssue],
        assetIssues: [AssetCatalogIssue],
        designIssues: [DesignQualityIssue]
    ) -> Int {
        var criticalCount = 0
        
        // Critical PNG issues (high performance impact)
        criticalCount += pngIssues.filter { $0.performanceImpact == "Critical" }.count
        
        // Critical color profile issues (missing profiles)
        criticalCount += colorIssues.filter { 
            if case .missing = $0.issueType { return true }
            return false
        }.count
        
        // Critical asset catalog issues (missing scale variants)
        criticalCount += assetIssues.filter {
            if case .missingScaleVariant = $0.issueType { return true }
            return false
        }.count
        
        // Critical design issues (too small or memory intensive)
        criticalCount += designIssues.filter { 
            $0.issueType == .tooSmallForHighRes || $0.issueType == .inefficientDimensions 
        }.count
        
        return criticalCount
    }
    
    private func calculateComplianceScore(totalImages: Int, totalIssues: Int, criticalIssues: Int) -> Int {
        guard totalImages > 0 else { return 100 }
        
        // Base score starts at 100
        var score = 100
        
        // Deduct points for issues
        let issueRate = Double(totalIssues) / Double(totalImages)
        let criticalRate = Double(criticalIssues) / Double(totalImages)
        
        // Heavy penalty for critical issues, lighter for warnings
        score -= Int(criticalRate * 60) // Up to 60 points for critical issues
        score -= Int((issueRate - criticalRate) * 30) // Up to 30 points for other issues
        
        return max(0, score) // Ensure score doesn't go below 0
    }
}
//test_CI
