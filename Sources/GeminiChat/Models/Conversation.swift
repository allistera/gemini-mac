import Foundation
import GoogleGenerativeAI

struct Conversation: Identifiable, Codable, Equatable {
    var id = UUID()
    var title: String
    var messages: [Message] = []
    var dateCreated: Date = Date()
    var modelId: String = "gemini-1.5-pro"
    var folderId: UUID? = nil
    
    // Equatable
    static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        lhs.id == rhs.id
    }
}
