# Vendored PyroWave GPU wavelet codec - static library subproject for moonlight-qt.
#
# Built as a separate static lib (rather than injected into app.pro) so it can
# use C++20 and isolate its VMA implementation TU from the rest of the app.
# Enabled from the top-level project via `CONFIG += pyrowave`.

TEMPLATE = lib
CONFIG += staticlib c++20
CONFIG -= qt          # pure C++/Vulkan, no Qt dependency
TARGET = pyrowave

# CRITICAL (NDEBUG consistency): vk::raii / vulkan.hpp class layout and the
# DeviceDispatcher asserts are gated on NDEBUG. This codec shares vk::raii
# objects (vk::raii::Device and its dispatcher) with the app across the static
# library boundary, so it MUST be compiled with the SAME NDEBUG state as the
# app -- otherwise the dispatcher is misread at runtime and `getDispatcher()`
# aborts on `getVkHeaderVersion() == VK_HEADER_VERSION` (decoder init crash).
# So mirror the app exactly: NDEBUG in release builds, asserts in debug builds.
CONFIG(release, debug|release): DEFINES += NDEBUG

# Vulkan headers (vulkan_raii.hpp, vk_mem_alloc.h needs vulkan/vulkan.h).
#
# CRITICAL (cross-module vk::raii ABI): this codec shares vk::raii::Device + its
# DeviceDispatcher with the app across the static-library boundary, so it MUST
# resolve Vulkan headers in the SAME order as app.pro. On Windows that means the
# bundled set fetched by setup-deps.ps1 (libs/windows/include) FIRST, with the
# Vulkan SDK only as a fallback. A different header version here vs. the app would
# skew the dispatcher layout and crash decoder init on connect.
win32 {
    contains(QT_ARCH, x86_64): INCLUDEPATH += $$PWD/../libs/windows/include/x64
    contains(QT_ARCH, arm64):  INCLUDEPATH += $$PWD/../libs/windows/include/arm64
    INCLUDEPATH += $$PWD/../libs/windows/include
}
VULKAN_SDK_ENV = $$(VULKAN_SDK)
!isEmpty(VULKAN_SDK_ENV) {
    win32: INCLUDEPATH += $$VULKAN_SDK_ENV/Include
    else:  INCLUDEPATH += $$VULKAN_SDK_ENV/include
}

include($$PWD/pyrowave.pri)
