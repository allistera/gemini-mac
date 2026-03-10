import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var showingNewFolderAlert = false
    @State private var newFolderName = ""
    
    @State private var showingRenameFolderAlert = false
    @State private var folderToRename: Folder?
    @State private var renameFolderName = ""
    
    @State private var showingRenameConvAlert = false
    @State private var convToRename: Conversation?
    @State private var renameConvTitle = ""
    
    @State private var folderBeingTargeted: UUID? = nil
    @State private var isTargetingUncategorized = false
    
    var body: some View {
        List(selection: $viewModel.selectedConversationId) {
            Section("Folders") {
                ForEach(viewModel.folders) { folder in
                    FolderView(
                        folder: folder,
                        conversations: viewModel.conversations.filter { $0.folderId == folder.id },
                        isTargeted: folderBeingTargeted == folder.id,
                        onRename: {
                            folderToRename = folder
                            renameFolderName = folder.name
                            showingRenameFolderAlert = true
                        },
                        onDelete: { deleteChats in
                            viewModel.deleteFolder(id: folder.id, deleteChats: deleteChats)
                        },
                        onDrop: { providers in
                            handleDrop(providers: providers, toFolderId: folder.id)
                        },
                        onTargetChange: { targeted in
                            folderBeingTargeted = targeted ? folder.id : nil
                        },
                        onRenameChat: { conv in
                            convToRename = conv
                            renameConvTitle = conv.title
                            showingRenameConvAlert = true
                        },
                        onMoveChat: { convId, targetFolderId in
                            viewModel.moveConversation(convId, toFolderId: targetFolderId)
                        },
                        onDeleteChat: { convId in
                            if let index = viewModel.conversations.firstIndex(where: { $0.id == convId }) {
                                viewModel.conversations.remove(at: index)
                            }
                        },
                        availableFolders: viewModel.folders
                    )
                }
            }
            
            Section {
                let uncategorized = viewModel.conversations.filter { $0.folderId == nil }
                ForEach(uncategorized) { conv in
                    ChatRow(
                        conv: conv,
                        onRename: {
                            convToRename = conv
                            renameConvTitle = conv.title
                            showingRenameConvAlert = true
                        },
                        onMove: { targetFolderId in
                            viewModel.moveConversation(conv.id, toFolderId: targetFolderId)
                        },
                        onDelete: {
                            if let index = viewModel.conversations.firstIndex(where: { $0.id == conv.id }) {
                                viewModel.conversations.remove(at: index)
                            }
                        },
                        availableFolders: viewModel.folders
                    )
                }
                .onDelete { indexSet in
                    let convsToDelete = indexSet.map { uncategorized[$0] }
                    for conv in convsToDelete {
                        if let index = viewModel.conversations.firstIndex(where: { $0.id == conv.id }) {
                            viewModel.conversations.remove(at: index)
                        }
                    }
                }
            } header: {
                Text("Uncategorized")
                    .foregroundColor(isTargetingUncategorized ? .blue : .secondary)
                    .onDrop(of: [.text], isTargeted: $isTargetingUncategorized) { providers in
                        handleDrop(providers: providers, toFolderId: nil)
                    }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("GeminiChat")
        .toolbar {
            ToolbarItemGroup {
                Button(action: { showingNewFolderAlert = true }) {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
                Button(action: { viewModel.createNewConversation() }) {
                    Label("New Chat", systemImage: "square.and.pencil")
                }
            }
        }
        .alert("New Folder", isPresented: $showingNewFolderAlert) {
            TextField("Folder Name", text: $newFolderName)
            Button("Create") {
                if !newFolderName.isEmpty {
                    viewModel.createFolder(name: newFolderName)
                    newFolderName = ""
                }
            }
            Button("Cancel", role: .cancel) { newFolderName = "" }
        }
        .alert("Rename Folder", isPresented: $showingRenameFolderAlert) {
            TextField("Folder Name", text: $renameFolderName)
            Button("Rename") {
                if let folder = folderToRename, !renameFolderName.isEmpty {
                    viewModel.renameFolder(id: folder.id, newName: renameFolderName)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .alert("Rename Conversation", isPresented: $showingRenameConvAlert) {
            TextField("Conversation Title", text: $renameConvTitle)
            Button("Rename") {
                if let conv = convToRename, !renameConvTitle.isEmpty {
                    viewModel.renameConversation(conv.id, to: renameConvTitle)
                }
            }
            Button("Cancel", role: .cancel) { }
        }
        .safeAreaInset(edge: .bottom) {
            ModelPickerView()
        }
    }
    
    private func handleDrop(providers: [NSItemProvider], toFolderId: UUID?) -> Bool {
        for provider in providers {
            if provider.canLoadObject(ofClass: NSString.self) {
                provider.loadObject(ofClass: NSString.self) { (uuidString, error) in
                    if let uuidString = uuidString as? String, let uuid = UUID(uuidString: uuidString) {
                        DispatchQueue.main.async {
                            viewModel.moveConversation(uuid, toFolderId: toFolderId)
                        }
                    }
                }
                return true
            }
        }
        return false
    }
}

struct FolderView: View {
    let folder: Folder
    let conversations: [Conversation]
    let isTargeted: Bool
    let onRename: () -> Void
    let onDelete: (Bool) -> Void
    let onDrop: ([NSItemProvider]) -> Bool
    let onTargetChange: (Bool) -> Void
    let onRenameChat: (Conversation) -> Void
    let onMoveChat: (UUID, UUID?) -> Void
    let onDeleteChat: (UUID) -> Void
    let availableFolders: [Folder]
    
    @State private var isInternalTargeted: Bool = false
    
    var body: some View {
        DisclosureGroup {
            ForEach(conversations) { conv in
                ChatRow(
                    conv: conv,
                    onRename: { onRenameChat(conv) },
                    onMove: { targetFolderId in onMoveChat(conv.id, targetFolderId) },
                    onDelete: { onDeleteChat(conv.id) },
                    availableFolders: availableFolders
                )
            }
        } label: {
            Label(folder.name, systemImage: "folder")
                .foregroundColor(isTargeted ? .blue : .primary)
                .onDrop(of: [.text], isTargeted: Binding(get: { isTargeted }, set: { onTargetChange($0) })) { providers in
                    onDrop(providers)
                }
                .contextMenu {
                    Button("Rename") { onRename() }
                    Button("Delete (Keep Chats)") { onDelete(false) }
                    Button("Delete (Delete Chats)", role: .destructive) { onDelete(true) }
                }
        }
    }
}

struct ChatRow: View {
    let conv: Conversation
    let onRename: () -> Void
    let onMove: (UUID?) -> Void
    let onDelete: () -> Void
    let availableFolders: [Folder]
    
    var body: some View {
        NavigationLink(value: conv.id) {
            VStack(alignment: .leading) {
                Text(conv.title)
                    .lineLimit(1)
                Text(conv.dateCreated, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .onDrag {
            NSItemProvider(object: conv.id.uuidString as NSString)
        }
        .contextMenu {
            Button("Rename") { onRename() }
            Menu("Move to Folder") {
                Button("Uncategorized") { onMove(nil) }
                ForEach(availableFolders.filter { $0.id != conv.folderId }) { folder in
                    Button(folder.name) { onMove(folder.id) }
                }
            }
            Divider()
            Button("Delete", role: .destructive) { onDelete() }
        }
    }
}

struct ModelPickerView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if viewModel.isFetchingModels {
                ProgressView("Loading Models...").controlSize(.small)
            } else if let error = viewModel.errorMessage {
                Text(error).font(.caption).foregroundColor(.red)
            } else {
                Picker("Model", selection: $viewModel.selectedModelId) {
                    ForEach(viewModel.availableModels) { model in
                        Text(model.displayName ?? model.name).tag(model.id)
                    }
                }
                .pickerStyle(.menu)
                .labelsHidden()
                
                if let selected = viewModel.availableModels.first(where: { $0.id == viewModel.selectedModelId }),
                   let description = selected.description {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding()
        .background(Color(NSColor.windowBackgroundColor))
        .border(width: 1, edges: [.top], color: Color.gray.opacity(0.2))
    }
}

extension View {
    func border(width: CGFloat, edges: [Edge], color: Color) -> some View {
        overlay(EdgeBorder(width: width, edges: edges).foregroundColor(color))
    }
}

struct EdgeBorder: Shape {
    var width: CGFloat
    var edges: [Edge]

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for edge in edges {
            var x: CGFloat {
                switch edge {
                case .top, .bottom, .leading: return rect.minX
                case .trailing: return rect.maxX - width
                }
            }
            var y: CGFloat {
                switch edge {
                case .top, .leading, .trailing: return rect.minY
                case .bottom: return rect.maxY - width
                }
            }
            var w: CGFloat {
                switch edge {
                case .top, .bottom: return rect.width
                case .leading, .trailing: return width
                }
            }
            var h: CGFloat {
                switch edge {
                case .top, .bottom: return width
                case .leading, .trailing: return rect.height
                }
            }
            path.addRect(CGRect(x: x, y: y, width: w, height: h))
        }
        return path
    }
}
