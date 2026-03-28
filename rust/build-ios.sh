#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$(realpath "$0")")" && pwd)"
CARGO_MANIFEST="$SCRIPT_DIR/Cargo.toml"
LIB_NAME="rust_lib_polar_app"
WORKSPACE_TARGET="$SCRIPT_DIR/../target"

# Determine targets based on Xcode build
if [ "${PLATFORM_NAME:-iphoneos}" = "iphonesimulator" ]; then
    if [ "$(uname -m)" = "arm64" ]; then
        TARGETS="aarch64-apple-ios-sim"
    else
        TARGETS="x86_64-apple-ios"
    fi
else
    TARGETS="aarch64-apple-ios"
fi

# Build for each target
for TARGET in $TARGETS; do
    echo "Building for $TARGET..."
    cargo build --manifest-path "$CARGO_MANIFEST" --lib --release --target "$TARGET"
done

# Create universal output directory
UNIVERSAL_DIR="$SCRIPT_DIR/target/universal-ios/release"
mkdir -p "$UNIVERSAL_DIR"

# Use lipo to merge if multiple targets
if [ $(echo "$TARGETS" | wc -w) -gt 1 ]; then
    LIBS=""
    for TARGET in $TARGETS; do
        LIBS="$LIBS $WORKSPACE_TARGET/$TARGET/release/lib${LIB_NAME}.a"
    done
    lipo -create $LIBS -output "$UNIVERSAL_DIR/lib${LIB_NAME}.a"
else
    TARGET=$(echo "$TARGETS" | head -1)
    cp "$WORKSPACE_TARGET/$TARGET/release/lib${LIB_NAME}.a" "$UNIVERSAL_DIR/lib${LIB_NAME}.a"
fi

# Copy to BUILT_PRODUCTS_DIR so Xcode linker finds it
if [ -n "${BUILT_PRODUCTS_DIR:-}" ]; then
    cp "$UNIVERSAL_DIR/lib${LIB_NAME}.a" "${BUILT_PRODUCTS_DIR}/lib${LIB_NAME}.a"
    echo "Copied to: ${BUILT_PRODUCTS_DIR}/lib${LIB_NAME}.a"
fi

echo "Built: $UNIVERSAL_DIR/lib${LIB_NAME}.a"
