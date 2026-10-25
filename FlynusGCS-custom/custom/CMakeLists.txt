# ============================================================================
# Flynus GCS - QGroundControl custom build (branding)
# ============================================================================

message(STATUS "QGC: Adding Flynus GCS custom plugin")

# ----------------------------------------------------------------------------
# Android package template overlay: stock android/ + custom/android/ on top
# ----------------------------------------------------------------------------
if(ANDROID)
    set(CUSTOM_ANDROID_DIR "${CMAKE_CURRENT_SOURCE_DIR}/android")
    if(EXISTS "${CUSTOM_ANDROID_DIR}")
        set(DEFAULT_ANDROID_DIR "${CMAKE_SOURCE_DIR}/android")
        set(FINAL_ANDROID_DIR "${CMAKE_BINARY_DIR}/custom/android")
        file(COPY "${DEFAULT_ANDROID_DIR}/." DESTINATION "${FINAL_ANDROID_DIR}")
        execute_process(COMMAND ${CMAKE_COMMAND} -E copy_directory "${CUSTOM_ANDROID_DIR}" "${FINAL_ANDROID_DIR}")
        set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${DEFAULT_ANDROID_DIR}/" "${CUSTOM_ANDROID_DIR}/")
        set(QGC_ANDROID_PACKAGE_SOURCE_DIR "${FINAL_ANDROID_DIR}" CACHE PATH "Path to a custom Android package template" FORCE)
        message(STATUS "QGC: Flynus Android template: ${QGC_ANDROID_PACKAGE_SOURCE_DIR}")
    endif()
endif()

# ----------------------------------------------------------------------------
# Resources
# ----------------------------------------------------------------------------
list(APPEND CUSTOM_RESOURCES ${CMAKE_CURRENT_SOURCE_DIR}/custom.qrc)
set(QGC_RESOURCES ${QGC_RESOURCES} ${CUSTOM_RESOURCES} CACHE STRING "Paths to .qrc Resources" FORCE)

# ----------------------------------------------------------------------------
# Plugin sources
# ----------------------------------------------------------------------------
set(CUSTOM_SOURCES
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/src/CustomPlugin.h
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_LIBRARIES "" CACHE INTERNAL "" FORCE)

set(CUSTOM_INCLUDE_DIRECTORIES
    ${CMAKE_CURRENT_SOURCE_DIR}/src
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_DEFINITIONS
    QGC_CUSTOM_BUILD
    CUSTOMHEADER="CustomPlugin.h"
    CUSTOMCLASS=CustomPlugin
    CACHE INTERNAL "" FORCE
)

set(CUSTOM_QT_COMPONENTS Core CACHE INTERNAL "" FORCE)
