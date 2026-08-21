QT += core gui qml quick quickcontrols2 concurrent
CONFIG += c++11
TEMPLATE = app
TARGET = meow-os
SOURCES += src/main.cpp src/systembackend.cpp
HEADERS += src/systembackend.h src/version.h
RESOURCES += qml.qrc
INCLUDEPATH += src

unix:!macx {
    QMAKE_CXXFLAGS += -Wall -Wextra -Wno-unused-parameter
}
