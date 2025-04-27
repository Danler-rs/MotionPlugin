import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers

Window {
    width: 1200
    height: 800
    visible: true
    title: "Motion Plugin"
    color: "#404040"

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
               Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint | Qt.WindowFullscreenButtonHint

    // Создаем отдельный объект для управления сеткой
    GridManager {
        id: gridManager
    }

    CameraHelper {
        id: cameraHelper
        orbitCameraNode: orbitCameraNode
        orbitCamera: orbitCamera
        wasdCamera: wasdCamera
        wasdController: wasdController
    }

    ControlPanelUI {
        id: controlPanel
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
        }
        cameraHelper: cameraHelper
        gridManager: gridManager

        onOrbitModeRequested: cameraHelper.switchController(true)
        onWasdModeRequested: cameraHelper.switchController(false)
        onResetViewRequested: cameraHelper.resetView()
        onToggleGridRequested: gridManager.toggleGrid()
    }

    View3D {
        id: view3D
        anchors.fill: parent
        environment: SceneEnvironment {
            clearColor: "#404040"
            backgroundMode: SceneEnvironment.Color
            InfiniteGrid {
                visible: gridManager.gridEnabled
                gridInterval: 100
            }
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High

        }

        camera: cameraHelper.orbitControllerEnabled ? orbitCamera : wasdCamera

        Node {
            id: orbitCameraNode
            position: Qt.vector3d(0, 0, 0)

            PerspectiveCamera {
                id: orbitCamera
                position: Qt.vector3d(0, 200, 300)
                clipFar: 1000
                clipNear: 1
                fieldOfView: 45
            }
        }

        PerspectiveCamera {
            id: wasdCamera
            clipFar: 1000
            clipNear: 1
            fieldOfView: 45

            onPositionChanged: {
                let distance = position.length()
                if (distance < 1) {
                    clipFar = 100
                    clipNear = 0.01
                } else if (distance < 100) {
                    clipNear = 0.1
                    clipFar = 100
                } else {
                    clipNear = 1
                    clipFar = 10000
                }
            }
        }

        DirectionalLight {
            id: directionalLight
            color: Qt.rgba(0.8, 0.8, 0.8, 1.0)
            ambientColor: Qt.rgba(0.1, 0.1, 0.1, 1.0)
            position: Qt.vector3d(0, 200, 0)
            rotation: Qt.quaternion(0.707, 0.707, 0, 0)
            castsShadow: true
            shadowMapQuality: Light.ShadowMapQualityHigh
        }

        Model {
            id: cubeModel
            source: "#Cube"
            scale: Qt.vector3d(1.5, 1.5, 1.5)
            eulerRotation.y: 45
            materials: [
                DefaultMaterial {
                    diffuseColor: "#4080ff"
                    specularAmount: 0.5
                }
            ]

            SequentialAnimation on eulerRotation {
                loops: Animation.Infinite
                PropertyAnimation {
                    duration: 5000
                    from: Qt.vector3d(0, 0, 0)
                    to: Qt.vector3d(360, 360, 0)
                }
            }
        }

        Model {
            id: sphereModel
            source: "#Sphere"
            scale: Qt.vector3d(1.2, 1.2, 1.2)
            position: Qt.vector3d(100, 0, 0)
            materials: [
                DefaultMaterial {
                    diffuseColor: "#ff4040"
                    specularAmount: 0.7
                }
            ]

            SequentialAnimation on position.y {
                loops: Animation.Infinite
                PropertyAnimation {
                    duration: 2000
                    from: 0
                    to: 50
                    easing.type: Easing.InOutQuad
                }
                PropertyAnimation {
                    duration: 2000
                    from: 50
                    to: 0
                    easing.type: Easing.InOutQuad
                }
            }
        }

        Model {
            id: cylinderModel
            source: "#Cylinder"
            position: Qt.vector3d(0, 0, -100)
            scale: Qt.vector3d(1.0, 2.0, 1.0)
            materials: [
                DefaultMaterial {
                    diffuseColor: "#40ff40"
                    specularAmount: 0.5
                }
            ]

            SequentialAnimation on eulerRotation.x {
                loops: Animation.Infinite
                PropertyAnimation {
                    duration: 3000
                    from: 0
                    to: 360
                }
            }
        }

    }

    OrbitCameraController {
        id: orbitController
        anchors.fill: parent
        origin: orbitCameraNode
        camera: orbitCamera
        enabled: cameraHelper.orbitControllerEnabled
    }

    WasdController {
        id: wasdController
        anchors.fill: parent
        controlledObject: wasdCamera
        enabled: !cameraHelper.orbitControllerEnabled
        speed: 5.0
        shiftSpeed: 15.0
    }

    InfoPanel {
        id: controlsInfo
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        height: 40
        applicationTitle: "Motion Plugin"
    }

    Component.onCompleted: {
        cameraHelper.resetView()
    }
}
