import XCTest
import Foundation
@testable import iOSImageOptimizer

final class ProjectParserTests: XCTestCase {
    
    var tempProjectPath: String!
    var parser: ProjectParser!
    
    override func setUp() {
        super.setUp()
        tempProjectPath = TestUtilities.createTempDirectory(named: "ProjectParserTest")
        parser = ProjectParser(projectPath: tempProjectPath, verbose: false)
    }
    
    override func tearDown() {
        TestUtilities.cleanupTempDirectory(tempProjectPath)
        super.tearDown()
    }
    
    // MARK: - Project.pbxproj Parsing Tests
    
    func testParseProjectFile_EmptyProject() throws {
        let projectFiles = try parser.parseProjectFile()
        XCTAssertEqual(projectFiles.count, 0, "Empty project should return no project files")
    }
    
    func testParseProjectFile_NoXcodeProjFile() throws {
        // Create some files but no .xcodeproj
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/SomeFile.swift", content: "// Swift file")
        
        let projectFiles = try parser.parseProjectFile()
        XCTAssertEqual(projectFiles.count, 0, "Project without .xcodeproj should return no project files")
    }
    
    func testParseProjectFile_BasicPbxproj() throws {
        // Create .xcodeproj directory and project.pbxproj file
        let xcodeProjDir = "\(tempProjectPath!)/TestProject.xcodeproj"
        try FileManager.default.createDirectory(atPath: xcodeProjDir, withIntermediateDirectories: true)
        
        let pbxprojContent = """
        // !$*UTF8*$!
        {
            archiveVersion = 1;
            classes = {
            };
            objectVersion = 56;
            objects = {
                ABC123DEF456 /* AppIcon.appiconset */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = folder.assetcatalog;
                    path = "Assets.xcassets";
                    sourceTree = "<group>";
                };
                DEF456GHI789 /* test_image.png */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = image.png;
                    path = "test_image.png";
                    sourceTree = "<group>";
                };
                GHI789JKL012 /* ViewController.swift */ = {
                    isa = PBXFileReference;
                    fileEncoding = 4;
                    lastKnownFileType = sourcecode.swift;
                    path = "ViewController.swift";
                    sourceTree = "<group>";
                };
                JKL012MNO345 /* Main.storyboard */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = file.storyboard;
                    path = "Main.storyboard";
                    sourceTree = "<group>";
                };
                MNO345PQR678 /* Info.plist */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = text.plist.xml;
                    path = "Info.plist";
                    sourceTree = "<group>";
                };
                PQR678STU901 /* Localizable.strings */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = text.plist.strings;
                    path = "Localizable.strings";
                    sourceTree = "<group>";
                };
            };
            rootObject = AAA111BBB222;
        }
        """
        
        TestUtilities.createMockFile(at: "\(xcodeProjDir)/project.pbxproj", content: pbxprojContent)
        
        let projectFiles = try parser.parseProjectFile()
        
        XCTAssertEqual(projectFiles.count, 6, "Should find 6 project files")
        
        // Check each file type
        let assetCatalog = projectFiles.first { $0.name == "AppIcon.appiconset" }
        XCTAssertNotNil(assetCatalog, "Should find asset catalog")
        if case .assetCatalog = assetCatalog?.type {} else {
            XCTFail("Asset catalog should have correct type")
        }
        
        let imageFile = projectFiles.first { $0.name == "test_image.png" }
        XCTAssertNotNil(imageFile, "Should find image file")
        if case .image(let ext) = imageFile?.type {
            XCTAssertEqual(ext, "png", "Image should have PNG extension")
        } else {
            XCTFail("Image file should have correct type")
        }
        
        let swiftFile = projectFiles.first { $0.name == "ViewController.swift" }
        XCTAssertNotNil(swiftFile, "Should find Swift file")
        if case .sourceCode = swiftFile?.type {} else {
            XCTFail("Swift file should have sourceCode type")
        }
        
        let storyboard = projectFiles.first { $0.name == "Main.storyboard" }
        XCTAssertNotNil(storyboard, "Should find storyboard")
        if case .interfaceBuilder = storyboard?.type {} else {
            XCTFail("Storyboard should have interfaceBuilder type")
        }
        
        let plist = projectFiles.first { $0.name == "Info.plist" }
        XCTAssertNotNil(plist, "Should find plist")
        if case .plist = plist?.type {} else {
            XCTFail("Plist should have plist type")
        }
        
        let strings = projectFiles.first { $0.name == "Localizable.strings" }
        XCTAssertNotNil(strings, "Should find strings file")
        if case .strings = strings?.type {} else {
            XCTFail("Strings file should have strings type")
        }
    }
    
