import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string applicationTitle: "MotionPlugin"

    color: "#80000000"
    radius: 5

    Column {
        anchors.centerIn: parent
        spacing: 5

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.applicationTitle
            font.pixelSize: 20
            color: "white"
        }
    }
}
