import SwiftUI
import Splash
#if os(macOS)
import AppKit
#endif

struct ChatDetailView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var inputText: String = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(alignment: .center) {
                        messageList
                    }
                    .frame(maxWidth: .infinity)
                }
                .onChange(of: viewModel.currentConversation?.messages.last?.text.count) { _, _ in
                    if viewModel.isSendingMessage {
                        scrollToBottom(proxy: proxy)
                    }
                }
                .onChange(of: viewModel.currentConversation?.messages.count) { _, _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            ChatInputBar(
                inputText: $inputText,
                isSendingMessage: viewModel.isSendingMessage,
                isInputFocused: $isInputFocused,
                onSend: sendMessage
            )
        }
        .navigationTitle(viewModel.currentConversation?.title ?? "Chat")
        .onAppear {
            isInputFocused = true
        }
    }
    
    @ViewBuilder
    private var messageList: some View {
        LazyVStack(spacing: 32) {
            if let conv = viewModel.currentConversation {
                if conv.messages.isEmpty {
                    emptyStateView
                } else {
                    ForEach(conv.messages) { message in
                        MessageView(message: message, isLast: message.id == conv.messages.last?.id)
                            .id(message.id)
                    }
                    
                    if viewModel.isSendingMessage {
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 20)
        .padding(.bottom, 20)
        .frame(maxWidth: 800)
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "sparkles")
                .font(.system(size: 40))
                .foregroundColor(.blue)
                .padding(.top, 150)
            Text("How can I help you today?")
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
        }
    }
    
    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !viewModel.isSendingMessage else { return }
        
        viewModel.sendMessage(text)
        inputText = ""
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        if let lastMsg = viewModel.currentConversation?.messages.last {
            proxy.scrollTo(lastMsg.id, anchor: .bottom)
        }
    }
}

struct ChatInputBar: View {
    @Binding var inputText: String
    let isSendingMessage: Bool
    var isInputFocused: FocusState<Bool>.Binding
    let onSend: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Divider()
            VStack(spacing: 8) {
                HStack(alignment: .bottom, spacing: 12) {
                    textFieldContainer
                    sendStopButton
                }
                
                Text("Gemini can make mistakes. Check important info.")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .frame(maxWidth: 800)
        }
        .frame(maxWidth: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    @ViewBuilder
    private var textFieldContainer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message Gemini...", text: $inputText, axis: .vertical)
                .focused(isInputFocused)
                .textFieldStyle(.plain)
                .font(.body)
                .lineLimit(1...12)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .onKeyPress(phases: .down) { press in
                    if press.key == .return {
                        if press.modifiers.contains(.shift) {
                            return .ignored
                        } else {
                            onSend()
                            return .handled
                        }
                    }
                    return .ignored
                }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var sendStopButton: some View {
        if isSendingMessage {
            Button(action: { /* Stop logic */ }) {
                ZStack {
                    Circle()
                        .fill(Color.primary)
                        .frame(width: 34, height: 34)
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .frame(width: 12, height: 12)
                }
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 34))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundColor(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .primary)
            }
            .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            .buttonStyle(.plain)
        }
    }
}

struct MessageView: View {
    let message: Message
    let isLast: Bool
    @EnvironmentObject var viewModel: ChatViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if message.role == .user {
                Spacer(minLength: 80)
                
                MarkdownContentView(text: message.text, isUser: true, isStreaming: false)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(18)
                    .textSelection(.enabled)
            } else {
                GeminiIcon()
                    .padding(.top, 4)
                
                VStack(alignment: .leading, spacing: 8) {
                    MarkdownContentView(text: message.text, isUser: false, isStreaming: isLast && viewModel.isSendingMessage)
                        .textSelection(.enabled)
                }
                
                Spacer(minLength: 50)
            }
        }
    }
}

struct GeminiIcon: View {
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 32, height: 32)
            
            Image(systemName: "sparkles")
                .font(.system(size: 16))
                .foregroundColor(.blue)
        }
    }
}

