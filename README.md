# libavkit Android

libavkit Android is a lightweight multimedia toolkit for Android streaming and media processing scenarios.

This project provides prebuilt Android shared libraries and build scripts based on FFmpeg for RTSP/RTMP streaming, media muxing/demuxing, and related multimedia workflows.

------

## Features

- RTSP streaming
- RTMP streaming
- MP4 muxing
- H.264 / AAC support
- H.264 software encoding via OpenH264 (`libopenh264` encoder)
- Android NDK support
- Shared library build
- Android network routing support

------

## Build Environment

Example build environment:

- macOS: macOS 12.7.6 (the build scripts only support macOS hosts)
- Android NDK: r28c
- FFmpeg: 6.0
- OpenH264: 2.6.0

You may replace the versions above according to your local environment.

`pkg-config` does **not** need to be installed. The build script generates a temporary pkg-config compatibility script for OpenH264 by itself.

------

## Supported Architectures

- armeabi-v7a
- arm64-v8a

------

## Build Overview

The final output is a single shared library, `libavkit.so`, for each ABI. It is built in three stages:

1. **Build OpenH264** as Android libraries (`libopenh264.a` / `libopenh264.so`). This is done in the separate OpenH264 project.
2. **Build FFmpeg** as static libraries (`libavcodec.a`, `libavformat.a`, etc.) with `--enable-libopenh264`.
3. **Merge** the FFmpeg static libraries and `libopenh264.a` into `libavkit.so`.

Stages 2 and 3 are both performed by `build_ffmpeg_android.sh`, which calls `merge_static_to_shared.sh` automatically after FFmpeg is built for each ABI.

> **Important:** OpenH264 must be built **before** building FFmpeg. If the OpenH264 libraries cannot be found, `build_ffmpeg_android.sh` stops with a `Cannot find OpenH264 ...` error and no `libavkit.so` will be generated.

------

## Build Instructions

### 1. Build OpenH264

Get the OpenH264 project and build it by following its README:

```bash
cd /path/to/openh264-2.6.0
./build_openh264_android.sh
```

After a successful build, make sure the following files exist for **every** ABI you want to build (`armeabi-v7a` and `arm64-v8a`):

```text
openh264-2.6.0/android/<ABI>/
├── include/wels/codec_api.h
└── lib/
    ├── libopenh264.a     # Linked into the final libavkit.so
    └── libopenh264.so    # Only used by FFmpeg configure for its link check
```

Both `libopenh264.a` and `libopenh264.so` are required. The `.so` is only used to let FFmpeg `configure` pass its OpenH264 detection, and the final `libavkit.so` does **not** depend on it at runtime.

The `API` level used for OpenH264 should not be higher than the `API` level used for FFmpeg.

------

### 2. Configure the Build Scripts

Both build scripts in this project contain machine-specific paths. Update **both** of them before building.

**`build_ffmpeg_android.sh`**

```bash
export NDK=/Users/yourname/Library/Android/sdk/ndk/28.2.xxxxxxx   # Path to the Android NDK
export API=23                                                     # Minimum Android API level (minSdk)
export OPENH264_ROOT=/path/to/openh264-2.6.0/android              # OpenH264 output directory from step 1
```

**`merge_static_to_shared.sh`**

```bash
NDK=/Users/yourname/Library/Android/sdk/ndk/28.2.xxxxxxx          # Must be the same as in build_ffmpeg_android.sh
OPENH264_ROOT=/path/to/openh264-2.6.0/android                     # Must be the same as in build_ffmpeg_android.sh
```

- `NDK`: **Must** be changed to the Android NDK path on your machine.
- `API`: The minimum Android API level of the generated libraries. It should not be higher than the `minSdk` of the app that uses them. It is passed to `merge_static_to_shared.sh` automatically.
- `OPENH264_ROOT`: **Must** point to the `android/` output directory of OpenH264 (the directory that contains the `<ABI>` subdirectories), not to the OpenH264 source root.

`NDK` and `OPENH264_ROOT` are not passed from `build_ffmpeg_android.sh` to `merge_static_to_shared.sh`, so the values in the two scripts must be kept the same. If only `build_ffmpeg_android.sh` is updated, FFmpeg will build successfully but the final merge step will fail.

To build only one ABI, edit the `ABIS` array near the end of `build_ffmpeg_android.sh`.

------

### 3. Grant Execute Permission

```bash
chmod +x build_ffmpeg_android.sh merge_static_to_shared.sh
```

------

### 4. Build Libraries

Run the script **from the project root**:

```bash
cd /path/to/ffmpeg_build_n6.0
./build_ffmpeg_android.sh
```

For each ABI, the script will:

1. Check that the OpenH264 headers, `libopenh264.a` and `libopenh264.so` exist.
2. Configure and build FFmpeg as static libraries, then install them to `android/`.
3. Call `merge_static_to_shared.sh` to link the FFmpeg static libraries and `libopenh264.a` into `libavkit.so`.

------

## Build Output

After a successful build, the output is located in the `android/` directory of the project root:

```text
android/
├── include/
│   ├── armeabi-v7a/          # FFmpeg headers (libavcodec/, libavformat/, ...)
│   └── arm64-v8a/
├── lib/
│   ├── armeabi-v7a/
│   │   ├── libavkit.so       # Final shared library
│   │   ├── libavcodec.a
│   │   ├── libavfilter.a
│   │   ├── libavformat.a
│   │   ├── libavutil.a
│   │   ├── libswresample.a
│   │   └── libswscale.a
│   └── arm64-v8a/
│       └── (same layout as armeabi-v7a)
└── pkgconfig/
    ├── armeabi-v7a/
    └── arm64-v8a/
```

- `lib/<ABI>/libavkit.so`: The final shared library used by the Android project. It contains FFmpeg and OpenH264.
- `include/<ABI>/`: FFmpeg public headers.
- `lib/<ABI>/*.a` and `pkgconfig/<ABI>/`: Intermediate FFmpeg static libraries and pkg-config files. They are not needed for Android integration.

`libavkit.so` statically links OpenH264 and the C++ runtime (`-static-libstdc++`). The Android project only needs to include `libavkit.so`. It does **not** need `libopenh264.so` or `libc++_shared.so`.

------

## Notes

- This project builds FFmpeg as Android shared libraries and includes additional Android-specific networking support for multimedia streaming scenarios.
- The script runs `make distclean` before building each ABI, which removes the files generated by `configure` in the source root. This is expected.
- If you rebuild OpenH264 (for example, with a different `API` level), rebuild FFmpeg as well so that `libavkit.so` links the new `libopenh264.a`.

------

## License

This project includes FFmpeg licensed under the GNU Lesser General Public License (LGPL) version 2.1.

FFmpeg copyright belongs to the FFmpeg developers.

Modified source code used in this project is provided in accordance with the LGPL license requirements.

`libavkit.so` also includes OpenH264, which is licensed under the BSD 2-Clause License. OpenH264 copyright belongs to Cisco Systems.

Note that Cisco's H.264 patent license only covers the prebuilt OpenH264 binaries distributed by Cisco. OpenH264 built from source, as in this project, is not covered by that license. Please evaluate the H.264 patent licensing requirements for your product before distribution.

For more information about FFmpeg:

https://ffmpeg.org/

For more information about OpenH264:

https://github.com/cisco/openh264

LGPL v2.1 license text:

https://www.gnu.org/licenses/old-licenses/lgpl-2.1.html