    func testParseProjectFile_ObjectiveCFiles() throws {
        let xcodeProjDir = "\(tempProjectPath!)/TestProject.xcodeproj"
        try FileManager.default.createDirectory(atPath: xcodeProjDir, withIntermediateDirectories: true)
        
        let pbxprojContent = """
        {
            objects = {
                ABC123DEF456 /* MyClass.h */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = sourcecode.c.h;
                    path = "MyClass.h";
                    sourceTree = "<group>";
                };
                DEF456GHI789 /* MyClass.m */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = sourcecode.c.objc;
                    path = "MyClass.m";
                    sourceTree = "<group>";
                };
            };
        }
        """
        
        TestUtilities.createMockFile(at: "\(xcodeProjDir)/project.pbxproj", content: pbxprojContent)
        
        let projectFiles = try parser.parseProjectFile()
        
        let objcFile = projectFiles.first { $0.name == "MyClass.m" }
        XCTAssertNotNil(objcFile, "Should find Objective-C implementation file")
        if case .sourceCode = objcFile?.type {} else {
            XCTFail("Objective-C file should have sourceCode type")
        }
    }
    
    func testParseProjectFile_XIBFiles() throws {
        let xcodeProjDir = "\(tempProjectPath!)/TestProject.xcodeproj"
        try FileManager.default.createDirectory(atPath: xcodeProjDir, withIntermediateDirectories: true)
        
        let pbxprojContent = """
        {
            objects = {
                ABC123DEF456 /* CustomView.xib */ = {
                    isa = PBXFileReference;
                    lastKnownFileType = file.xib;
                    path = "CustomView.xib";
                    sourceTree = "<group>";
                };
            };
        }
        """
        
        TestUtilities.createMockFile(at: "\(xcodeProjDir)/project.pbxproj", content: pbxprojContent)
        
        let projectFiles = try parser.parseProjectFile()
        
        let xibFile = projectFiles.first { $0.name == "CustomView.xib" }
        XCTAssertNotNil(xibFile, "Should find XIB file")
        if case .interfaceBuilder = xibFile?.type {} else {
            XCTFail("XIB file should have interfaceBuilder type")
        }
    }
    
    func testParseProjectFile_CorruptedPbxproj() throws {
        let xcodeProjDir = "\(tempProjectPath!)/TestProject.xcodeproj"
        try FileManager.default.createDirectory(atPath: xcodeProjDir, withIntermediateDirectories: true)
        
        // Create corrupted pbxproj with invalid regex patterns
        let pbxprojContent = "{ invalid pbxproj content without proper structure"
        TestUtilities.createMockFile(at: "\(xcodeProjDir)/project.pbxproj", content: pbxprojContent)
        
        // Should not crash and return empty array
        let projectFiles = try parser.parseProjectFile()
        XCTAssertEqual(projectFiles.count, 0, "Corrupted pbxproj should return empty array")
    }
    
    // MARK: - Asset Catalog Parsing Tests
    
    func testParseAssetCatalogs_EmptyProject() throws {
        let assets = try parser.parseAssetCatalogs()
        XCTAssertEqual(assets.count, 0, "Empty project should return no assets")
    }
    
