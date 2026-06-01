# libavkit Android

libavkit Android is a lightweight multimedia toolkit for Android streaming and media processing scenarios.

This project provides prebuilt Android shared libraries and build scripts based on FFmpeg for RTSP/RTMP streaming, media muxing/demuxing, and related multimedia workflows.

## Features

- RTSP streaming
- RTMP streaming
- MP4 muxing
- H.264 / AAC support
- Android NDK support
- Shared library build
- Android network routing support

## Build Environment

Example build environment:

- macOS: macOS 12.7.6
- Android NDK: r28c
- FFmpeg: 6.0

You may replace the versions above according to your local environment.

## Supported Architectures

- armeabi-v7a
- arm64-v8a
- x86_64

## Build Instructions

### 1. Configure Android NDK

Open the `build_ffmpeg_android.sh`  file and set the Android NDK path before building:

```bash
export NDK=/Users/yourname/Library/Android/sdk/ndk/28.2.xxxxxxx
```

### 2. Grant Execute Permission

```bash
chmod +x build_ffmpeg_android.sh
```

### 3. Build Libraries

```bash
./build_ffmpeg_android.sh
```

After a successful build, the generated shared libraries will be located in:

```text
android/
```

or the corresponding ABI output directories.

## Notes

This project builds FFmpeg as Android shared libraries and includes additional Android-specific networking support for multimedia streaming scenarios.

The generated library name may differ depending on the build configuration.

## License

This project includes FFmpeg licensed under the GNU Lesser General Public License (LGPL) version 2.1.

FFmpeg copyright belongs to the FFmpeg developers.

Modified source code used in this project is provided in accordance with the LGPL license requirements.

For more information about FFmpeg:

https://ffmpeg.org/

LGPL v2.1 license text:

https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
