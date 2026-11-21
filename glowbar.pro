QT += core gui qml quick quickcontrols2 bluetooth

CONFIG += c++17 release
TARGET = glowbar
TEMPLATE = app

HEADERS += \
    src/backend.h \
    src/stripprotocol.h \
    src/ledbleprotocol.h \
    src/theme.h \
    src/translator.h

SOURCES += \
    src/main.cpp \
    src/backend.cpp \
    src/stripprotocol.cpp \
    src/ledbleprotocol.cpp \
    src/theme.cpp \
    src/translator.cpp

RESOURCES += src/resources.qrc

macx {
    QMAKE_INFO_PLIST = macos/Info.plist
    ICON = macos/glowbar.icns
    # Required by macOS for Bluetooth access.
    QMAKE_POST_LINK += macdeployqt $${TARGET}.app
}