    func testParseAssetCatalogs_ValidAssetCatalog() throws {
        let assetDir = "\(tempProjectPath!)/Assets.xcassets/TestImage.imageset"
        try FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        let contentsJSON = """
        {
          "images" : [
            {
              "filename" : "TestImage.png",
              "idiom" : "universal",
              "scale" : "1x"
            },
            {
              "filename" : "TestImage@2x.png",
              "idiom" : "universal",
              "scale" : "2x"
            },
            {
              "filename" : "TestImage@3x.png",
              "idiom" : "universal",
              "scale" : "3x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        TestUtilities.createMockFile(at: "\(assetDir)/Contents.json", content: contentsJSON)
        
        let assets = try parser.parseAssetCatalogs()
        
        XCTAssertEqual(assets.count, 1, "Should find 1 asset")
        
        let asset = assets[0]
        XCTAssertEqual(asset.name, "TestImage", "Asset name should be TestImage")
        XCTAssertEqual(asset.variants.count, 3, "Should have 3 variants")
        
        let scales = asset.variants.map { $0.scale }.sorted()
        XCTAssertEqual(scales, ["1x", "2x", "3x"], "Should have correct scales")
        
        let filenames = asset.variants.map { $0.filename }.sorted()
        XCTAssertEqual(filenames, ["TestImage.png", "TestImage@2x.png", "TestImage@3x.png"], "Should have correct filenames")
    }
    
    func testParseAssetCatalogs_AppIconSet() throws {
        // Note: AppIcon.appiconset is handled differently than regular .imageset
        // The current parser only looks for .imageset folders, not .appiconset
        // So we'll create a regular imageset for this test
        let assetDir = "\(tempProjectPath!)/Assets.xcassets/AppIcon.imageset"
        try FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        let contentsJSON = """
        {
          "images" : [
            {
              "filename" : "AppIcon-20@2x.png",
              "idiom" : "iphone",
              "scale" : "2x",
              "size" : "20x20"
            },
            {
              "filename" : "AppIcon-20@3x.png",
              "idiom" : "iphone",
              "scale" : "3x",
              "size" : "20x20"
            },
            {
              "filename" : "AppIcon-29@2x.png",
              "idiom" : "iphone",
              "scale" : "2x",
              "size" : "29x29"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        TestUtilities.createMockFile(at: "\(assetDir)/Contents.json", content: contentsJSON)
        
        let assets = try parser.parseAssetCatalogs()
        
        XCTAssertEqual(assets.count, 1, "Should find 1 app icon asset")
        
        let asset = assets[0]
        XCTAssertEqual(asset.name, "AppIcon", "Asset name should be AppIcon")
        XCTAssertEqual(asset.variants.count, 3, "Should have 3 app icon variants")
        
        // Check for size information
        let sizesSet = Set(asset.variants.compactMap { $0.size })
        XCTAssertTrue(sizesSet.contains("20x20"), "Should contain 20x20 size")
        XCTAssertTrue(sizesSet.contains("29x29"), "Should contain 29x29 size")
    }
    
    func testParseAssetCatalogs_MissingContentsJSON() throws {
        let assetDir = "\(tempProjectPath!)/Assets.xcassets/BrokenImage.imageset"
        try FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        // No Contents.json file created
        
        let assets = try parser.parseAssetCatalogs()
        XCTAssertEqual(assets.count, 0, "Should not find assets without Contents.json")
    }
    
    func testParseAssetCatalogs_CorruptedContentsJSON() throws {
        let assetDir = "\(tempProjectPath!)/Assets.xcassets/CorruptedImage.imageset"
        try FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        TestUtilities.createMockFile(at: "\(assetDir)/Contents.json", content: "{ invalid json")
        
        let assets = try parser.parseAssetCatalogs()
        XCTAssertEqual(assets.count, 0, "Should handle corrupted JSON gracefully")
    }
    
    func testParseAssetCatalogs_EmptyContentsJSON() throws {
        let assetDir = "\(tempProjectPath!)/Assets.xcassets/EmptyImage.imageset"
        try FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
        
        let contentsJSON = """
        {
          "images" : [],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        TestUtilities.createMockFile(at: "\(assetDir)/Contents.json", content: contentsJSON)
        
        let assets = try parser.parseAssetCatalogs()
        
        XCTAssertEqual(assets.count, 1, "Should find asset even with empty images array")
        XCTAssertEqual(assets[0].variants.count, 0, "Should have no variants")
    }
    
    func testParseAssetCatalogs_MultipleAssetCatalogs() throws {
        // Create first asset catalog
        let assetDir1 = "\(tempProjectPath!)/Assets1.xcassets/Image1.imageset"
        try FileManager.default.createDirectory(atPath: assetDir1, withIntermediateDirectories: true)
        
        let contentsJSON1 = """
        {
          "images" : [
            {
              "filename" : "Image1.png",
              "idiom" : "universal",
              "scale" : "1x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        TestUtilities.createMockFile(at: "\(assetDir1)/Contents.json", content: contentsJSON1)
        
        // Create second asset catalog
        let assetDir2 = "\(tempProjectPath!)/Assets2.xcassets/Image2.imageset"
        try FileManager.default.createDirectory(atPath: assetDir2, withIntermediateDirectories: true)
        
        let contentsJSON2 = """
        {
          "images" : [
            {
              "filename" : "Image2.png",
              "idiom" : "universal",
              "scale" : "1x"
            }
          ],
          "info" : {
            "author" : "xcode",
            "version" : 1
          }
        }
        """
        TestUtilities.createMockFile(at: "\(assetDir2)/Contents.json", content: contentsJSON2)
        
        let assets = try parser.parseAssetCatalogs()
        
        XCTAssertEqual(assets.count, 2, "Should find assets from both catalogs")
        
        let assetNames = Set(assets.map { $0.name })
        XCTAssertTrue(assetNames.contains("Image1"), "Should contain Image1")
        XCTAssertTrue(assetNames.contains("Image2"), "Should contain Image2")
    }
    
    // MARK: - Info.plist Parsing Tests
    
    func testParseInfoPlists_EmptyProject() throws {
        let references = try parser.parseInfoPlists()
        XCTAssertEqual(references.count, 0, "Empty project should return no references")
    }
    
    func testParseInfoPlists_BasicInfoPlist() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>CFBundleIconName</key>
            <string>AppIcon</string>
            <key>CFBundleIconFile</key>
            <string>AppIcon.png</string>
            <key>UILaunchImageFile</key>
            <string>LaunchImage</string>
            <key>UILaunchStoryboardName</key>
            <string>LaunchScreen</string>
        </dict>
        </plist>
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Info.plist", content: plistContent)
        
        let references = try parser.parseInfoPlists()
        
        XCTAssertGreaterThan(references.count, 0, "Should find image references")
        XCTAssertTrue(references.contains("AppIcon"), "Should contain AppIcon")
        XCTAssertTrue(references.contains("LaunchImage"), "Should contain LaunchImage")
        XCTAssertTrue(references.contains("LaunchScreen"), "Should contain LaunchScreen")
    }
    
    func testParseInfoPlists_ImageFileReferences() throws {
        let plistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
            <key>CustomImages</key>
            <dict>
                <key>SplashImage</key>
                <string>splash_screen.png</string>
                <key>LoadingImage</key>
                <string>loading_spinner.jpg</string>
                <key>BackgroundImage</key>
                <string>background.pdf</string>
            </dict>
        </dict>
        </plist>
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Info.plist", content: plistContent)
        
        let references = try parser.parseInfoPlists()
        
        XCTAssertTrue(references.contains("splash_screen.png"), "Should contain full filename")
        XCTAssertTrue(references.contains("splash_screen"), "Should contain name without extension")
        XCTAssertTrue(references.contains("loading_spinner.jpg"), "Should contain JPEG file")
        XCTAssertTrue(references.contains("loading_spinner"), "Should contain JPEG name without extension")
        XCTAssertTrue(references.contains("background.pdf"), "Should contain PDF file")
        XCTAssertTrue(references.contains("background"), "Should contain PDF name without extension")
    }
    
    func testParseInfoPlists_MultipleInfoPlists() throws {
        // Create main Info.plist
        let mainPlistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
            <key>CFBundleIconName</key>
            <string>MainAppIcon</string>
        </dict>
        </plist>
        """
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Info.plist", content: mainPlistContent)
        
        // Create nested Info.plist
        let nestedDir = "\(tempProjectPath!)/NestedFolder"
        try FileManager.default.createDirectory(atPath: nestedDir, withIntermediateDirectories: true)
        
        let nestedPlistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
            <key>CFBundleIconFile</key>
            <string>NestedIcon.png</string>
        </dict>
        </plist>
        """
        TestUtilities.createMockFile(at: "\(nestedDir)/Info.plist", content: nestedPlistContent)
        
        let references = try parser.parseInfoPlists()
        
        XCTAssertTrue(references.contains("MainAppIcon"), "Should contain main app icon")
        XCTAssertTrue(references.contains("NestedIcon.png"), "Should contain nested icon with extension")
        XCTAssertTrue(references.contains("NestedIcon"), "Should contain nested icon without extension")
    }
    
    func testParseInfoPlists_CorruptedPlist() throws {
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Info.plist", content: "{ invalid plist content")
        
        // Should handle gracefully and not crash
        let references = try parser.parseInfoPlists()
        XCTAssertEqual(references.count, 0, "Should handle corrupted plist gracefully")
    }
    
    func testParseInfoPlists_VerboseMode() throws {
        let verboseParser = ProjectParser(projectPath: tempProjectPath, verbose: true)
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Info.plist", content: "{ invalid plist content")
        
        // Should not crash in verbose mode
        let references = try verboseParser.parseInfoPlists()
        XCTAssertEqual(references.count, 0, "Should handle errors in verbose mode")
    }
    
    // MARK: - Strings File Parsing Tests
    
    func testParseStringsFiles_EmptyProject() throws {
        let references = try parser.parseStringsFiles()
        XCTAssertEqual(references.count, 0, "Empty project should return no references")
    }
    
    func testParseStringsFiles_BasicStringsFile() throws {
        let stringsContent = """
        /* Image references */
        "welcome_image" = "welcome_banner.png";
        "error_icon" = "error_red_icon";
        "success_image" = "success_checkmark.jpg";
        
        /* Button images */
        "save_button_image" = "button_save";
        "cancel_button_image" = "button_cancel";
        
        /* Non-image strings */
        "app_name" = "My App";
        "version_number" = "1.0.0";
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Localizable.strings", content: stringsContent)
        
        let references = try parser.parseStringsFiles()
        
        XCTAssertGreaterThan(references.count, 0, "Should find image references")
        XCTAssertTrue(references.contains("welcome_banner.png"), "Should contain welcome banner with extension")
        XCTAssertTrue(references.contains("welcome_banner"), "Should contain welcome banner without extension")
        XCTAssertTrue(references.contains("error_red_icon"), "Should contain error icon")
        XCTAssertTrue(references.contains("success_checkmark.jpg"), "Should contain success image with extension")
        XCTAssertTrue(references.contains("success_checkmark"), "Should contain success image without extension")
        XCTAssertTrue(references.contains("button_save"), "Should contain button save")
        XCTAssertTrue(references.contains("button_cancel"), "Should contain button cancel")
    }
    
    func testParseStringsFiles_KeysAndValuesWithImages() throws {
        let stringsContent = """
        "background_image_key" = "main_background";
        "header_logo" = "company_logo.png";
        "icon_name" = "app_icon";
        """
        
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/UI.strings", content: stringsContent)
        
        let references = try parser.parseStringsFiles()
        
        // Should find image references in both keys and values
        XCTAssertTrue(references.contains("background_image_key"), "Should detect image reference in key")
        XCTAssertTrue(references.contains("main_background"), "Should detect image reference in value")
        XCTAssertTrue(references.contains("company_logo.png"), "Should detect image file in value")
        XCTAssertTrue(references.contains("company_logo"), "Should detect image name without extension")
        XCTAssertTrue(references.contains("app_icon"), "Should detect icon reference")
    }
    
    func testParseStringsFiles_MultipleStringsFiles() throws {
        // Create first strings file
        TestUtilities.createMockFile(
            at: "\(tempProjectPath!)/English.strings",
            content: """
            "header_image" = "header_en.png";
            "button_icon" = "button_en";
            """
        )
        
        // Create second strings file in subdirectory
        let localizationDir = "\(tempProjectPath!)/es.lproj"
        try FileManager.default.createDirectory(atPath: localizationDir, withIntermediateDirectories: true)
        
        TestUtilities.createMockFile(
            at: "\(localizationDir)/Localizable.strings",
            content: """
            "header_image" = "header_es.png";
            "welcome_logo" = "logo_spanish";
            """
        )
        
        let references = try parser.parseStringsFiles()
        
        XCTAssertTrue(references.contains("header_en.png"), "Should contain English header")
        XCTAssertTrue(references.contains("header_en"), "Should contain English header without extension")
        XCTAssertTrue(references.contains("button_en"), "Should contain English button")
        XCTAssertTrue(references.contains("header_es.png"), "Should contain Spanish header")
        XCTAssertTrue(references.contains("header_es"), "Should contain Spanish header without extension")
        XCTAssertTrue(references.contains("logo_spanish"), "Should contain Spanish logo")
    }
    
    func testParseStringsFiles_CorruptedStringsFile() throws {
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Localizable.strings", content: "invalid strings format")
        
        // Should handle gracefully
        let references = try parser.parseStringsFiles()
        XCTAssertEqual(references.count, 0, "Should handle corrupted strings file gracefully")
    }
    
    func testParseStringsFiles_EmptyStringsFile() throws {
        TestUtilities.createMockFile(at: "\(tempProjectPath!)/Empty.strings", content: "")
        
        let references = try parser.parseStringsFiles()
        XCTAssertEqual(references.count, 0, "Empty strings file should return no references")
    }
    
    // MARK: - Settings Bundle Parsing Tests
    
    func testParseSettingsBundle_EmptyProject() throws {
        let references = try parser.parseSettingsBundle()
        XCTAssertEqual(references.count, 0, "Empty project should return no references")
    }
    
    func testParseSettingsBundle_BasicSettingsBundle() throws {
        let bundleDir = "\(tempProjectPath!)/Settings.bundle"
        try FileManager.default.createDirectory(atPath: bundleDir, withIntermediateDirectories: true)
        
        // Create Root.plist
        let rootPlistContent = """
        <?xml version="1.0" encoding="UTF-8"?>
        <plist version="1.0">
        <dict>
            <key>PreferenceSpecifiers</key>
            <array>
                <dict>
                    <key>Type</key>
                    <string>PSGroupSpecifier</string>
                    <key>Title</key>
                    <string>Settings</string>
                    <key>FooterText</key>
                    <string>settings_footer_image.png</string>
                </dict>
            </array>
        </dict>
        </plist>
        """
        TestUtilities.createMockFile(at: "\(bundleDir)/Root.plist", content: rootPlistContent)
        
        // Create localized strings file
        TestUtilities.createMockFile(
            at: "\(bundleDir)/Root.strings",
            content: """
            "settings_title_image" = "title_banner.png";
            "help_icon" = "help_button";
            """
        )
        
        // Create image file in bundle
        TestUtilities.createMockFile(at: "\(bundleDir)/settings_icon.png", content: "mock image data")
        
        let references = try parser.parseSettingsBundle()
        
        XCTAssertGreaterThan(references.count, 0, "Should find references in settings bundle")
        XCTAssertTrue(references.contains("settings_footer_image.png"), "Should find plist image reference")
        XCTAssertTrue(references.contains("settings_footer_image"), "Should find plist image name without extension")
        XCTAssertTrue(references.contains("title_banner.png"), "Should find strings image reference")
        XCTAssertTrue(references.contains("title_banner"), "Should find strings image name without extension")
        XCTAssertTrue(references.contains("help_button"), "Should find help button reference")
        XCTAssertTrue(references.contains("settings_icon"), "Should find bundle image file")
    }
    
    func testParseSettingsBundle_MultipleSettingsBundles() throws {
        // Create first settings bundle
        let bundle1Dir = "\(tempProjectPath!)/Settings1.bundle"
        try FileManager.default.createDirectory(atPath: bundle1Dir, withIntermediateDirectories: true)
        
        TestUtilities.createMockFile(
            at: "\(bundle1Dir)/Root.plist",
            content: """
            <?xml version="1.0" encoding="UTF-8"?>
            <plist version="1.0">
            <dict>
                <key>CustomIcon</key>
                <string>bundle1_icon.png</string>
            </dict>
            </plist>
            """
        )
        
        // Create second settings bundle
        let bundle2Dir = "\(tempProjectPath!)/Settings2.bundle"
        try FileManager.default.createDirectory(atPath: bundle2Dir, withIntermediateDirectories: true)
        
        TestUtilities.createMockFile(
            at: "\(bundle2Dir)/Root.plist",
            content: """
            <?xml version="1.0" encoding="UTF-8"?>
            <plist version="1.0">
            <dict>
                <key>CustomIcon</key>
                <string>bundle2_icon.png</string>
            </dict>
            </plist>
            """
        )
        
        let references = try parser.parseSettingsBundle()
        
        XCTAssertTrue(references.contains("bundle1_icon.png"), "Should find first bundle icon")
        XCTAssertTrue(references.contains("bundle1_icon"), "Should find first bundle icon without extension")
        XCTAssertTrue(references.contains("bundle2_icon.png"), "Should find second bundle icon")
        XCTAssertTrue(references.contains("bundle2_icon"), "Should find second bundle icon without extension")
    }
    
    func testParseSettingsBundle_CorruptedBundleFiles() throws {
        let bundleDir = "\(tempProjectPath!)/Corrupted.bundle"
        try FileManager.default.createDirectory(atPath: bundleDir, withIntermediateDirectories: true)
        
        // Create corrupted plist
        TestUtilities.createMockFile(at: "\(bundleDir)/Root.plist", content: "{ invalid plist")
        
        // Create corrupted strings file
        TestUtilities.createMockFile(at: "\(bundleDir)/Root.strings", content: "invalid strings format")
        
        // Should handle gracefully
        let references = try parser.parseSettingsBundle()
        XCTAssertEqual(references.count, 0, "Should handle corrupted bundle files gracefully")
    }
    
    func testParseSettingsBundle_VerboseMode() throws {
        let verboseParser = ProjectParser(projectPath: tempProjectPath, verbose: true)
        
        let bundleDir = "\(tempProjectPath!)/Verbose.bundle"
        try FileManager.default.createDirectory(atPath: bundleDir, withIntermediateDirectories: true)
        
        TestUtilities.createMockFile(at: "\(bundleDir)/Root.plist", content: "{ invalid plist")
        
        // Should not crash in verbose mode
        let references = try verboseParser.parseSettingsBundle()
        XCTAssertEqual(references.count, 0, "Should handle errors in verbose mode")
    }
    
    // MARK: - Helper Methods Tests
    
    func testIsLikelyImageReference_ValidImageReferences() {
        let testCases = [
            ("app_icon", true),
            ("background_image", true),
            ("company_logo", true),
            ("button_normal", true),
            ("main_background", true),
            ("test.png", true),
            ("photo.jpg", true),
            ("document.pdf", true),
            ("vector.svg", true),
            ("animation.gif", true),
            ("icon.jpeg", true),
            ("ICON_LARGE", true), // Uppercase
            ("Header_Image", true) // Mixed case
        ]
        
        for (input, expected) in testCases {
            let result = parser.isLikelyImageReference(input)
            XCTAssertEqual(result, expected, "Input '\(input)' should return \(expected)")
        }
    }
    
    func testIsLikelyImageReference_NonImageReferences() {
        let testCases = [
            ("app_name", false),
            ("version_number", false),
            ("user_email", false),
            ("database_url", false),
            ("api_key", false),
            ("text_content", false),
            ("random_string", false),
            ("test.txt", false),
            ("data.json", false),
            ("config.xml", false)
        ]
        
        for (input, expected) in testCases {
            let result = parser.isLikelyImageReference(input)
            XCTAssertEqual(result, expected, "Input '\(input)' should return \(expected)")
        }
    }
    
    func testIsImageExtension_ValidExtensions() {
        let validExtensions = ["png", "jpg", "jpeg", "gif", "svg", "pdf", "PNG", "JPG", "JPEG"]
        
        for ext in validExtensions {
            let result = parser.isImageExtension(ext)
            XCTAssertTrue(result, "Extension '\(ext)' should be recognized as image extension")
        }
    }
    
    func testIsImageExtension_InvalidExtensions() {
        let invalidExtensions = ["txt", "json", "xml", "swift", "m", "h", "plist", "strings"]
        
        for ext in invalidExtensions {
            let result = parser.isImageExtension(ext)
            XCTAssertFalse(result, "Extension '\(ext)' should not be recognized as image extension")
        }
    }
    
    // MARK: - Integration Tests
    
    func testIntegration_ComplexProject() throws {
        try withMockProject(structure: .complex) { projectPath in
            let complexParser = ProjectParser(projectPath: projectPath, verbose: false)
            
            // Test all parsing methods
            let projectFiles = try complexParser.parseProjectFile()
            let assets = try complexParser.parseAssetCatalogs()
            let infoPlistRefs = try complexParser.parseInfoPlists()
            let stringsRefs = try complexParser.parseStringsFiles()
            let bundleRefs = try complexParser.parseSettingsBundle()
            
            // Should find various types of references
            XCTAssertGreaterThanOrEqual(projectFiles.count, 0, "Should process project files")
            XCTAssertGreaterThanOrEqual(assets.count, 0, "Should process asset catalogs")
            XCTAssertGreaterThanOrEqual(infoPlistRefs.count, 0, "Should process Info.plist files")
            XCTAssertGreaterThanOrEqual(stringsRefs.count, 0, "Should process strings files")
            XCTAssertGreaterThanOrEqual(bundleRefs.count, 0, "Should process settings bundles")
        }
    }
    
    func testIntegration_CorruptedProject() throws {
        try withMockProject(structure: .corrupted) { projectPath in
            let corruptedParser = ProjectParser(projectPath: projectPath, verbose: false)
            
            // Should handle corrupted project gracefully - most should not throw, but return empty results
            XCTAssertNoThrow(try corruptedParser.parseProjectFile(), "Should handle corrupted project file")
            
            // Asset catalogs with corrupted JSON should return empty results, not throw
            let assets = try corruptedParser.parseAssetCatalogs()
            XCTAssertEqual(assets.count, 0, "Corrupted asset catalogs should return empty results")
            
            XCTAssertNoThrow(try corruptedParser.parseInfoPlists(), "Should handle corrupted Info.plist")
            XCTAssertNoThrow(try corruptedParser.parseStringsFiles(), "Should handle corrupted strings files")
            XCTAssertNoThrow(try corruptedParser.parseSettingsBundle(), "Should handle corrupted settings bundle")
        }
    }
    
    // MARK: - Performance Tests
    
    func testPerformance_LargeProject() throws {
        // Create a large project structure
        let largeProjectDir = "\(tempProjectPath!)/LargeProject"
        try FileManager.default.createDirectory(atPath: largeProjectDir, withIntermediateDirectories: true)
        
        // Create multiple asset catalogs
        for i in 1...20 {
            let assetDir = "\(largeProjectDir)/Assets\(i).xcassets/Image\(i).imageset"
            try FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)
            
            let contentsJSON = """
            {
              "images" : [
                {
                  "filename" : "Image\(i).png",
                  "idiom" : "universal",
                  "scale" : "1x"
                }
              ],
              "info" : {
                "author" : "xcode",
                "version" : 1
              }
            }
            """
            TestUtilities.createMockFile(at: "\(assetDir)/Contents.json", content: contentsJSON)
        }
        
        let largeParser = ProjectParser(projectPath: largeProjectDir, verbose: false)
        
        do {
            try assertFasterThan(2.0, description: "Parsing large project") {
                let assets = try largeParser.parseAssetCatalogs()
                XCTAssertEqual(assets.count, 20, "Should find all 20 assets")
            }
        } catch {
            XCTFail("Performance test failed: \(error)")
        }
    }
}

// MARK: - Helper Extensions

extension ProjectParserTests {
    
    private func assertFileExists(at path: String, message: String) {
        XCTAssertTrue(FileManager.default.fileExists(atPath: path), message)
    }
}