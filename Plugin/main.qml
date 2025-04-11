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

    Rectangle {
            id: controlPanel
            anchors {
                top: parent.top
                left: parent.left
                right: parent.right
            }
            height: 50
            color: "#80000000"
            z: 10 // Панель поверх всего

            RowLayout {
                anchors {
                    fill: parent
                    margins: 5
                }
                spacing: 10

                Button {
                    id: orbitButton
                    text: "Режим Orbit"
                    Layout.preferredWidth: 120
                    background: Rectangle {
                        color: helper.orbitControllerEnabled ? "#007acc" : "#444444"
                        radius: 4
                    }
                    contentItem: Text {
                        text: orbitButton.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: helper.switchController(true)
                    ToolTip.visible: hovered
                    ToolTip.text: "Переключиться на режим Orbit камеры"
                }

                Button {
                    id: wasdButton
                    text: "Режим WASD"
                    Layout.preferredWidth: 120
                    background: Rectangle {
                        color: !helper.orbitControllerEnabled ? "#007acc" : "#444444"
                        radius: 4
                    }
                    contentItem: Text {
                        text: wasdButton.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    onClicked: helper.switchController(false)
                    ToolTip.visible: hovered
                    ToolTip.text: "Переключиться на режим WASD камеры"
                }

                Button {
                    text: "Сброс вида"
                    Layout.preferredWidth: 120
                    onClicked: helper.resetView()
                    ToolTip.visible: hovered
                    ToolTip.text: "Сбросить положение камеры"
                }

                Button {
                    id: gridButton
                    property bool gridState: helper.gridEnabled
                    text: gridState ? "Скрыть сетку" : "Показать сетку"
                    Layout.preferredWidth: 120
                    onClicked: {
                        helper.gridEnabled = !helper.gridEnabled
                        gridState = helper.gridEnabled // Обновляем локальное свойство для обновления текста
                    }
                    ToolTip.visible: hovered
                    ToolTip.text: "Показать/скрыть вспомогательную сетку"
                }

                Item { Layout.fillWidth: true } // Расширитель

                Label {
                    text: helper.orbitControllerEnabled ? "Текущий режим: Orbit" : "Текущий режим: WASD"
                    color: "white"
                    font.pixelSize: 14
                    Layout.alignment: Qt.AlignRight
                }
            }
        }

    View3D {
        id: view3D
        anchors.fill: parent
        environment: SceneEnvironment {
            clearColor: "#404040"
            backgroundMode: SceneEnvironment.Color
            InfiniteGrid {
                visible: helper.gridEnabled
                gridInterval: 100
            }
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High

        }

        camera: helper.orbitControllerEnabled ? orbitCamera : wasdCamera

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
        enabled: helper.orbitControllerEnabled
    }

    WasdController {
        id: wasdController
        anchors.fill: parent
        controlledObject: wasdCamera
        enabled: !helper.orbitControllerEnabled
        speed: 5.0
        shiftSpeed: 15.0
    }

    QtObject {
            id: helper
            property bool orbitControllerEnabled: true
            property bool gridEnabled: true
            property vector3d boundsCenter: Qt.vector3d(0, 0, 0)
            property real boundsDiameter: 200

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

    Rectangle {
        id: controlsInfo
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
            margins: 10
        }
        height: 40
        color: "#80000000"
        radius: 5

        Column {
            anchors.centerIn: parent
            spacing: 5

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "Motion Plugin"
                font.pixelSize: 20
                color: "white"
            }
        }
    }

    Component.onCompleted: {
        helper.resetView()
    }

}
