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