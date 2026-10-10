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
OPENH264_ROOT=/Users/anathan/Desktop/ffmpeg_build/openh264-2.6.0/android

LIB_DIR=$PREFIX/lib/$ABI
OPENH264_LIB=$OPENH264_ROOT/$ABI/lib/libopenh264.a
OUTPUT_SO_NAME=libavkit.so
OUTPUT_SO=$LIB_DIR/$OUTPUT_SO_NAME

# Use clang++ for the final link because OpenH264 contains C++ code.
# -static-libstdc++ keeps the C++ runtime inside libavkit.so, so Android does
# not need an additional libc++_shared.so.
case $ABI in
  armeabi-v7a)
    CXX=$TOOLCHAIN/bin/armv7a-linux-androideabi${API_LEVEL}-clang++
    ;;
  arm64-v8a)
    CXX=$TOOLCHAIN/bin/aarch64-linux-android${API_LEVEL}-clang++
    ;;
  x86_64)
    CXX=$TOOLCHAIN/bin/x86_64-linux-android${API_LEVEL}-clang++
    ;;
  *)
    echo "Unsupported ABI: $ABI"
    exit 1
    ;;
esac

if [ ! -f "$OPENH264_LIB" ]; then
  echo "ERROR: Cannot find OpenH264 static library for ABI $ABI"
  echo "Expected: $OPENH264_LIB"
  exit 1
fi

for LIB in \
  "$LIB_DIR/libavcodec.a" \
  "$LIB_DIR/libavformat.a" \
  "$LIB_DIR/libavutil.a" \
  "$LIB_DIR/libswresample.a" \
  "$LIB_DIR/libswscale.a" \
  "$LIB_DIR/libavfilter.a"; do
  if [ ! -f "$LIB" ]; then
    echo "ERROR: Cannot find FFmpeg static library: $LIB"
    exit 1
  fi
done

echo "Linking FFmpeg + OpenH264 static libraries into $OUTPUT_SO"
echo "Using OpenH264: $OPENH264_LIB"

"$CXX" \
  -fPIC \
  -shared \
  -static-libstdc++ \
  -Wl,-Bsymbolic \
  -Wl,--no-undefined \
  -Wl,--whole-archive \
  "$LIB_DIR/libavcodec.a" \
  "$LIB_DIR/libavformat.a" \
  "$LIB_DIR/libavutil.a" \
  "$LIB_DIR/libswresample.a" \
  "$LIB_DIR/libswscale.a" \
  "$LIB_DIR/libavfilter.a" \
  "$OPENH264_LIB" \
  -Wl,--no-whole-archive \
  -Wl,-soname=$OUTPUT_SO_NAME \
  -lc -lm -lz -llog -landroid -ldl \
  -o "$OUTPUT_SO"

echo "Created shared library: $OUTPUT_SO"
