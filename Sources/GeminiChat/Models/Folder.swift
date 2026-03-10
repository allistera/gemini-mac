import Foundation

struct Folder: Identifiable, Codable, Equatable {
    var id = UUID()
    var name: String
    
    static func == (lhs: Folder, rhs: Folder) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
}
