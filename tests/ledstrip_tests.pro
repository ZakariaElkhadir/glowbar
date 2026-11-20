QT += core gui quick quickcontrols2 testlib bluetooth
CONFIG += c++17 testcase
TARGET = ledstrip_tests
TEMPLATE = app

INCLUDEPATH += ../src

HEADERS += ../src/backend.h ../src/protocol.h ../src/theme.h ../src/translator.h
SOURCES += ledstrip_tests.cpp ../src/backend.cpp ../src/protocol.cpp ../src/theme.cpp ../src/translator.cpp
RESOURCES += ../src/resources.qrc
