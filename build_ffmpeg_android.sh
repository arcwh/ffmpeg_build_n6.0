#!/bin/bash
set -e

# Path to Android NDK
export NDK=/Users/anathan/Documents/android-ndk-r28c
export TOOLCHAIN=$NDK/toolchains/llvm/prebuilt/darwin-x86_64
export SYSROOT=$TOOLCHAIN/sysroot
export API=23
export PREFIX=android

# Compiler prefix for different ABIs
export CC_COMPILE_PREFIX_ARMV7=armv7a-linux-androideabi
export CC_COMPILE_PREFIX_ARM64=aarch64-linux-android
export CC_COMPILE_PREFIX_X86_64=x86_64-linux-android

# FFmpeg common configure options
COMMON_OPTIONS="\
  --prefix=$PREFIX \
  --target-os=android \
  --enable-cross-compile \
  --enable-static \
  --disable-shared \
  --disable-programs \
  --disable-ffmpeg \
  --disable-ffplay \
  --disable-ffprobe \
  --disable-doc \
  --disable-debug \
  --disable-symver \
  --disable-postproc \
  --disable-avdevice \
  --disable-iconv \
  --disable-vulkan \
  --enable-pic \
  --enable-jni \
  --enable-asm \
  --enable-neon \
  --enable-stripping \
  --enable-mediacodec \
  --enable-network \
  --disable-everything \
  \
  --enable-decoder=h264 \
  --enable-decoder=hevc \
  --enable-decoder=aac \
  --enable-decoder=opus \
  --enable-decoder=h264_mediacodec \
  --enable-decoder=hevc_mediacodec \
  --enable-decoder=mjpeg \
  \
  --enable-encoder=aac \
  --enable-encoder=h264_mediacodec \
  --enable-encoder=hevc_mediacodec \
  --enable-encoder=mjpeg \
  \
  --enable-parser=h264 \
  --enable-parser=hevc \
  --enable-parser=aac \
  --enable-parser=opus \
  --enable-parser=mjpeg \
  \
  --enable-muxer=mp4 \
  --enable-muxer=adts \
  --enable-muxer=flv \
  --enable-muxer=rtsp \
  --enable-muxer=sdp \
  --enable-muxer=image2 \
  \
  --enable-demuxer=mov \
  --enable-demuxer=aac \
  --enable-demuxer=flv \
  --enable-demuxer=rtsp \
  --enable-demuxer=sdp \
  --enable-demuxer=image2 \
  \
  --enable-protocol=file \
  --enable-protocol=pipe \
  --enable-protocol=rtmp \
  --enable-protocol=tcp \
  --enable-protocol=udp \
  --enable-protocol=http \
  --enable-protocol=rtp \
  \
  --enable-bsf=aac_adtstoasc \
  --enable-bsf=h264_mp4toannexb \
  --enable-bsf=hevc_mp4toannexb \
  \
  --enable-avcodec \
  --enable-avformat \
  --enable-avutil \
  --enable-swresample \
  --enable-swscale"

# Function to build FFmpeg for a specific ABI
function build_ffmpeg_for_abi() {
  ABI=$1

  case $ABI in
    armeabi-v7a)
      ARCH=arm
      CPU=armv7-a
      CC=$TOOLCHAIN/bin/${CC_COMPILE_PREFIX_ARMV7}${API}-clang
      CROSS_PREFIX=$TOOLCHAIN/bin/arm-linux-androideabi-
      EXTRA_CFLAGS="-march=armv7-a -mfloat-abi=softfp -mfpu=neon"
      EXTRA_LDFLAGS="-pie"
      ;;
    arm64-v8a)
      ARCH=aarch64
      CPU=armv8-a
      CC=$TOOLCHAIN/bin/${CC_COMPILE_PREFIX_ARM64}${API}-clang
      CROSS_PREFIX=$TOOLCHAIN/bin/aarch64-linux-android-
      EXTRA_CFLAGS="-fPIC"
      EXTRA_LDFLAGS="-pie" #-Wl,-z,common-page-size=16384 -Wl,-z,max-page-size=16384 -pie
      ;;
    x86_64)
      ARCH=x86_64
      CPU=x86_64
      CC=$TOOLCHAIN/bin/${CC_COMPILE_PREFIX_X86_64}${API}-clang
      CROSS_PREFIX=$TOOLCHAIN/bin/x86_64-linux-android-
      EXTRA_CFLAGS="-fPIC"
      EXTRA_LDFLAGS="-pie" #-Wl,-z,common-page-size=16384 -Wl,-z,max-page-size=16384 -pie
      ;;
    *)
      echo "Unsupported ABI: $ABI"
      exit 1
      ;;
  esac

  echo "Start building for ABI: $ABI"

  make distclean || true

  ./configure \
    --libdir=$PREFIX/lib/$ABI \
    --incdir=$PREFIX/include/$ABI \
    --pkgconfigdir=$PREFIX/pkgconfig/$ABI \
    --arch=$ARCH \
    --cpu=$CPU \
    --cc=$CC \
    --ar=$TOOLCHAIN/bin/llvm-ar \
    --nm=$TOOLCHAIN/bin/llvm-nm \
    --strip=$TOOLCHAIN/bin/llvm-strip \
    --ranlib=$TOOLCHAIN/bin/llvm-ranlib \
    --sysroot=$SYSROOT \
    --cross-prefix=$CROSS_PREFIX \
    --extra-cflags="$EXTRA_CFLAGS" \
    --extra-ldflags="$EXTRA_LDFLAGS" \
    $COMMON_OPTIONS

  make -j$(sysctl -n hw.ncpu)
  make install

  echo "Build finished for ABI: $ABI"

  ./merge_static_to_shared.sh $ABI $PREFIX $API
}

# ABIs to build
ABIS=("armeabi-v7a" "arm64-v8a")

# Build FFmpeg for each ABI
for ABI in "${ABIS[@]}"; do
  build_ffmpeg_for_abi $ABI
done

echo "All builds completed."