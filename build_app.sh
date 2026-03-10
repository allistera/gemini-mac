#!/bin/bash

# Configuration
APP_NAME="GeminiChat"
BUNDLE_ID="com.example.GeminiChat"
EXECUTABLE_PATH=".build/arm64-apple-macosx/debug/$APP_NAME"
APP_BUNDLE="$APP_NAME.app"

# 1. Build the app
echo "Building $APP_NAME..."
swift build

if [ $? -ne 0 ]; then
    echo "Build failed."
    exit 1
fi

# 2. Create the .app bundle structure
echo "Creating $APP_BUNDLE..."
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# 3. Copy the executable
cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/"

# 4. Create the Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
</dict>
</plist>
EOF

echo "Done! You can now click on $APP_BUNDLE to launch your app."
