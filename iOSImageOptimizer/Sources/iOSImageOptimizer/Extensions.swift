import Foundation

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}