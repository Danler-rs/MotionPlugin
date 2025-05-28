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
    property bool showSkeletonPanel: false

    // Skeleton Information Window
    Window {
        id: skeletonWindow
        width: 600
        height: 800
        visible: false
        title: "Skeleton Analysis"
        color: "#2a2a2a"

        flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
               Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint

        ScrollView {
            anchors.fill: parent
            anchors.margins: 15
            clip: true

            Column {
                spacing: 15
                width: skeletonWindow.width - 30

                Text {
                    text: "🦴 Skeleton Analysis Results"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 18
                }

                Rectangle {
                    width: parent.width
                    height: 2
                    color: "#555555"
                }

                // Model Info Section
                Rectangle {
                    width: parent.width
                    height: modelInfoColumn.height + 20
                    color: "#333333"
                    border.color: "#666666"
                    border.width: 1
                    radius: 5

                    Column {
                        id: modelInfoColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: "📁 Model Information"
                            color: "lightblue"
                            font.bold: true
                            font.pixelSize: 14
                        }

                        // Используем прямую привязку к свойствам анализатора
                        Text {
                            text: "• Status: " + (skeletonAnalyzer.modelInfo.Status || "N/A")
                            color: "lightgray"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            width: parent.width
                        }

                        Text {
                            text: "• Source: " + (skeletonAnalyzer.modelInfo.Source || "N/A")
                            color: "lightgray"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            width: parent.width
                        }

                        Text {
                            text: "• Analysis Time: " + (skeletonAnalyzer.modelInfo["Analysis Time"] || "N/A")
                            color: "lightgray"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            width: parent.width
                        }

                        Text {
                            text: "• Bounds: " + (skeletonAnalyzer.modelInfo.Bounds || "N/A")
                            color: "lightgray"
                            font.pixelSize: 12
                            wrapMode: Text.Wrap
                            width: parent.width
                        }
                    }
                }

                // Skeleton Statistics
                Rectangle {
                    width: parent.width
                    height: statsColumn.height + 20
                    color: "#333333"
                    border.color: "#666666"
                    border.width: 1
                    radius: 5

                    Column {
                        id: statsColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        Text {
                            text: "📊 Statistics"
                            color: "lightgreen"
                            font.bold: true
                            font.pixelSize: 14
                        }

                        Text {
                            text: "• Total Nodes: " + skeletonAnalyzer.totalNodes
                            color: "lightgray"
                            font.pixelSize: 12
                        }

                        Text {
                            text: "• Nodes with Children: " + skeletonAnalyzer.nodesWithChildren
                            color: "lightgray"
                            font.pixelSize: 12
                        }

                        Text {
                            text: "• Max Hierarchy Level: " + skeletonAnalyzer.maxLevel
                            color: "lightgray"
                            font.pixelSize: 12
                        }

                        Text {
                            text: "• Skeleton Nodes: " + skeletonAnalyzer.skeletonNodesCount
                            color: "lightgreen"
                            font.pixelSize: 12
                            font.bold: true
                        }
                    }
                }

                // Scene Hierarchy Section
                Rectangle {
                    width: parent.width
                    height: Math.min(500, hierarchyColumn.height + 20)
                    color: "#333333"
                    border.color: "#666666"
                    border.width: 1
                    radius: 5

                    Column {
                        id: hierarchyColumn
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.margins: 10
                        spacing: 8

                        Text {
                            text: "🌳 Scene Hierarchy (" + skeletonAnalyzer.totalNodes + " nodes)"
                            color: "yellow"
                            font.bold: true
                            font.pixelSize: 14
                        }

                        ScrollView {
                            width: parent.width
                            height: Math.min(450, contentHeight)
                            clip: true

                            Column {
                                spacing: 3
                                width: parent.width

                                Repeater {
                                    model: skeletonAnalyzer.displayModel

                                    Rectangle {
                                        width: hierarchyColumn.width - 20
                                        height: nodeDetailColumn.height + 8
                                        color: modelData.hasChildren ? "#4a4a4a" : "#3a3a3a"
                                        border.color: modelData.hasChildren ? "#888888" : "#666666"
                                        border.width: 1
                                        radius: 3

                                        Column {
                                            id: nodeDetailColumn
                                            anchors.left: parent.left
                                            anchors.right: parent.right
                                            anchors.margins: 6
                                            spacing: 2

                                            Text {
                                                text: "  ".repeat(modelData.level) + (modelData.hasChildren ? "📁 " : "📄 ") + modelData.name
                                                color: modelData.hasChildren ? "yellow" : "white"
                                                font.pixelSize: 11
                                                font.bold: modelData.hasChildren
                                                wrapMode: Text.Wrap
                                                width: parent.width
                                            }

                                            Text {
                                                text: "  ".repeat(modelData.level + 1) + "Type: " + modelData.type
                                                color: "lightgray"
                                                font.pixelSize: 10
                                                wrapMode: Text.Wrap
                                                width: parent.width
                                            }

                                            Repeater {
                                                model: modelData.properties

                                                Text {
                                                    text: "  ".repeat(modelData.level + 1) + "• " + modelData
                                                    color: {
                                                        if (modelData.indexOf("Skeleton") >= 0 ||
                                                            modelData.indexOf("Bones") >= 0 ||
                                                            modelData.indexOf("Skin") >= 0) {
                                                            return "lightgreen"
                                                        }
                                                        return "lightblue"
                                                    }
                                                    font.pixelSize: 10
                                                    font.bold: modelData.indexOf("Skeleton") >= 0 ||
                                                              modelData.indexOf("Bones") >= 0 ||
                                                              modelData.indexOf("Skin") >= 0
                                                    wrapMode: Text.Wrap
                                                    width: parent.width
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Control buttons
                Row {
                    spacing: 10

                    Button {
                        text: "🔄 Refresh Analysis"
                        onClicked: {
                            if (importNode.status === RuntimeLoader.Success) {
                                skeletonAnalyzer.analyzeSkeleton(importNode)
                            }
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#555555" : (parent.hovered ? "#444444" : "#333333")
                            border.color: "#777777"
                            border.width: 1
                            radius: 4
                        }
                    }

                    Button {
                        text: "💾 Export to Console"
                        onClicked: {
                            skeletonAnalyzer.exportToConsole()
                        }
                        background: Rectangle {
                            color: parent.pressed ? "#555555" : (parent.hovered ? "#444444" : "#333333")
                            border.color: "#777777"
                            border.width: 1
                            radius: 4
                        }
                    }

                    Button {
                        text: "❌ Close"
                        onClicked: skeletonWindow.visible = false
                        background: Rectangle {
                            color: parent.pressed ? "#664444" : (parent.hovered ? "#553333" : "#442222")
                            border.color: "#777777"
                            border.width: 1
                            radius: 4
                        }
                    }
                }
            }
        }
    }

    GridManager {
        id: gridManager
        cameraHelper: cameraHelper
    }

    // Skeleton Information Panel (боковая панель)
    Rectangle {
        id: skeletonPanel
        visible: windowRoot.showSkeletonPanel
        width: 400
        height: parent.height - controlPanel.height
        anchors.right: parent.right
        anchors.top: controlPanel.bottom
        color: "#2a2a2a"
        border.color: "#555555"
        border.width: 1

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 10

            Text {
                text: "Skeleton Analysis"
                color: "white"
                font.bold: true
                font.pixelSize: 16
            }

            Rectangle {
                width: parent.width - 20
                height: 1
                color: "#555555"
            }

            Text {
                text: "Total Nodes: " + skeletonAnalyzer.totalNodes
                color: "lightgreen"
                font.pixelSize: 12
            }

            Text {
                text: "Skeleton Nodes: " + skeletonAnalyzer.skeletonNodesCount
                color: "lightgreen"
                font.pixelSize: 12
                font.bold: true
            }

            ScrollView {
                width: parent.width - 20
                height: Math.min(300, contentHeight)
                clip: true

                Column {
                    spacing: 5

                    Repeater {
                        model: skeletonAnalyzer.displayModel

                        Rectangle {
                            width: skeletonPanel.width - 40
                            height: nodeColumn.height + 10
                            color: modelData.hasChildren ? "#3a3a3a" : "transparent"
                            border.color: modelData.hasChildren ? "#666666" : "transparent"
                            border.width: 1
                            radius: 3

                            Column {
                                id: nodeColumn
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.margins: 5
                                spacing: 2

                                Text {
                                    text: "  ".repeat(modelData.level) + "└─ " + modelData.name
                                    color: modelData.hasChildren ? "yellow" : "white"
                                    font.pixelSize: 11
                                    font.bold: modelData.hasChildren
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                }

                                Text {
                                    text: "  ".repeat(modelData.level + 1) + "Type: " + modelData.type
                                    color: "lightgray"
                                    font.pixelSize: 10
                                    wrapMode: Text.Wrap
                                    width: parent.width
                                }
                            }
                        }
                    }
                }
            }

            Button {
                text: "Refresh Analysis"
                onClicked: {
                    if (importNode.status === RuntimeLoader.Success) {
                        skeletonAnalyzer.analyzeSkeleton(importNode)
                    }
                }
            }

            Button {
                text: "Close Panel"
                onClicked: windowRoot.showSkeletonPanel = false
            }
        }
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

        onOrbitModeRequested: cameraHelper.switchController(true)
        onWasdModeRequested: cameraHelper.switchController(false)
        onResetViewRequested: cameraHelper.resetView()
        onToggleGridRequested: gridManager.toggleGrid()
        onImportModelRequested: fileDialog.open()
        onToggleSkeletonRequested: skeletonWindow.visible = !skeletonWindow.visible
    }

    View3D {
        id: view3D
        anchors.fill: parent
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
                    skeletonAnalyzer.analyzeSkeleton(importNode)
                }
            }
        }

        // Улучшенный анализатор скелета с правильной привязкой данных
        QtObject {
            id: skeletonAnalyzer

            // Основные свойства для привязки данных
            property var modelInfo: ({})
            property var displayModel: []
            property int totalNodes: 0
            property int nodesWithChildren: 0
            property int maxLevel: 0
            property int skeletonNodesCount: 0

            // Внутренние данные
            property var _internalSkeletonData: []

            function analyzeSkeleton(modelNode) {
                console.log("=== 🦴 SKELETON ANALYSIS STARTED ===")

                // Сброс данных
                _internalSkeletonData = []
                displayModel = []
                totalNodes = 0
                nodesWithChildren = 0
                maxLevel = 0
                skeletonNodesCount = 0
                modelInfo = {}

                if (modelNode && modelNode.status === RuntimeLoader.Success) {
                    modelInfo = {
                        "Status": "✅ Success",
                        "Source": modelNode.source.toString().split('/').pop(),
                        "Full Path": modelNode.source.toString(),
                        "Bounds": modelNode.bounds ? modelNode.bounds.toString() : "N/A",
                        "Analysis Time": new Date().toLocaleTimeString()
                    }

                    console.log("📁 Model loaded successfully:", modelInfo["Source"])

                    // Анализ узлов
                    traverseNode(modelNode, 0, "root")

                    // Обновляем статистику
                    totalNodes = _internalSkeletonData.length
                    nodesWithChildren = _internalSkeletonData.filter(function(item) { return item.hasChildren }).length
                    maxLevel = _internalSkeletonData.length > 0 ?
                              Math.max.apply(Math, _internalSkeletonData.map(function(item) { return item.level })) : 0

                    skeletonNodesCount = _internalSkeletonData.filter(function(node) {
                        return node.properties.some(function(prop) {
                            return prop.toLowerCase().includes("skeleton") ||
                                   prop.toLowerCase().includes("bone") ||
                                   prop.toLowerCase().includes("skin")
                        })
                    }).length

                    // Обновляем модель для отображения
                    displayModel = _internalSkeletonData.slice() // Создаем копию массива

                    analyzeForAnimation(modelNode)
                } else {
                    modelInfo = {
                        "Status": "❌ Failed or Not Ready",
                        "Error": modelNode ? modelNode.errorString : "No model provided",
                        "Analysis Time": new Date().toLocaleTimeString()
                    }
                    console.log("❌ Model analysis failed:", modelInfo["Error"])
                }

                console.log("📊 Analysis complete. Found", totalNodes, "nodes")
                console.log("🦴 Skeleton nodes found:", skeletonNodesCount)
                console.log("=== ANALYSIS COMPLETED ===")

                // Принудительно обновляем привязки
                modelInfoChanged()
                displayModelChanged()
                totalNodesChanged()
                skeletonNodesCountChanged()
            }

            function exportToConsole() {
                console.log("=== SKELETON ANALYSIS EXPORT ===")
                console.log("Model Info:", JSON.stringify(modelInfo, null, 2))
                console.log("Skeleton Data:", JSON.stringify(_internalSkeletonData, null, 2))
                console.log("=== END EXPORT ===")
            }

            function traverseNode(node, level, parentName) {
                if (!node) return

                var indent = "  ".repeat(level)
                var nodeInfo = {
                    "level": level,
                    "name": getNodeName(node, level),
                    "type": getNodeType(node),
                    "parent": parentName,
                    "hasChildren": false,
                    "properties": []
                }

                console.log(indent + "🔍 Analyzing node:", nodeInfo.name, "Type:", nodeInfo.type)

                // Анализ свойств узла
                analyzeNodeProperties(node, nodeInfo)

                _internalSkeletonData.push(nodeInfo)

                // Анализ дочерних узлов
                var childCount = analyzeChildren(node, level, nodeInfo.name)
                if (childCount > 0) {
                    nodeInfo.hasChildren = true
                    nodeInfo.properties.push("👥 Children: " + childCount)
                }
            }

            function getNodeName(node, level) {
                if (node.objectName && node.objectName !== "") {
                    return node.objectName
                }

                if (typeof node.name !== 'undefined' && node.name !== "") {
                    return node.name
                }

                return "Node_Level_" + level + "_" + Math.random().toString(36).substr(2, 5)
            }

            function getNodeType(node) {
                var typeStr = node.toString()
                if (typeStr.includes("(")) {
                    return typeStr.split("(")[0]
                }
                return "Unknown"
            }

            function analyzeNodeProperties(node, nodeInfo) {
                try {
                    // Position analysis
                    if (typeof node.position !== 'undefined') {
                        nodeInfo.properties.push("📍 Position: " + formatVector3D(node.position))
                    }

                    // Rotation analysis
                    if (typeof node.eulerRotation !== 'undefined') {
                        nodeInfo.properties.push("🔄 Rotation: " + formatVector3D(node.eulerRotation))
                    }

                    // Scale analysis
                    if (typeof node.scale !== 'undefined') {
                        nodeInfo.properties.push("📏 Scale: " + formatVector3D(node.scale))
                    }

                    // Skeleton-specific properties
                    if (typeof node.skeleton !== 'undefined') {
                        nodeInfo.properties.push("🦴 Has Skeleton: YES")
                        console.log("    🎯 SKELETON FOUND!")
                        if (node.skeleton && node.skeleton.joints) {
                            nodeInfo.properties.push("🦴 Joints Count: " + node.skeleton.joints.length)
                            console.log("    🦴 Joints:", node.skeleton.joints.length)
                        }
                    }

                    // Bones analysis
                    if (typeof node.bones !== 'undefined') {
                        nodeInfo.properties.push("🦴 Has Bones: YES")
                        console.log("    🎯 BONES FOUND!")
                    }

                    // Skin analysis
                    if (typeof node.skin !== 'undefined') {
                        nodeInfo.properties.push("🦴 Has Skin: YES")
                        console.log("    🎯 SKIN FOUND!")
                    }

                    // Animation analysis
                    if (typeof node.animations !== 'undefined') {
                        nodeInfo.properties.push("🎬 Has Animations: YES")
                        console.log("    🎯 ANIMATIONS FOUND!")
                    }

                    // Material analysis
                    if (typeof node.materials !== 'undefined') {
                        nodeInfo.properties.push("🎨 Has Materials: YES")
                    }

                    // Geometry analysis
                    if (typeof node.geometry !== 'undefined') {
                        nodeInfo.properties.push("📐 Has Geometry: YES")
                    }

                    // Source analysis
                    if (typeof node.source !== 'undefined') {
                        nodeInfo.properties.push("📄 Source: " + node.source.toString().split('/').pop())
                    }

                } catch (e) {
                    console.log("    ⚠️ Error analyzing properties:", e.toString())
                    nodeInfo.properties.push("⚠️ Analysis Error: " + e.toString())
                }
            }

            function analyzeChildren(node, level, nodeName) {
                var childCount = 0
                try {
                    if (node.children && node.children.length > 0) {
                        childCount = node.children.length
                        console.log("    👥 Found", childCount, "children")
                        for (var i = 0; i < node.children.length; i++) {
                            traverseNode(node.children[i], level + 1, nodeName)
                        }
                    }

                    if (childCount === 0 && typeof node.childNodes !== 'undefined') {
                        console.log("    🔍 Trying childNodes...")
                    }

                } catch (e) {
                    console.log("    ⚠️ Could not access children:", e.toString())
                }

                return childCount
            }

            function analyzeForAnimation(modelNode) {
                console.log("🎬 Checking for animation capabilities...")
                try {
                    if (typeof modelNode.animations !== 'undefined') {
                        console.log("🎯 Model has animations property")
                    }
                } catch (e) {
                    console.log("⚠️ Animation analysis error:", e.toString())
                }
            }

            function formatVector3D(vec) {
                if (!vec) return "N/A"
                try {
                    return "(" + vec.x.toFixed(2) + ", " + vec.y.toFixed(2) + ", " + vec.z.toFixed(2) + ")"
                } catch (e) {
                    return "Invalid Vector"
                }
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
        nameFilters: ["gITF files (*.gITF *.glb)", "All files (*)"]
        onAccepted: importUrl = file
        Settings {
            id: fileDialogSettings
            category: "QtQuick3D.Examples.RuntimeLoader"
            property alias folder: fileDialog.folder
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
