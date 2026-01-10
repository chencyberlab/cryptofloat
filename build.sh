#!/bin/bash
# Build script for CryptoFloat Swift app

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="CryptoFloat"
SWIFT_FILE="CryptoFloat.swift"

echo "🔨 Building $APP_NAME..."

# Check if Swift is available
if ! command -v swiftc &> /dev/null; then
    echo "❌ Swift compiler not found. Please install Xcode or Xcode Command Line Tools."
    echo "   Run: xcode-select --install"
    exit 1
fi

# Create app bundle structure
APP_BUNDLE="$APP_NAME.app"
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Compile Swift code
echo "   Compiling Swift code..."
swiftc -O \
    -o "$APP_BUNDLE/Contents/MacOS/$APP_NAME" \
    -framework Cocoa \
    -framework Foundation \
    "$SWIFT_FILE"

if [ $? -ne 0 ]; then
    echo "❌ Compilation failed!"
    exit 1
fi

# Create Info.plist
cat > "$APP_BUNDLE/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>CryptoFloat</string>
    <key>CFBundleDisplayName</key>
    <string>CryptoFloat</string>
    <key>CFBundleIdentifier</key>
    <string>com.cryptofloat.app</string>
    <key>CFBundleVersion</key>
    <string>1.0.0</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleExecutable</key>
    <string>CryptoFloat</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>11.0</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Create PkgInfo
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "✅ Build successful!"
echo ""
echo "📦 App bundle created: $APP_BUNDLE"
echo ""
echo "To run:"
echo "   open $APP_BUNDLE"
echo ""
echo "To install:"
echo "   cp -r $APP_BUNDLE /Applications/"
echo ""
