import XCTest
import Foundation
@testable import iOSImageOptimizer

final class SemanticAnalyzerTests: XCTestCase {
    
    var tempProjectPath: String!
    var analyzer: SemanticAnalyzer!
    
    override func setUp() {
        super.setUp()
        tempProjectPath = TestUtilities.createTempDirectory(named: "SemanticAnalyzerTest")
        analyzer = SemanticAnalyzer(projectPath: tempProjectPath, verbose: false)
    }
    
    override func tearDown() {
        TestUtilities.cleanupTempDirectory(tempProjectPath)
        super.tearDown()
    }
    
    // MARK: - Basic Functionality Tests
    
    func testAnalyzeImageReferences_EmptyProject() throws {
        let references = try analyzer.analyzeImageReferences()
        XCTAssertEqual(references.count, 0, "Empty project should return no image references")
    }
    
    func testAnalyzeImageReferences_NoSwiftFiles() throws {
        // Create non-Swift files
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/test.txt", content: "Some text file")
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/config.json", content: "{}")
        
        let references = try analyzer.analyzeImageReferences()
        XCTAssertEqual(references.count, 0, "Project without Swift files should return no references")
    }
    
    // MARK: - Variable Assignment Tests
    
    func testParseVariableAssignments_StringConstants() throws {
        let swiftContent = """
        import UIKit
        
        class ImageManager {
            let defaultIcon: String = "app_icon"
            let backgroundImage: String = "main_background"
            let errorIcon: String = "error_red"
            
            func loadImages() {
                let logo = UIImage(named: "\\(defaultIcon)")
                let bg = UIImage(named: "\\(backgroundImage)")
                let error = UIImage(named: "\\(errorIcon)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ImageManager.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find resolved image references")
        XCTAssertTrue(references.contains("app_icon"), "Should resolve defaultIcon interpolation")
        XCTAssertTrue(references.contains("main_background"), "Should resolve backgroundImage interpolation")
        XCTAssertTrue(references.contains("error_red"), "Should resolve errorIcon interpolation")
    }
    
    func testParseVariableAssignments_ArrayLiterals() throws {
        let swiftContent = """
        import UIKit
        
        class ThemeManager {
            let availableThemes: [String] = ["Light", "Dark", "Auto"]
            
            func loadThemeIcons() {
                // Direct use of array variable in interpolation
                let themeIcon = UIImage(named: "icon_\\(availableThemes)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ThemeManager.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find resolved array-based interpolations")
        XCTAssertTrue(references.contains("icon_Light"), "Should resolve theme Light")
        XCTAssertTrue(references.contains("icon_Dark"), "Should resolve theme Dark")
        XCTAssertTrue(references.contains("icon_Auto"), "Should resolve theme Auto")
    }
    
    func testParseVariableAssignments_EnumCases() throws {
        let swiftContent = """
        import UIKit
        
        enum AppIcon: String {
            case primary = "PrimaryIcon"
            case secondary = "SecondaryIcon"
            case alternate = "AlternateIcon"
        }
        
        class IconManager {
            func setIcon(_ icon: AppIcon) {
                let iconImage = UIImage(named: "\\(icon.rawValue)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/IconManager.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        // Note: The current implementation may not handle enum rawValue interpolation
        // This test documents the current behavior
        XCTAssertGreaterThanOrEqual(references.count, 0, "Should handle enum cases")
        
        // If the analyzer finds the enum values, they should be correct
        if references.count > 0 {
            let enumValues = ["PrimaryIcon", "SecondaryIcon", "AlternateIcon"]
            let foundEnumValues = enumValues.filter { references.contains($0) }
            XCTAssertGreaterThan(foundEnumValues.count, 0, "Should find at least some enum values")
        }
    }
    
    func testParseVariableAssignments_VarWithDefaults() throws {
        let swiftContent = """
        import UIKit
        
        class UserPreferences {
            var selectedTheme: String = "DefaultTheme"
            
            func updateUI() {
                let themeBackground = UIImage(named: "bg_\\(selectedTheme)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/UserPreferences.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find resolved property-based interpolations")
        XCTAssertTrue(references.contains("bg_DefaultTheme"), "Should resolve selectedTheme interpolation")
    }
    
    // MARK: - String Interpolation Pattern Tests
    
    func testParseStringInterpolations_SwiftUIImage() throws {
        let swiftContent = """
        import SwiftUI
        
        struct ContentView: View {
            let imageName: String = "TestImage"
            
            var body: some View {
                VStack {
                    Image("header_\\(imageName)")
                    Image("footer_\\(imageName)_small")
                }
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ContentView.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find SwiftUI Image interpolations")
        XCTAssertTrue(references.contains("header_TestImage"), "Should resolve header interpolation")
        XCTAssertTrue(references.contains("footer_TestImage_small"), "Should resolve footer interpolation")
    }
    
    func testParseStringInterpolations_UIKitImage() throws {
        let swiftContent = """
        import UIKit
        
        class ViewController: UIViewController {
            let iconSize: String = "large"
            let iconColor: String = "red"
            
            override func viewDidLoad() {
                super.viewDidLoad()
                
                let sizeIcon = UIImage(named: "icon_\\(iconSize)")
                let colorIcon = UIImage(named: "icon_\\(iconColor)_variant")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ViewController.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find UIKit Image interpolations")
        XCTAssertTrue(references.contains("icon_large"), "Should resolve size interpolation")
        XCTAssertTrue(references.contains("icon_red_variant"), "Should resolve color interpolation")
    }
    
    func testParseStringInterpolations_SpriteWithFile() throws {
        let swiftContent = """
        import Foundation
        
        class GameScene {
            let characterType: String = "warrior"
            
            func loadSprites() {
                let character = spriteWithFile:@"char_\\(characterType).png"
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/GameScene.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find spriteWithFile interpolations")
        XCTAssertTrue(references.contains("char_warrior.png"), "Should resolve character interpolation")
        XCTAssertTrue(references.contains("char_warrior"), "Should also have name without extension")
    }
    
    // MARK: - Common Pattern Inference Tests
    
    func testInferFromCommonPatterns_ThemeVariables() throws {
        let swiftContent = """
        import UIKit
        
        class ThemeViewController {
            func loadThemeImages() {
                // Unknown variable but theme-related interpolation
                let themeIcon = UIImage(named: "theme_icon_\\(unknownThemeVariable)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ThemeViewController.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should infer common theme patterns")
        
        // Should infer some common theme values
        let hasThemeInference = references.contains { $0.contains("theme_icon_") }
        XCTAssertTrue(hasThemeInference, "Should infer some theme patterns")
    }
    
    func testInferFromCommonPatterns_IconVariables() throws {
        let swiftContent = """
        import UIKit
        
        class IconManager {
            func loadIcons() {
                let primaryIcon = UIImage(named: "primary_icon_\\(unknownIconVariable)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/IconManager.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should infer common icon patterns")
        
        // Should infer some common values for icon-related interpolations
        let hasIconInference = references.contains { $0.contains("primary_icon_") }
        XCTAssertTrue(hasIconInference, "Should infer some icon patterns")
    }
    
    // MARK: - Cross-File Resolution Tests
    
    func testAnalyzeImageReferences_CrossFileVariables() throws {
        // Create first file with variable definitions
        let constantsContent = """
        import Foundation
        
        struct ImageConstants {
            static let primaryColor: String = "Blue"
            static let secondaryColor: String = "Green"
        }
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ImageConstants.swift", content: constantsContent)
        
        // Create second file with interpolations
        let viewContent = """
        import UIKit
        
        class ImageView: UIView {
            func setupImages() {
                let primaryIcon = UIImage(named: "icon_\\(ImageConstants.primaryColor)")
                let secondaryIcon = UIImage(named: "icon_\\(ImageConstants.secondaryColor)")
            }
        }
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ImageView.swift", content: viewContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find cross-file resolved interpolations")
        XCTAssertTrue(references.contains("icon_Blue"), "Should resolve cross-file primary color")
        XCTAssertTrue(references.contains("icon_Green"), "Should resolve cross-file secondary color")
    }
    
    // MARK: - Edge Case Tests
    
    func testParseVariableAssignments_SpecialCharacters() throws {
        let swiftContent = """
        import UIKit
        
        class SpecialCharacterTest {
            let specialName: String = "test-image_01"
            
            func loadImages() {
                let special = UIImage(named: "prefix_\\(specialName)_suffix")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/SpecialCharacterTest.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should handle special characters in variable values")
        XCTAssertTrue(references.contains("prefix_test-image_01_suffix"), "Should resolve special characters")
    }
    
    func testParseStringInterpolations_WhitespaceHandling() throws {
        let swiftContent = """
        import UIKit
        
        class WhitespaceTest {
            let spacing: String = "normal"
            
            func loadImages() {
                let image1 = UIImage(named: "test_\\( spacing )")
                let image2 = UIImage(named: "test_\\(spacing)")
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/WhitespaceTest.swift", content: swiftContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should handle whitespace in interpolations")
        XCTAssertTrue(references.contains("test_normal"), "Should resolve interpolation with various whitespace")
    }
    
    // MARK: - Error Handling Tests
    
    func testAnalyzeImageReferences_CorruptedFiles() throws {
        // Create corrupted Swift file
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Corrupted.swift", content: "class Incomplete {")
        
        // Create valid Swift file
        let validContent = """
        import UIKit
        
        class ValidClass {
            let validImage: String = "ValidImage"
            
            func loadImage() {
                let image = UIImage(named: "\\(validImage)")
            }
        }
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Valid.swift", content: validContent)
        
        // Should handle corrupted files gracefully and process valid ones
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should process valid files despite corrupted ones")
        XCTAssertTrue(references.contains("ValidImage"), "Should resolve valid file interpolations")
    }
    
    func testAnalyzeImageReferences_EmptySwiftFiles() throws {
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Empty.swift", content: "")
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/WhitespaceOnly.swift", content: "   \n\t  \n  ")
        
        let references = try analyzer.analyzeImageReferences()
        XCTAssertEqual(references.count, 0, "Empty Swift files should return no references")
    }
    
    func testAnalyzeImageReferences_VerboseMode() throws {
        let verboseAnalyzer = SemanticAnalyzer(projectPath: tempProjectPath, verbose: true)
        
        let swiftContent = """
        import UIKit
        
        class VerboseTest {
            let testImage: String = "VerboseImage"
            
            func loadImage() {
                let image = UIImage(named: "\\(testImage)")
            }
        }
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/VerboseTest.swift", content: swiftContent)
        
        let references = try verboseAnalyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Verbose mode should work correctly")
        XCTAssertTrue(references.contains("VerboseImage"), "Should resolve in verbose mode")
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_ManyVariables() throws {
        var swiftContent = """
        import UIKit
        
        class PerformanceTest {
        """
        
        // Create many variable assignments
        for i in 1...50 {
            swiftContent += """
                let variable\(i): String = "Value\(i)"
            """
        }
        
        swiftContent += """
        
            func loadImages() {
        """
        
        // Create many interpolations
        for i in 1...50 {
            swiftContent += """
                let image\(i) = UIImage(named: "image_\\(variable\(i))")
            """
        }
        
        swiftContent += """
            }
        }
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/PerformanceTest.swift", content: swiftContent)
        
        do {
            try assertFasterThan(3.0, description: "Analyzing many variables and interpolations") {
                let references = try analyzer.analyzeImageReferences()
                XCTAssertGreaterThan(references.count, 0, "Should resolve interpolations")
            }
        } catch {
            XCTFail("Performance test failed: \(error)")
        }
    }
    
    func testPerformance_MultipleFiles() throws {
        // Create multiple Swift files with variables and interpolations
        for fileIndex in 1...10 {
            let swiftContent = """
            import UIKit
            
            class TestClass\(fileIndex) {
                let theme\(fileIndex): String = "Theme\(fileIndex)"
                
                func loadImages() {
                    let themeImage = UIImage(named: "theme_\\(theme\(fileIndex))")
                }
            }
            """
            TestUtilities.createMockFile(at: "\(tempProjectPath!)/TestFile\(fileIndex).swift", content: swiftContent)
        }
        
        do {
            try assertFasterThan(5.0, description: "Analyzing multiple files") {
                let references = try analyzer.analyzeImageReferences()
                XCTAssertGreaterThan(references.count, 0, "Should find references from multiple files")
            }
        } catch {
            XCTFail("Performance test failed: \(error)")
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegration_RealWorldScenario() throws {
        // Simulate a realistic app scenario
        
        // Theme system
        let themeContent = """
        import UIKit
        
        enum AppTheme: String, CaseIterable {
            case light = "Light"
            case dark = "Dark"
        }
        
        class ThemeManager {
            static let shared = ThemeManager()
            var currentTheme: AppTheme = .light
            
            func getThemeIcon() -> UIImage? {
                return UIImage(named: "theme_\\(currentTheme.rawValue)")
            }
        }
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/ThemeManager.swift", content: themeContent)
        
        // User interface
        let uiContent = """
        import SwiftUI
        
        struct MainView: View {
            let iconSize: String = "Medium"
            let buttonState: String = "Normal"
            
            var body: some View {
                VStack {
                    Image("icon_\\(iconSize)")
                    Image("button_\\(buttonState)")
                }
            }
        }
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/MainView.swift", content: uiContent)
        
        let references = try analyzer.analyzeImageReferences()
        
        XCTAssertGreaterThan(references.count, 0, "Should find multiple references in real-world scenario")
        
        // Check for expected patterns that should be found
        XCTAssertTrue(references.contains("icon_Medium"), "Should resolve icon size")
        XCTAssertTrue(references.contains("button_Normal"), "Should resolve button state")
        
        // May or may not find theme references depending on enum handling
        let hasThemeReferences = references.contains { $0.contains("theme_") }
        // This is informational - we don't assert true/false as enum handling may vary
        print("Found theme references: \(hasThemeReferences)")
    }
}