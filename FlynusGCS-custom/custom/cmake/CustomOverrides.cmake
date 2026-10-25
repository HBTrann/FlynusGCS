# ============================================================================
# Flynus GCS - build configuration overrides
# ============================================================================

# Internal app/target name (no spaces allowed in CMake target names).
# The user-visible Android label "Flynus GCS" is set in custom/android/AndroidManifest.xml.
set(QGC_APP_NAME "FlynusGCS" CACHE STRING "App Name" FORCE)
set(QGC_ORG_NAME "Flynus" CACHE STRING "Org Name" FORCE)
set(QGC_ORG_DOMAIN "hypmotion.com" CACHE STRING "Domain" FORCE)
set(QGC_APP_DESCRIPTION "Flynus GCS - Ground Control Station" CACHE STRING "Description" FORCE)
set(QGC_APP_COPYRIGHT "Copyright (C) 2026 Hypmotion. All rights reserved." CACHE STRING "Copyright" FORCE)
# Different package id => installs side-by-side with stock QGroundControl.
set(QGC_ANDROID_PACKAGE_NAME "com.hypmotion.flynusgcs" CACHE STRING "Android package identifier" FORCE)
set(QGC_MACOS_BUNDLE_ID "com.hypmotion.flynusgcs" CACHE STRING "macOS bundle id" FORCE)

# Icons
set(_FLYNUS_DIR "${CMAKE_SOURCE_DIR}/${QGC_CUSTOM_DIR}")
set(QGC_MACOS_ICON_PATH "${_FLYNUS_DIR}/res/icons/flynus_gcs.icns" CACHE FILEPATH "MacOS Icon Path" FORCE)
set(QGC_APPIMAGE_ICON_SCALABLE_PATH "${_FLYNUS_DIR}/res/icons/flynus_gcs.svg" CACHE FILEPATH "AppImage Icon SVG Path" FORCE)
set(QGC_APPIMAGE_ICON_256_PATH "${_FLYNUS_DIR}/res/icons/flynus_gcs_256.png" CACHE FILEPATH "AppImage Icon 256 Path" FORCE)
set(QGC_WINDOWS_ICON_PATH "${_FLYNUS_DIR}/deploy/windows/FlynusGCS.ico" CACHE FILEPATH "Windows Icon Path" FORCE)
set(QGC_WINDOWS_INSTALL_HEADER_PATH "${_FLYNUS_DIR}/deploy/windows/installheader.bmp" CACHE FILEPATH "Windows Install Header Path" FORCE)

# Both PX4 and ArduPilot stay supported (stock firmware plugins are kept).
