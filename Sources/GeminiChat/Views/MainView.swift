import SwiftUI

struct MainView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var columnVisibility = NavigationSplitViewVisibility.all
    
    var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibility) {
            SidebarView()
        } detail: {
            if viewModel.selectedConversationId != nil {
                ChatDetailView()
            } else {
                ContentUnavailableView("Select a conversation", systemImage: "bubble.left.and.bubble.right")
            }
        }
        .task {
            await viewModel.fetchModels()
        }
    }
}
