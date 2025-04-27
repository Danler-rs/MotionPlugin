import QtQuick
import QtQuick3D

QtObject {
    id: root

    // Публичные свойства
    property bool orbitControllerEnabled: true
    property vector3d boundsCenter: Qt.vector3d(0, 0, 0)
    property real boundsDiameter: 200

    // Внешние ссылки на объекты сцены - нужно будет установить из основного файла
    property Node orbitCameraNode
    property PerspectiveCamera orbitCamera
    property PerspectiveCamera wasdCamera
    property Item wasdController

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
