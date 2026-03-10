import SwiftUI

struct APIKeyView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @FocusState private var isFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Welcome to GeminiChat")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Please enter your Gemini API Key to continue.")
                .foregroundColor(.secondary)
            
            SecureField("API Key", text: $viewModel.apiKey)
                .focused($isFieldFocused)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .frame(width: 300)
                .onSubmit {
                    if !viewModel.apiKey.isEmpty {
                        viewModel.saveAPIKey()
                    }
                }
            
            Toggle("Save API Key securely", isOn: $viewModel.shouldSaveAPIKey)
                .frame(width: 300, alignment: .leading)
            
            Button("Continue") {
                viewModel.saveAPIKey()
            }
            .disabled(viewModel.apiKey.isEmpty)
            .buttonStyle(.borderedProminent)
            .keyboardShortcut(.defaultAction)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                isFieldFocused = true
            }
        }
    }
}
