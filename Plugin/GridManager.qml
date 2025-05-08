import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick.Dialogs
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils
import Qt.labs.platform
import QtCore

QtObject {
    id: root

    property bool gridEnabled: true
    property CameraHelper cameraHelper

    property real cameraDistance: cameraHelper.orbitControllerEnabled ? cameraHelper.orbitCamera.z : cameraHelper.wasdCamera.position.length()
    property real gridInterval: Math.pow(10, Math.round(Math.log10(cameraDistance)) - 1)

    function toggleGrid() {
        gridEnabled = !gridEnabled
    }

}
