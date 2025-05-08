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

    // Публичные свойства
    property bool orbitControllerEnabled: true
    property vector3d boundsCenter
    property vector3d boundsSize
    property real boundsDiameter: 0

    // Внешние ссылки на объекты сцены - нужно будет установить из основного файла
    property Node orbitCameraNode
    property PerspectiveCamera orbitCamera
    property PerspectiveCamera wasdCamera
    property Item wasdController
    property View3D view3d

    function updateBounds(bounds) {
        boundsSize = Qt.vector3d(bounds.maximum.x - bounds.minimum.x,
                                 bounds.maximum.y - bounds.minimum.y,
                                 bounds.maximum.z - bounds.minimum.z)
        boundsDiameter = Math.max(boundsSize.x, boundsSize.y, boundsSize.z)
        boundsCenter = Qt.vector3d((bounds.maximum.x + bounds.minimum.x) / 2,
                                   (bounds.maximum.y + bounds.minimum.y) / 2,
                                   (bounds.maximum.z + bounds.minimum.z) / 2 )

        wasdController.speed = boundsDiameter / 1000.0
        wasdController.shiftSpeed = 3 * wasdController.speed
        wasdCamera.clipNear = boundsDiameter / 100
        wasdCamera.clipFar = boundsDiameter * 10
        view3D.resetView()
    }

    function switchController(useOrbitController) {
        if (useOrbitController) {
            let wasdOffset = wasdCamera.position.minus(boundsCenter)
            let wasdDistance = wasdOffset.length()
            let wasdDistanceInPlane = Qt.vector3d(wasdOffset.x, 0, wasdOffset.z).length()
            let yAngle = Math.atan2(wasdOffset.x, wasdOffset.z) * 180 / Math.PI
            let xAngle = -Math.atan2(wasdOffset.y, wasdDistanceInPlane) * 180 / Math.PI

            orbitCameraNode.position = boundsCenter
            orbitCameraNode.eulerRotation = Qt.vector3d(xAngle, yAngle, 0)
            orbitCamera.position = Qt.vector3d(0, 0, wasdDistance)
            orbitCamera.eulerRotation = Qt.vector3d(0, 0, 0)
        } else {
            wasdCamera.position = orbitCamera.scenePosition
            wasdCamera.rotation = orbitCamera.sceneRotation
            wasdController.focus = true
        }
        orbitControllerEnabled = useOrbitController
    }

    function resetView() {
        orbitCameraNode.eulerRotation = Qt.vector3d(-15, 0, 0)
        orbitCameraNode.position = boundsCenter
        orbitCamera.position = Qt.vector3d(0, 0, 400)
        orbitCamera.eulerRotation = Qt.vector3d(0, 0, 0)
        orbitControllerEnabled = true
    }
}
