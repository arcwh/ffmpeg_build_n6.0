#!/bin/bash
set -e

ABI=$1
PREFIX=$2
API_LEVEL=$3

if [ -z "$ABI" ] || [ -z "$PREFIX" ] || [ -z "$API_LEVEL" ]; then
  echo "Usage: $0 <abi> <prefix_dir> <api_level>"
  exit 1
fi

NDK=/Users/anathan/Documents/android-ndk-r28c
TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64
LIB_DIR=$PREFIX/lib/$ABI
OUTPUT_SO_NAME=libavkit.so
OUTPUT_SO=$LIB_DIR/$OUTPUT_SO_NAME

# Select CC and builtins path based on ABI
case $ABI in
  armeabi-v7a)
    CC=$TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang
    BUILTINS_PATH=$(find "$TOOLCHAIN/lib/clang" -name "libclang_rt.builtins-arm-android.a" | head -n 1)
    ;;
  arm64-v8a)
    CC=$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang
    BUILTINS_PATH=$(find "$TOOLCHAIN/lib/clang" -name "libclang_rt.builtins-aarch64-android.a" | head -n 1)
    ;;
  x86_64)
    CC=$TOOLCHAIN/bin/x86_64-linux-android${API_LEVEL}-clang
    BUILTINS_PATH=$(find "$TOOLCHAIN/lib/clang" -name "libclang_rt.builtins-x86_64-android.a" | head -n 1)
    ;;
  *)
    echo "Unsupported ABI: $ABI"
    exit 1
    ;;
esac

# Check that the runtime lib exists
if [ ! -f "$BUILTINS_PATH" ]; then
  echo "ERROR: Cannot find libclang_rt.builtins for ABI $ABI"
  exit 1
fi

echo "Linking static libs into $OUTPUT_SO"
echo "Using builtins: $BUILTINS_PATH"

$CC \
  -fPIC \
  -shared \
  -nostdlib \
  -Wl,-Bsymbolic \
  -Wl,--no-undefined \
  -Wl,--whole-archive \
  $LIB_DIR/libavcodec.a \
  $LIB_DIR/libavformat.a \
  $LIB_DIR/libavutil.a \
  $LIB_DIR/libswresample.a \
  $LIB_DIR/libswscale.a \
  $LIB_DIR/libavfilter.a \
  -Wl,--no-whole-archive \
  -Wl,-soname=$OUTPUT_SO_NAME \
  -lc -lm -lz -llog -landroid -ldl \
  "$BUILTINS_PATH" \
  -o $OUTPUT_SO

echo "Created shared library: $OUTPUT_SO"