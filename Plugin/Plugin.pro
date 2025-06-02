QT += gui qml quick quick3d opengl widgets

TEMPLATE = lib
CONFIG += plugin

CONFIG += c++17

# You can make your code fail to compile if it uses deprecated APIs.
# In order to do so, uncomment the following line.
#DEFINES += QT_DISABLE_DEPRECATED_BEFORE=0x060000    # disables all the APIs deprecated before Qt 6.0.0

TARGET = plugin

CONFIG(debug, debug|release) {
    DESTDIR = $$OUT_PWD/../ConsoleApp/debug/plugins
} else {
    DESTDIR = $$OUT_PWD/../ConsoleApp/release/plugins
}


SOURCES += \
    motionplugin.cpp

HEADERS += \
    motionplugin.h \
    ../common/pluginInterface.h

DISTFILES += Plugin.json \
    BoneControlWindow.qml \
    BoneManipulator.qml \
    CameraHelper.qml \
    ControlPanelUI.qml \
    GridManager.qml \
    KeyFrameManager.qml \
    SkeletonAnalyzer.qml \
    SkeletonWindow.qml \
    TimeLineView.qml \
    main.qml

INCLUDEPATH += ../common

# Default rules for deployment.
unix {
    target.path = $$[QT_INSTALL_PLUGINS]/generic
}
!isEmpty(target.path): INSTALLS += target

RESOURCES += \
    qml.qrc
