import Foundation

extension String {
    static func * (left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}

extension ImageAsset: Encodable {
    enum CodingKeys: String, CodingKey {
        case name, path, size, type, scale
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encode(path, forKey: .path)
        try container.encode(size, forKey: .size)
        try container.encode(scale, forKey: .scale)
        
        let typeString: String
        switch type {
        case .png: typeString = "png"
        case .jpeg: typeString = "jpeg"
        case .pdf: typeString = "pdf"
        case .svg: typeString = "svg"
        case .assetCatalog(let scale): typeString = "assetCatalog-\(scale)"
        }
        try container.encode(typeString, forKey: .type)
    }
}