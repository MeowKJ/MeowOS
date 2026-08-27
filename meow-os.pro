QT += core gui qml quick quickcontrols2 concurrent
CONFIG += c++11
TEMPLATE = app
TARGET = meow-os
SOURCES += src/main.cpp src/systembackend.cpp \
    src/hal/hal_interfaces.cpp \
    src/runtime/task_scheduler.cpp \
    src/runtime/app_session.cpp
HEADERS += src/systembackend.h src/version.h \
    src/runtime/task_scheduler.h \
    src/runtime/app_session.h \
    src/hal/hal_interfaces.h
RESOURCES += qml.qrc
INCLUDEPATH += src

unix:!macx {
    QMAKE_CXXFLAGS += -Wall -Wextra -Wno-unused-parameter
}
