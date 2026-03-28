#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
CARGO_MANIFEST="$SCRIPT_DIR/Cargo.toml"
LIB_NAME="rust_lib_polar_app"

echo "Building for macOS (native arch)..."
cargo build --manifest-path "$CARGO_MANIFEST" --lib --release

STATIC_LIB="$SCRIPT_DIR/../target/release/lib${LIB_NAME}.a"

# Copy static library to BUILT_PRODUCTS_DIR so Xcode linker finds it
if [ -n "${BUILT_PRODUCTS_DIR:-}" ]; then
    mkdir -p "${BUILT_PRODUCTS_DIR}"
    cp "$STATIC_LIB" "${BUILT_PRODUCTS_DIR}/lib${LIB_NAME}.a"
    echo "Copied static lib to: ${BUILT_PRODUCTS_DIR}/lib${LIB_NAME}.a"
fi

echo "Built: $STATIC_LIB"
