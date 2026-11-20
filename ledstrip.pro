QT += core gui qml quick quickcontrols2 bluetooth

CONFIG += c++17 release
TARGET = ledstrip
TEMPLATE = app

HEADERS += \
    src/backend.h \
    src/protocol.h \
    src/theme.h \
    src/translator.h

SOURCES += \
    src/main.cpp \
    src/backend.cpp \
    src/protocol.cpp \
    src/theme.cpp \
    src/translator.cpp

RESOURCES += src/resources.qrc
