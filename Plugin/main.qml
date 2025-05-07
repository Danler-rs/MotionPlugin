//main.qml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Helpers
import QtQuick.Dialogs
import MotionPlugin 1.0

Window {
    width: 1200
    height: 800
    visible: true
    title: "Motion Plugin"
    color: "#404040"

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
               Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint | Qt.WindowFullscreenButtonHint

    FileDialog {
            id: modelFileDialog
            title: "Выберите 3D модель"
            nameFilters: ["3D модели (*.obj *.dae *.fbx *.stl *.ply *.gltf *.glb)"]
            onAccepted: {
                statusText.text = "Загрузка модели..."
                statusText.visible = true
                // Используем modelImporter для обработки модели
                modelImporter.processModel(selectedFile, tempDirectory)
            }
    }
    // Свойство для хранения пути к выбранному файлу
    property url selectedFile
    // Свойство для временного каталога (можно настроить)
    property string tempDirectory: StandardPaths.writableLocation(StandardPaths.TempLocation)
    // Статус текущей модели
    property string currentModelPath: "#Cube"

    QtObject {
        id: standardPaths
        function writableLocation(location) {
            // Возвращаем директорию Documents пользователя как временную
            return "file:///" + Qt.application.path + "/temp/"
        }
        readonly property int TempLocation: 0
    }

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

    Connections {
        target: modelImporter

        function onModelProcessed(filePath) {
            console.log("Model processed successfully:", filePath)
            currentModelPath = filePath
            model3D.loadModel(filePath)
            statusText.text = "Модель загружена успешно"
            statusText.color = "lightgreen"
            statusTimer.start()
        }

        function onProcessingError(errorMessage) {
            console.error("Model processing error:", errorMessage)
            statusText.text = "Ошибка: " + errorMessage
            statusText.color = "red"
            statusTimer.start()
        }
    }

    // Скрываем статус через некоторое время
    Timer {
        id: statusTimer
        interval: 5000
        onTriggered: statusText.visible = false
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
        onLoadModelRequested: {
            modelFileDialog.open()
        }
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

        Model3D {
            id: model3D
            source: currentModelPath
            gridEnabled: gridManager.gridEnabled
            axisEnabled: true

            onModelLoaded: function(modelSource) {
                console.log("Model loaded in view:", modelSource)
            }
        }
    }

    Rectangle {
        id: statusBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 25
        color: "#333333"

        Text {
            id: statusText
            anchors {
                verticalCenter: parent.verticalCenter
                left: parent.left
                leftMargin: 10
            }
            color: "white"
            font.pixelSize: 12
            text: "Готово"
            visible: false
        }

        Text {
            anchors {
                verticalCenter: parent.verticalCenter
                right: parent.right
                rightMargin: 10
            }
            color: "white"
            font.pixelSize: 12
            text: "Текущая модель: " + (currentModelPath === "#Cube" ? "Стандартный куб" : currentModelPath.split('/').pop())
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

    Component.onCompleted: {
        cameraHelper.resetView()
    }
}
