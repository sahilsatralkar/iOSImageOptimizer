import ArgumentParser
import Foundation
import Files
import Rainbow

struct IOSImageOptimizer: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "ios-image-optimizer",
        abstract: "Find unused and oversized images in iOS projects"
    )
    
    @Argument(help: "Path to iOS project directory")
    var projectPath: String
    
    @Flag(name: .shortAndLong, help: "Show detailed output")
    var verbose = false
    
    @Flag(name: .shortAndLong, help: "Export findings to JSON")
    var json = false
    
    mutating func run() throws {
        print("🔍 Analyzing iOS project at: \(projectPath)".cyan)
        
        let analyzer = ProjectAnalyzer(projectPath: projectPath, verbose: verbose)
        let report = try analyzer.analyze()
        
        if json {
            try report.exportJSON()
        } else {
            report.printToConsole()
        }
    }
}

IOSImageOptimizer.main()