struct MarkdownContentView: View {
    let text: String
    let isUser: Bool
    let isStreaming: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            let segments = parseMarkdown(text)
            ForEach(0..<segments.count, id: \.self) { index in
                let segment = segments[index]
                if segment.isCode {
                    CodeBlockView(content: segment.content, language: segment.language)
                } else {
                    let paragraphs = segment.content.components(separatedBy: "\n\n")
                    ForEach(0..<paragraphs.count, id: \.self) { pIndex in
                        let pText = paragraphs[pIndex]
                        if !pText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            HStack(alignment: .bottom, spacing: 0) {
                                Text(attributedString(from: pText))
                                    .fixedSize(horizontal: false, vertical: true)
                                    .lineSpacing(6)
                                
                                if isStreaming && index == segments.count - 1 && pIndex == paragraphs.count - 1 {
                                    Rectangle()
                                        .fill(Color.primary)
                                        .frame(width: 8, height: 18)
                                        .padding(.leading, 4)
                                        .padding(.bottom, 2)
                                }
                            }
                        }
                    }
                }
            }
            
            if text.isEmpty && isStreaming {
                Rectangle()
                    .fill(Color.primary)
                    .frame(width: 8, height: 18)
            }
        }
    }
    
    private func attributedString(from text: String) -> AttributedString {
        do {
            let processed = text.replacingOccurrences(of: "\n", with: "  \n")
            let attributed = try AttributedString(markdown: processed, options: .init(interpretedSyntax: .full))
            return attributed
        } catch {
            return AttributedString(text)
        }
    }
    
    struct MarkdownSegment {
        let content: String
        let isCode: Bool
        let language: String?
    }
    
    private func parseMarkdown(_ text: String) -> [MarkdownSegment] {
        var segments: [MarkdownSegment] = []
        let lines = text.components(separatedBy: .newlines)
        
        var currentBlock: [String] = []
        var isInCodeBlock = false
        var currentLanguage: String? = nil
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("```") {
                if isInCodeBlock {
                    segments.append(MarkdownSegment(content: currentBlock.joined(separator: "\n"), isCode: true, language: currentLanguage))
                    currentBlock = []
                    isInCodeBlock = false
                    currentLanguage = nil
                } else {
                    if !currentBlock.isEmpty {
                        segments.append(MarkdownSegment(content: currentBlock.joined(separator: "\n"), isCode: false, language: nil))
                    }
                    currentBlock = []
                    isInCodeBlock = true
                    currentLanguage = trimmed.replacingOccurrences(of: "```", with: "")
                    if currentLanguage?.isEmpty == true { currentLanguage = nil }
                }
            } else {
                currentBlock.append(line)
            }
        }
        
        if !currentBlock.isEmpty {
            segments.append(MarkdownSegment(content: currentBlock.joined(separator: "\n"), isCode: isInCodeBlock, language: currentLanguage))
        }
        
        return segments
    }
}

struct CodeBlockView: View {
    let content: String
    let language: String?
    @State private var showingCopied = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                let displayLanguage = language?.lowercased() ?? "code"
                Text(displayLanguage)
                    .font(.caption2.monospaced())
                    .foregroundColor(.gray)
                Spacer()
                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(content, forType: .string)
                    showingCopied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        showingCopied = false
                    }
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showingCopied ? "checkmark" : "doc.on.doc")
                        Text(showingCopied ? "Copied!" : "Copy code")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(white: 0.15))
            
            ScrollView(.horizontal, showsIndicators: true) {
                HighlightedCodeView(code: content, language: language)
                    .padding(16)
                    .textSelection(.enabled)
            }
            .background(Color.black)
            .foregroundColor(Color(white: 0.9))
        }
        .cornerRadius(8)
        .padding(.vertical, 4)
    }
}

struct HighlightedCodeView: View {
    let code: String
    let language: String?
    
    var body: some View {
        let grammar: Grammar = {
            guard let lang = language?.lowercased() else { return SwiftGrammar() }
            switch lang {
            case "swift": return SwiftGrammar()
            default: return SwiftGrammar()
            }
        }()
        
        let theme = Splash.Theme.midnight(withFont: Splash.Font(size: 13))
        let highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme), grammar: grammar)
        let attributedString = highlighter.highlight(code)
        
        Text(attributedString)
            .font(.system(.body, design: .monospaced))
    }
}

struct AttributedStringOutputFormat: OutputFormat {
    private let theme: Theme

    init(theme: Theme) {
        self.theme = theme
    }

    func makeBuilder() -> Builder {
        return Builder(theme: theme)
    }
}

extension AttributedStringOutputFormat {
    struct Builder: OutputBuilder {
        private let theme: Theme
        private var accumulated = AttributedString()

        init(theme: Theme) {
            self.theme = theme
        }

        mutating func addToken(_ token: String, ofType type: TokenType) {
            var attributedToken = AttributedString(token)
            let color = theme.tokenColors[type] ?? .white
            #if os(macOS)
            attributedToken.foregroundColor = Color(nsColor: color)
            #else
            attributedToken.foregroundColor = Color(uiColor: color)
            #endif
            accumulated += attributedToken
        }

        mutating func addPlainText(_ text: String) {
            var attributedText = AttributedString(text)
            #if os(macOS)
            attributedText.foregroundColor = Color(nsColor: theme.plainTextColor)
            #else
            attributedText.foregroundColor = Color(uiColor: theme.plainTextColor)
            #endif
            accumulated += attributedText
        }

        mutating func addWhitespace(_ whitespace: String) {
            accumulated += AttributedString(whitespace)
        }

        func build() -> AttributedString {
            return accumulated
        }
    }
}
