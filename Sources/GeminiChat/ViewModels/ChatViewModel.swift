import Foundation
import SwiftUI
import GoogleGenerativeAI

@MainActor
class ChatViewModel: ObservableObject {
    @Published var apiKey: String = "" {
        didSet {
            hasAPIKey = !apiKey.isEmpty
        }
    }
    @Published var hasAPIKey: Bool = false
    @Published var shouldSaveAPIKey: Bool = true
    
    @Published var availableModels: [GeminiModel] = []
    @Published var selectedModelId: String = ""
    @Published var isFetchingModels = false
    @Published var errorMessage: String? = nil
    
    @Published var conversations: [Conversation] = []
    @Published var folders: [Folder] = []
    @Published var selectedConversationId: UUID?
    
    @Published var isSendingMessage: Bool = false
    
    struct GeminiModel: Identifiable, Decodable, Hashable {
        let name: String
        let version: String?
        let displayName: String?
        let description: String?

        var id: String { name }
    }    
    struct ModelListResponse: Decodable {
        let models: [GeminiModel]
    }
    
    init() {
        if let savedKey = UserDefaults.standard.string(forKey: "GEMINI_API_KEY") {
            self.apiKey = savedKey
            self.hasAPIKey = true
        }
        
        // Add a default conversation
        if conversations.isEmpty {
            createNewConversation()
        }
    }
    
    var currentConversation: Conversation? {
        guard let id = selectedConversationId else { return nil }
        return conversations.first(where: { $0.id == id })
    }
    
    func saveAPIKey() {
        if shouldSaveAPIKey {
            UserDefaults.standard.set(apiKey, forKey: "GEMINI_API_KEY")
        }
        hasAPIKey = true
        Task {
            await fetchModels()
        }
    }
    
    func fetchModels() async {
        guard !apiKey.isEmpty else { return }
        
        isFetchingModels = true
        errorMessage = nil
        
        let urlString = "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            isFetchingModels = false
            return
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                if let errorJson = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let error = errorJson["error"] as? [String: Any],
                   let message = error["message"] as? String {
                    errorMessage = message
                } else {
                    errorMessage = "Failed to fetch models: HTTP \(httpResponse.statusCode)"
                }
                isFetchingModels = false
                return
            }

            let decoder = JSONDecoder()
            let listResponse = try decoder.decode(ModelListResponse.self, from: data)

            self.availableModels = listResponse.models.filter { $0.name.starts(with: "models/gemini") }

            if selectedModelId.isEmpty, let first = availableModels.first {
                selectedModelId = first.name
            }

        } catch {
            errorMessage = "Failed to fetch models: \(error.localizedDescription)"
            // Fallback models
            self.availableModels = [
                GeminiModel(name: "models/gemini-2.5-flash", version: "2.5", displayName: "Gemini 2.5 Flash", description: "Fast and capable model."),
                GeminiModel(name: "models/gemini-2.5-pro", version: "2.5", displayName: "Gemini 2.5 Pro", description: "Complex reasoning tasks."),
                GeminiModel(name: "models/gemini-1.5-pro", version: "1.5", displayName: "Gemini 1.5 Pro", description: "Complex reasoning tasks.")
            ]
            self.selectedModelId = "models/gemini-2.5-flash"
        }
        
        isFetchingModels = false
    }
    
    func createNewConversation() {
        let newConv = Conversation(title: "New Chat", modelId: selectedModelId.isEmpty ? "models/gemini-2.5-flash" : selectedModelId)
        conversations.insert(newConv, at: 0)
        selectedConversationId = newConv.id
    }
    
    func createFolder(name: String) {
        let newFolder = Folder(name: name)
        folders.append(newFolder)
    }
    
    func renameFolder(id: UUID, newName: String) {
        if let index = folders.firstIndex(where: { $0.id == id }) {
            folders[index].name = newName
        }
    }
    
    func deleteFolder(id: UUID, deleteChats: Bool = false) {
        if deleteChats {
            conversations.removeAll(where: { $0.folderId == id })
        } else {
            for i in 0..<conversations.count {
                if conversations[i].folderId == id {
                    conversations[i].folderId = nil
                }
            }
        }
        folders.removeAll(where: { $0.id == id })
    }
    
    func moveConversation(_ convId: UUID, toFolderId folderId: UUID?) {
        if let index = conversations.firstIndex(where: { $0.id == convId }) {
            conversations[index].folderId = folderId
        }
    }
    
    func renameConversation(_ id: UUID, to newTitle: String) {
        if let index = conversations.firstIndex(where: { $0.id == id }) {
            conversations[index].title = newTitle
        }
    }
    
    func sendMessage(_ text: String) {
        guard !text.isEmpty, let conversationId = selectedConversationId,
              let index = conversations.firstIndex(where: { $0.id == conversationId }) else { return }
        
        let userMessage = Message(text: text, role: .user)
        conversations[index].messages.append(userMessage)
        
        if conversations[index].messages.count == 1 {
            conversations[index].title = String(text.prefix(30)) + (text.count > 30 ? "..." : "")
        }
        
        let conversation = conversations[index]
        Task {
            await generateResponse(for: userMessage, in: conversation)
        }
    }
    
    private func generateResponse(for message: Message, in conversation: Conversation) async {
        isSendingMessage = true
        
        let cleanModelId = conversation.modelId.replacingOccurrences(of: "models/", with: "")
        let generativeModel = GenerativeModel(name: cleanModelId, apiKey: apiKey)
        
        var history: [ModelContent] = []
        let previousMessages = conversation.messages.dropLast()
        for msg in previousMessages {
            let role = msg.role == .user ? "user" : "model"
            history.append(ModelContent(role: role, parts: msg.text))
        }
        
        let chat = generativeModel.startChat(history: history)
        
        // Create an empty model message placeholder
        let modelMessageId = UUID()
        let initialModelMessage = Message(id: modelMessageId, text: "", role: .model)
        
        if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }) {
            self.conversations[index].messages.append(initialModelMessage)
        }
        
        do {
            let stream = chat.sendMessageStream(message.text)
            var fullResponse = ""
            
            for try await chunk in stream {
                if let text = chunk.text {
                    fullResponse += text
                    if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }),
                       let msgIndex = self.conversations[index].messages.firstIndex(where: { $0.id == modelMessageId }) {
                        self.conversations[index].messages[msgIndex].text = fullResponse
                    }
                }
            }
        } catch {
            let errorText = "Error: \(error.localizedDescription)"
            if let index = self.conversations.firstIndex(where: { $0.id == conversation.id }),
               let msgIndex = self.conversations[index].messages.firstIndex(where: { $0.id == modelMessageId }) {
                self.conversations[index].messages[msgIndex].text = errorText
            }
        }
        
        isSendingMessage = false
    }
}
