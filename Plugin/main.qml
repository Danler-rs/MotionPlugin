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

Window {
    id: windowRoot
    width: 1200
    height: 800
    visible: true
    title: "Motion Plugin"
    color: "#404040"

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
               Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint | Qt.WindowFullscreenButtonHint

    property url importUrl;

    SkeletonWindow {
        id: skeletonWindow
    }

    BoneControlWindow {
        id: boneControlWindow
    }

    GridManager {
        id: gridManager
        cameraHelper: cameraHelper
    }

    CameraHelper {
        id: cameraHelper
        orbitCameraNode: orbitCameraNode
        orbitCamera: orbitCamera
        wasdCamera: wasdCamera
        wasdController: wasdController
        view3d: view3D
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
        boneManipulator: boneControlWindow.manipulator

        onOrbitModeRequested: cameraHelper.switchController(true)
        onWasdModeRequested: cameraHelper.switchController(false)
        onResetViewRequested: cameraHelper.resetView()
        onToggleGridRequested: gridManager.toggleGrid()
        onImportModelRequested: fileDialog.open()
        onToggleSkeletonRequested: skeletonWindow.visible = !skeletonWindow.visible
        onToggleBoneManipulationRequested: boneControlWindow.visible = !boneControlWindow.visible
    }

    View3D {
        id: view3D
        anchors {
            top: controlPanel.bottom
            left: parent.left
            right: parent.right
            bottom: statusBar.top
        }

        environment: SceneEnvironment {
            clearColor: "#404040"
            backgroundMode: SceneEnvironment.Color
            InfiniteGrid {
                visible: gridManager.gridEnabled
                gridInterval: gridManager.gridInterval
            }
            antialiasingMode: SceneEnvironment.MSAA
            antialiasingQuality: SceneEnvironment.High
        }

        RuntimeLoader {
            id: importNode
            source: windowRoot.importUrl
            onBoundsChanged: cameraHelper.updateBounds(bounds)
            onStatusChanged: {
                if (status === RuntimeLoader.Success) {
                    console.log("Model loaded successfully")
                    skeletonWindow.analyzer.analyzeSkeleton(importNode)

                    // Автоматически настраиваем bone manipulator
                    if (skeletonWindow.analyzer.skeletonNodesCount > 0) {
                        // Небольшая задержка для корректной инициализации
                        boneSetupTimer.start()
                    }
                } else if (status === RuntimeLoader.Error) {
                    console.log("Error loading model:", importNode.errorString)
                }
            }
        }

        // Таймер для настройки bone manipulator
        Timer {
            id: boneSetupTimer
            interval: 500
            repeat: false
            onTriggered: {
                // Передаем анализатор в bone manipulator
                boneControlWindow.manipulator.skeletonAnalyzer = skeletonWindow.analyzer

                // Автоматически открываем окно управления костями
                boneControlWindow.visible = true
                boneControlWindow.manipulator.enableManipulation(true)
            }
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
            eulerRotation.x: -35
            eulerRotation.y: -90
            castsShadow: true
            brightness: 1.0
        }

        // Дополнительное освещение
        PointLight {
            id: pointLight
            position: cameraHelper.orbitControllerEnabled ?
                     orbitCamera.scenePosition :
                     wasdCamera.position
            brightness: 0.3
            castsShadow: false
        }

        Model {
            parent: importNode
            opacity: 0.2
            visible: importNode.status === RuntimeLoader.Success
            position: cameraHelper.boundsCenter
            scale: Qt.vector3d(cameraHelper.boundsSize.x / 100,
                               cameraHelper.boundsSize.y / 100,
                               cameraHelper.boundsSize.z / 100)
        }

        Rectangle {
            id: messageBox
            visible: importNode.status !== RuntimeLoader.Success
            color: "red"
            width: parent.width * 0.8
            height: parent.height * 0.8
            anchors.centerIn: parent
            radius: Math.min(width, height) / 10
            opacity: 0.6
            Text {
                anchors.fill: parent
                font.pixelSize: 36
                text: "Status: " + importNode.errorString + "\nPress \"Import...\" to import a model"
                color: "white"
                wrapMode: Text.Wrap
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    FileDialog {
        id: fileDialog
        title: "Select 3D Model"
        nameFilters: ["glTF files (*.gltf *.glb)", "All files (*)"]
        onAccepted: {
            console.log("Loading model:", currentFile)
            importUrl = currentFile
        }

        Settings {
            id: fileDialogSettings
            category: "QtQuick3D.Examples.RuntimeLoader"
            property alias folder: fileDialog.folder
        }
    }

    OrbitCameraController {
        id: orbitController
        anchors.fill: view3D
        origin: orbitCameraNode
        camera: orbitCamera
        enabled: cameraHelper.orbitControllerEnabled
    }

    WasdController {
        id: wasdController
        anchors.fill: view3D
        controlledObject: wasdCamera
        enabled: !cameraHelper.orbitControllerEnabled
        speed: 5.0
        shiftSpeed: 15.0
    }

    // Статусная строка
    Rectangle {
        id: statusBar
        anchors {
            left: parent.left
            right: parent.right
            bottom: parent.bottom
        }
        height: 30
        color: "#333333"
        border.color: "#666666"
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            spacing: 10

            Text {
                text: getStatusText()
                color: "white"
                font.pixelSize: 11
                Layout.fillWidth: true
            }

            Text {
                text: boneControlWindow.manipulator && boneControlWindow.manipulator.selectedBoneIndex !== null ?
                      "Selected: " + boneControlWindow.manipulator.selectedBoneData.name :
                      "No bone selected"
                color: boneControlWindow.manipulator && boneControlWindow.manipulator.selectedBoneIndex !== null ? "#4CAF50" : "#888888"
                font.pixelSize: 10
            }

            Text {
                text: boneControlWindow.visible ? "🦴 Bone Control: ON" : "🦴 Bone Control: OFF"
                color: boneControlWindow.visible ? "#4CAF50" : "#888888"
                font.pixelSize: 10
                font.bold: true
            }
        }
    }

    Component.onCompleted: {
        console.log("Motion Plugin initialized")
        cameraHelper.resetView()
    }

    function getStatusText() {
        var status = "Ready to load model"

        if (importNode.status === RuntimeLoader.Loading) {
            status = "⏳ Loading model..."
        } else if (importNode.status === RuntimeLoader.Success) {
            var nodeCount = skeletonWindow.analyzer.totalNodes
            var boneCount = skeletonWindow.analyzer.skeletonNodesCount
            status = "✅ Model loaded: " + nodeCount + " nodes, " + boneCount + " bones"
        } else if (importNode.status === RuntimeLoader.Error) {
            status = "❌ Error: " + importNode.errorString
        }

        return status
    }
}
