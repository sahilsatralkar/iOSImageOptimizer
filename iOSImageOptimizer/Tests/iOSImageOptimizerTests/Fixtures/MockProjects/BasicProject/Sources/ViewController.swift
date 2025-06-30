// Mock UIKit imports for pattern matching tests
// import UIKit

class ViewController {
    
    // @IBOutlet weak var logoImageView: UIImageView!
    // @IBOutlet weak var backgroundImageView: UIImageView!
    var logoImageView: MockUIImageView!
    var backgroundImageView: MockUIImageView!
    
    func viewDidLoad() {
        // super.viewDidLoad()
        
        // Direct image references (mock code for pattern testing)
        logoImageView.image = MockUIImage(named: "logo")
        backgroundImageView.image = MockUIImage(named: "background@2x")
        
        // String literal references
        let iconName = "icon"
        let buttonImage = MockUIImage(named: iconName)
        
        // Array of image names
        let imageNames = ["image1", "image2", "image3"]
        for name in imageNames {
            let image = MockUIImage(named: name)
        }
        
        // String interpolation
        let theme = "dark"
        let interpolatedImage = MockUIImage(named: "button_\(theme)")
        
        // SwiftUI Image references
        let swiftUIImage = MockImage("swiftui_image")
        
        // System images
        let systemImage = MockUIImage(systemName: "star")
        
        // Asset catalog references
        let assetImage = MockUIImage(named: "AppIcon")
    }
    
    func loadThemeImages() {
        let themes = ["light", "dark"]
        for theme in themes {
            let backgroundImage = MockUIImage(named: "background_\(theme)")
            let buttonImage = MockUIImage(named: "button_\(theme)_normal")
        }
    }
}

// Mock types for compilation
struct MockUIImage {
    init(named: String?) {}
    init(systemName: String) {}
}

struct MockImage {
    init(_ name: String) {}
}

struct MockUIImageView {
    var image: MockUIImage?
}