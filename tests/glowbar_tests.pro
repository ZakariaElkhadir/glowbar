QT += core gui quick quickcontrols2 testlib bluetooth
CONFIG += c++17 testcase
TARGET = glowbar_tests
TEMPLATE = app

INCLUDEPATH += ../src

HEADERS += ../src/backend.h ../src/stripprotocol.h ../src/ledbleprotocol.h ../src/theme.h ../src/translator.h
SOURCES += glowbar_tests.cpp ../src/backend.cpp ../src/stripprotocol.cpp ../src/ledbleprotocol.cpp ../src/theme.cpp ../src/translator.cpp
RESOURCES += ../src/resources.qrc
