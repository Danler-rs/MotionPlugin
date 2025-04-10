import QtQuick
import QtQuick.Window

Window {
    width: 400
    height: 300
    visible: true
    title: "Плагин QML"

    Rectangle {
        anchors.fill: parent
        color: "lightblue"

        Text {
            anchors.centerIn: parent
            text: "Привет из плагина!"
            font.pixelSize: 24
        }
    }
}
