import Foundation

enum Role: String, Codable {
    case user
    case model
}

struct Message: Identifiable, Codable, Equatable {
    var id = UUID()
    var text: String
    var role: Role
    var timestamp: Date = Date()
    
    // For Equatable to work properly
    static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id && lhs.text == rhs.text && lhs.role == rhs.role
    }
}
