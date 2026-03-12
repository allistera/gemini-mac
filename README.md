# GeminiChat

A native macOS chat application for [Google Gemini](https://ai.google.dev/) built with SwiftUI and the [Google Generative AI Swift SDK](https://github.com/google/generative-ai-swift).

## Features

- **Chat with Gemini** – Send messages and get responses from Google’s Gemini models
- **Multiple conversations** – Organize chats in a sidebar with support for folders
- **Model selection** – Choose from available Gemini models (e.g. Gemini 1.5 Pro, Flash)
- **API key management** – Enter your Gemini API key once; optional save to Keychain/UserDefaults
- **Code highlighting** – Inline code in responses is syntax-highlighted via [Splash](https://github.com/JohnSundell/Splash)

## Requirements

- **macOS 14.0** or later
- **Xcode 15+** (or Swift 5.9+ command-line tools)
- A [Google AI Studio API key](https://aistudio.google.com/apikey)

## Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/allistera/gemini-mac.git
cd gemini-mac
```

### 2. Build and run

```bash
swift build
swift run GeminiChat
```

Or open the package in Xcode and run the **GeminiChat** scheme:

```bash
open Package.swift
```

### 3. Create an app bundle (optional)

To build a standalone `.app` you can double-click:

```bash
./build_app.sh
```

Then open `GeminiChat.app` from the project directory.

### 4. Add your API key

On first launch, enter your [Google AI Studio API key](https://aistudio.google.com/apikey). You can optionally save it so you don’t need to re-enter it. The app will fetch available Gemini models after the key is set.

## Project structure

```
gemini-app/
├── Package.swift              # Swift package definition and dependencies
├── Sources/GeminiChat/
│   ├── GeminiChatApp.swift    # App entry point and window setup
│   ├── ViewModels/
│   │   └── ChatViewModel.swift # API key, models, conversations, send logic
│   ├── Models/
│   │   ├── Conversation.swift
│   │   ├── Message.swift
│   │   └── Folder.swift
│   └── Views/
│       ├── MainView.swift     # NavigationSplitView (sidebar + detail)
│       ├── SidebarView.swift  # Conversation and folder list
│       ├── ChatDetailView.swift
│       ├── APIKeyView.swift
│       └── GeminiLogo.swift
├── build_app.sh               # Script to create GeminiChat.app
└── .github/workflows/
    └── lint.yml               # SwiftLint on push/PR to main
```

## Dependencies

- [google/generative-ai-swift](https://github.com/google/generative-ai-swift) – Google Gemini API client
- [JohnSundell/Splash](https://github.com/JohnSundell/Splash) – Syntax highlighting for code in messages

## Development

- Linting is enforced with [SwiftLint](https://github.com/realm/SwiftSwiftLint); see `.swiftlint.yml`.
- CI runs SwiftLint on pushes and pull requests to `main` (see `.github/workflows/lint.yml`).

## License

See the repository license file for terms of use.
