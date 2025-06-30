// Mock Foundation import for pattern testing
import Foundation

struct ImageConstants {
    static let logo = "company_logo"
    static let background = "main_background"
    
    // Computed properties
    static var currentThemeLogo: String {
        return "logo_\(currentTheme)"
    }
    
    static let currentTheme = "blue"
    
    // Array constants
    static let onboardingImages = [
        "onboarding_1",
        "onboarding_2", 
        "onboarding_3"
    ]
    
    // Dictionary constants
    static let buttonImages: [String: String] = [
        "primary": "button_primary",
        "secondary": "button_secondary",
        "disabled": "button_disabled"
    ]
}

enum ThemeImages: String, CaseIterable {
    case light = "theme_light"
    case dark = "theme_dark" 
    case auto = "theme_auto"
}

class ImageLoader {
    func loadImage(named name: String) -> MockUIImage? {
        return MockUIImage(named: name)
    }
    
    func loadImages() {
        // Runtime image loading
        for i in 1...5 {
            let imageName = "step_\(i)"
            let image = MockUIImage(named: imageName)
        }
        
        // Conditional loading
        let isLargeScreen = true
        let suffix = isLargeScreen ? "_large" : "_small"
        let adaptiveImage = MockUIImage(named: "adaptive_image\(suffix)")
    }
}

// Mock types for compilation
struct MockUIImage {
    init(named: String?) {}
}