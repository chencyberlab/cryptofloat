#!/bin/bash
# Reliable local build script for the CryptoFloat macOS app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

APP_NAME="CryptoFloat"
APP_VERSION="1.1.0"
MINIMUM_MACOS_VERSION="11.0"
ICON_FILE="AppIcon.icns"
APP_BUNDLE="$SCRIPT_DIR/$APP_NAME.app"
BUILD_ARCH="${BUILD_ARCH:-native}"
SWIFT_FILES=(
    Sources/CryptoFloatCore/*.swift
    Sources/CryptoFloatApp/*.swift
)

for required_file in "${SWIFT_FILES[@]}" "$ICON_FILE"; do
    if [[ ! -f "$required_file" ]]; then
        echo "❌ Required build input is missing: $required_file"
        exit 1
    fi
done

if ! command -v swiftc >/dev/null 2>&1; then
    echo "❌ Swift compiler not found. Install Xcode or the Xcode Command Line Tools."
    echo "   Run: xcode-select --install"
    exit 1
fi

BUILD_ROOT="$(mktemp -d "$SCRIPT_DIR/.cryptofloat-build.XXXXXX")"
STAGED_APP="$BUILD_ROOT/$APP_NAME.app"
STAGED_EXECUTABLE="$STAGED_APP/Contents/MacOS/$APP_NAME"
PREVIOUS_APP="$BUILD_ROOT/previous-$APP_NAME.app"

cleanup() {
    local exit_status=$?
    trap - EXIT

    # Installing the staged bundle happens only after every validation succeeds.
    # If the shell is interrupted after the old app is moved aside, put it back
    # before removing the private staging directory.
    if [[ ! -e "$APP_BUNDLE" && -e "$PREVIOUS_APP" ]]; then
        if ! mv "$PREVIOUS_APP" "$APP_BUNDLE"; then
            echo "❌ Build cleanup could not restore the previous app at $APP_BUNDLE" >&2
            echo "   Backup preserved at: $PREVIOUS_APP" >&2
            exit 1
        fi
    fi

    rm -rf "$BUILD_ROOT"
    exit "$exit_status"
}
trap cleanup EXIT
trap 'exit 130' INT
trap 'exit 143' TERM
trap 'exit 129' HUP

mkdir -p "$STAGED_APP/Contents/MacOS" "$STAGED_APP/Contents/Resources"

compile_architecture() {
    local architecture="$1"
    local output="$2"
    local module_cache="$BUILD_ROOT/module-cache-$architecture"

    swiftc \
        -O \
        -swift-version 5 \
        -target "$architecture-apple-macosx$MINIMUM_MACOS_VERSION" \
        -module-cache-path "$module_cache" \
        -o "$output" \
        -framework Cocoa \
        -framework Foundation \
        "${SWIFT_FILES[@]}"
}

case "$BUILD_ARCH" in
    native)
        RESOLVED_ARCH="$(uname -m)"
        ;;
    arm64|x86_64)
        RESOLVED_ARCH="$BUILD_ARCH"
        ;;
    universal)
        RESOLVED_ARCH="universal"
        ;;
    *)
        echo "❌ Unsupported BUILD_ARCH '$BUILD_ARCH'. Use native, arm64, x86_64, or universal."
        exit 1
        ;;
esac

echo "🔨 Building $APP_NAME $APP_VERSION ($RESOLVED_ARCH, macOS $MINIMUM_MACOS_VERSION+)..."

if [[ "$RESOLVED_ARCH" == "universal" ]]; then
    ARM_EXECUTABLE="$BUILD_ROOT/$APP_NAME-arm64"
    INTEL_EXECUTABLE="$BUILD_ROOT/$APP_NAME-x86_64"
    compile_architecture "arm64" "$ARM_EXECUTABLE"
    compile_architecture "x86_64" "$INTEL_EXECUTABLE"
    /usr/bin/lipo -create "$ARM_EXECUTABLE" "$INTEL_EXECUTABLE" -output "$STAGED_EXECUTABLE"
else
    compile_architecture "$RESOLVED_ARCH" "$STAGED_EXECUTABLE"
fi

cp "$ICON_FILE" "$STAGED_APP/Contents/Resources/$ICON_FILE"

cat > "$STAGED_APP/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>com.cryptofloat.app</string>
    <key>CFBundleVersion</key>
    <string>$APP_VERSION</string>
    <key>CFBundleShortVersionString</key>
    <string>$APP_VERSION</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.finance</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSMinimumSystemVersion</key>
    <string>$MINIMUM_MACOS_VERSION</string>
</dict>
</plist>
EOF

printf 'APPL????' > "$STAGED_APP/Contents/PkgInfo"

/usr/bin/plutil -lint "$STAGED_APP/Contents/Info.plist" >/dev/null
test -x "$STAGED_EXECUTABLE"
test -s "$STAGED_APP/Contents/Resources/$ICON_FILE"

# Ad-hoc signing keeps local bundles internally consistent. Distribution builds
# should replace "-" with a Developer ID identity and then be notarized.
/usr/bin/codesign --force --deep --sign - "$STAGED_APP"
/usr/bin/codesign --verify --deep --strict "$STAGED_APP"

if [[ -e "$APP_BUNDLE" ]]; then
    mv "$APP_BUNDLE" "$PREVIOUS_APP"
fi

if ! mv "$STAGED_APP" "$APP_BUNDLE"; then
    if [[ -e "$PREVIOUS_APP" ]]; then
        mv "$PREVIOUS_APP" "$APP_BUNDLE"
    fi
    echo "❌ Could not install the newly built app bundle."
    exit 1
fi

rm -rf "$PREVIOUS_APP"

echo "✅ Build successful: $APP_BUNDLE"
echo "   Run with: open \"$APP_BUNDLE\""
