# Flynus GCS — QGroundControl custom build

This folder rebrands QGroundControl **5.1 stable** (branch `Stable_V5.1`, i.e. v5.1.5 + bug fixes) as **Flynus GCS**. It changes only the branding. All the normal QGC features stay on, for both PX4 and ArduPilot.

| What | Value |
|---|---|
| App label (Android launcher) | Flynus GCS |
| Internal app / target name | `FlynusGCS` (CMake targets can't contain spaces) |
| Android package id | `com.flynus.gcs` (installs alongside stock QGC) |
| Default theme | White (light) on every platform; users can still switch in *Application Settings → General → Color Scheme* |
| Accent colors | Flynus green `#223B25` (buttons, highlights, borders), Flynus red `#BC0814` (warnings, map indicators) |
| Logo | Flynus "F" mark replaces the QGC logo (toolbar button, settings icon, GCS position marker on the map) |
| Launcher icon | Adaptive icon (white background + F mark, vector) and legacy PNGs; Android 13 themed/monochrome icon included |
| Splash | White screen with the Flynus wordmark |
| Update check | Disabled, so users don't get "new QGroundControl version" prompts |

## Layout

```
custom/
├── CMakeLists.txt              plugin build + Android template overlay
├── cmake/CustomOverrides.cmake app name, package id, icons
├── custom.qrc                  logo overrides (qrc:/res/... -> qrc:/Custom/res/...)
├── src/CustomPlugin.{h,cc}     palette, light-theme default, URL interceptor
├── res/Images/                 Flynus SVGs (mark, wordmark, white variants) + original PNG
├── res/icons/                  .ico / .icns / .png / .svg app icons
├── deploy/windows/             Windows exe icon + installer header
├── android/                    AndroidManifest (label "Flynus GCS"), icons, splash, theme
└── github-workflow/flynus-gcs.yml  GitHub Actions: Windows installer + Android APK
```

## Build Windows (.exe installer) + Android (.apk) together — GitHub Actions

1. Fork https://github.com/mavlink/qgroundcontrol with **"Copy the master branch only" unchecked**, then create branch `flynus` from `Stable_V5.1`.
2. Copy this `custom/` folder to the repo root.
3. Copy `custom/github-workflow/flynus-gcs.yml` to `.github/workflows/flynus-gcs.yml`.
4. Commit, push the `flynus` branch, then **Actions → Flynus GCS → Run workflow** (branch `flynus`).
5. After roughly 1 hour, download two artifacts from the run:
   - **FlynusGCS-Windows-x64** → `FlynusGCS-Setup-x64.exe` (NSIS installer with the Flynus icon and header; installs to `C:\Program Files\FlynusGCS`)
   - **FlynusGCS-Android** → `FlynusGCS.apk` (arm64-v8a + armeabi-v7a)

Pushing a tag such as `flynus-v1.0.0` also runs the workflow.
For a properly signed APK (needed for in-place updates), add repo secrets `FLYNUS_KEYSTORE_BASE64`, `FLYNUS_KEYSTORE_ALIAS`, and `FLYNUS_KEYSTORE_PASSWORD`. Without them, every build is signed with a new debug key, so you have to uninstall before installing a newer build.
The Windows .exe is not code-signed, so SmartScreen will warn "Unknown publisher" (click *More info → Run anyway*). Buy a code-signing certificate if you distribute it to customers.

### Build the Windows .exe locally

Install Visual Studio 2022 (Desktop C++), Qt 6.11.1 *MSVC 2022 64-bit* with the modules listed below, CMake, Ninja, and NSIS. Then, from an *x64 Native Tools* prompt:
```bat
cmake -S . -B build-win -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_PREFIX_PATH=C:\Qt\6.11.1\msvc2022_64
cmake --build build-win
cmake --install build-win
```
This produces `build-win\FlynusGCS-installer-AMD64.exe`.

## Build the Android APK

### Option A — GitHub Actions (easiest, no local toolchain)

1. Fork https://github.com/mavlink/qgroundcontrol on GitHub.
2. Create a branch from the stable tag:
   `git checkout -b flynus origin/Stable_V5.1` (fork with "Copy the master branch only" unchecked)
3. Copy this `custom/` folder into the repo root, commit, and push the `flynus` branch.
4. In your fork, go to **Actions → Android → Run workflow**, choose branch `flynus`, and start the run.
5. When the **linux** job finishes, download the APK from that run's **Artifacts**. Without signing secrets it is signed with a debug key, which is fine for sideloading.
   (The emulator job, if it runs, may fail because it expects the stock package id. You can ignore it.)

### Option B — Build locally on Windows

Use the versions from `.github/build-config.json`:

- **Qt 6.11.1**, installed with the Qt Online Installer. Select *Desktop (MSVC 2022 64-bit or MinGW)* as the host kit, *Android arm64-v8a*, and the modules qtgraphs, qtlocation, qtpositioning, qtspeech, qtmultimedia, qtserialport, qtimageformats, qtshadertools, qtconnectivity, qtquick3d, qtsensors, qtscxml, qtwebsockets, and qthttpserver.
- **JDK 21**, **Android SDK platform 36**, build-tools 36.0.0, and **NDK r27c (27.2.12479018)**. Qt Creator → *Preferences → Devices → Android* can install these.
- **CMake 3.25 or newer** and **Ninja**.

Steps:

1. Put this folder at `qgroundcontrol/custom` (`Stable_V5.1` or v5.1.5 checkout).
2. Open `qgroundcontrol/CMakeLists.txt` in Qt Creator, select the *Android Qt 6.11.1 arm64-v8a* kit, and build in **Release**.
3. Or build from a terminal:
   ```bat
   cmake -S . -B build-android -G Ninja -DCMAKE_BUILD_TYPE=Release ^
     -DCMAKE_TOOLCHAIN_FILE=C:\Qt\6.11.1\android_arm64_v8a\lib\cmake\Qt6\qt.toolchain.cmake ^
     -DQT_HOST_PATH=C:\Qt\6.11.1\msvc2022_64 ^
     -DQT_ANDROID_ABIS=arm64-v8a ^
     -DANDROID_SDK_ROOT=%LOCALAPPDATA%\Android\Sdk ^
     -DANDROID_NDK_ROOT=%LOCALAPPDATA%\Android\Sdk\ndk\27.2.12479018
   cmake --build build-android --config Release
   ```
4. The APK ends up in `build-android/android-build/*.apk`. Install it with `adb install -r <file>.apk`.

Always start from a clean build directory after adding or changing `custom/`. The Android template is copied in at configure time.

## Changing things later

- **Colors:** edit `paletteOverride()` in `src/CustomPlugin.cc`. The constants at the top hold the brand colors.
- **Logo:** replace the SVGs in `res/Images/`, keeping the same file names.
- **Launcher icon:** `android/res/drawable/ic_launcher_foreground.xml` (vector), `values/ic_launcher_colors.xml` (background), and `mipmap-*/ic_launcher.png` (legacy).
- **App label:** `android/AndroidManifest.xml` (two `android:label` lines).
- **Package id / version:** `cmake/CustomOverrides.cmake`.
- **Hiding features:** override more `QGCCorePlugin` / `QGCOptions` methods. See `custom-example/` in the QGC repo.

## License note

QGroundControl is dual-licensed under Apache 2.0 and GPLv3. If you distribute Flynus GCS, keep the license files and attribution. See `LICENSE-APACHE` / `LICENSE-GPL` in the QGC repo.
