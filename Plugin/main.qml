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
            bottomPadding: 30

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

        // Улучшенный анализатор скелета с правильным отображением названий из .glb файла
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
                console.log("=== 🦴 ENHANCED SKELETON ANALYSIS STARTED ===")

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
                        "Source": extractFileName(modelNode.source.toString()),
                        "Full Path": modelNode.source.toString(),
                        "Bounds": modelNode.bounds ? formatBounds(modelNode.bounds) : "N/A",
                        "Analysis Time": new Date().toLocaleTimeString()
                    }

                    console.log("📁 Model loaded successfully:", modelInfo["Source"])

                    // Анализ узлов с улучшенным получением названий
                    traverseNodeEnhanced(modelNode, 0, "RootModel", "")

                    // Обновляем статистику
                    totalNodes = _internalSkeletonData.length
                    nodesWithChildren = _internalSkeletonData.filter(function(item) { return item.hasChildren }).length
                    maxLevel = _internalSkeletonData.length > 0 ?
                              Math.max.apply(Math, _internalSkeletonData.map(function(item) { return item.level })) : 0

                    skeletonNodesCount = _internalSkeletonData.filter(function(node) {
                        return node.isSkeleton || node.isBone || node.hasSkin || node.hasAnimation
                    }).length

                    // Сортируем по иерархии для лучшего отображения
                    _internalSkeletonData.sort(function(a, b) {
                        if (a.level !== b.level) return a.level - b.level
                        return a.hierarchyIndex - b.hierarchyIndex
                    })

                    // Обновляем модель для отображения
                    displayModel = _internalSkeletonData.slice()

                    analyzeSkeletonStructure(modelNode)
                } else {
                    modelInfo = {
                        "Status": "❌ Failed or Not Ready",
                        "Error": modelNode ? modelNode.errorString : "No model provided",
                        "Analysis Time": new Date().toLocaleTimeString()
                    }
                    console.log("❌ Model analysis failed:", modelInfo["Error"])
                }

                console.log("📊 Enhanced analysis complete. Found", totalNodes, "nodes")
                console.log("🦴 Skeleton-related nodes found:", skeletonNodesCount)
                console.log("=== ENHANCED ANALYSIS COMPLETED ===")

                // Принудительно обновляем привязки
                modelInfoChanged()
                displayModelChanged()
                totalNodesChanged()
                skeletonNodesCountChanged()
            }

            function traverseNodeEnhanced(node, level, parentName, hierarchyPath) {
                if (!node) return

                var hierarchyIndex = _internalSkeletonData.length
                var realName = extractRealNodeName(node)
                var nodeType = getEnhancedNodeType(node)
                var fullPath = hierarchyPath ? hierarchyPath + "/" + realName : realName

                var nodeInfo = {
                    "level": level,
                    "name": realName,
                    "displayName": realName,
                    "type": nodeType,
                    "parent": parentName,
                    "hierarchyPath": fullPath,
                    "hierarchyIndex": hierarchyIndex,
                    "hasChildren": false,
                    "childCount": 0,
                    "properties": [],
                    "isSkeleton": false,
                    "isBone": false,
                    "hasSkin": false,
                    "hasAnimation": false,
                    "isGeometry": false,
                    "isMaterial": false
                }

                var indent = "  ".repeat(level)
                console.log(indent + "🔍 Analyzing:", realName, "(" + nodeType + ")")

                // Детальный анализ свойств узла
                analyzeNodePropertiesEnhanced(node, nodeInfo)

                // Определяем иконку для узла
                nodeInfo.icon = getNodeIcon(nodeInfo)

                _internalSkeletonData.push(nodeInfo)

                // Анализ дочерних узлов
                var childCount = analyzeChildrenEnhanced(node, level, realName, fullPath)
                if (childCount > 0) {
                    nodeInfo.hasChildren = true
                    nodeInfo.childCount = childCount
                    nodeInfo.properties.push("👥 Children: " + childCount)
                }

                return hierarchyIndex
            }

            function extractRealNodeName(node) {
                // Пытаемся получить реальное название из различных источников
                var name = ""

                // 1. Проверяем objectName (QML property)
                if (node.objectName && node.objectName !== "") {
                    name = node.objectName
                }
                // 2. Проверяем свойство name
                else if (typeof node.name !== 'undefined' && node.name !== "") {
                    name = node.name
                }
                // 3. Проверяем свойство id
                else if (typeof node.id !== 'undefined' && node.id !== "") {
                    name = node.id
                }
                // 4. Для Joint узлов проверяем joint-специфичные свойства
                else if (node.toString().includes("Joint")) {
                    name = "Joint_" + Math.random().toString(36).substr(2, 4)
                }
                // 5. Для Model узлов пытаемся извлечь название из источника
                else if (node.toString().includes("Model") && typeof node.source !== 'undefined') {
                    var sourceName = extractFileName(node.source.toString())
                    name = sourceName.replace(/\.[^/.]+$/, "") // Убираем расширение
                }
                // 6. Последняя попытка - парсим название из toString()
                else {
                    var nodeString = node.toString()
                    var match = nodeString.match(/(\w+)_\w+\(/)
                    if (match && match[1]) {
                        name = match[1]
                    } else {
                        name = "UnknownNode"
                    }
                }

                return name || "UnnamedNode"
            }

            function getEnhancedNodeType(node) {
                var nodeString = node.toString()

                // Специфичные типы Qt3D/QtQuick3D
                if (nodeString.includes("Joint")) return "Joint"
                if (nodeString.includes("Skeleton")) return "Skeleton"
                if (nodeString.includes("Model")) return "Model"
                if (nodeString.includes("Node")) return "Node"
                if (nodeString.includes("Camera")) return "Camera"
                if (nodeString.includes("Light")) return "Light"
                if (nodeString.includes("Material")) return "Material"
                if (nodeString.includes("Texture")) return "Texture"
                if (nodeString.includes("Geometry")) return "Geometry"
                if (nodeString.includes("Mesh")) return "Mesh"
                if (nodeString.includes("Animation")) return "Animation"

                // Попытка извлечь тип из строкового представления
                var match = nodeString.match(/^(\w+)/)
                return match ? match[1] : "Unknown"
            }

            function analyzeNodePropertiesEnhanced(node, nodeInfo) {
                try {
                    // Основные трансформации
                    if (typeof node.position !== 'undefined') {
                        var pos = node.position
                        if (pos.x !== 0 || pos.y !== 0 || pos.z !== 0) {
                            nodeInfo.properties.push("📍 Position: " + formatVector3D(pos))
                        }
                    }

                    if (typeof node.eulerRotation !== 'undefined') {
                        var rot = node.eulerRotation
                        if (rot.x !== 0 || rot.y !== 0 || rot.z !== 0) {
                            nodeInfo.properties.push("🔄 Rotation: " + formatVector3D(rot))
                        }
                    }

                    if (typeof node.scale !== 'undefined') {
                        var scale = node.scale
                        if (scale.x !== 1 || scale.y !== 1 || scale.z !== 1) {
                            nodeInfo.properties.push("📏 Scale: " + formatVector3D(scale))
                        }
                    }

                    // Skeleton и Bone анализ
                    if (typeof node.skeleton !== 'undefined') {
                        nodeInfo.isSkeleton = true
                        nodeInfo.properties.push("🦴 Skeleton Node")
                        if (node.skeleton && typeof node.skeleton.joints !== 'undefined') {
                            nodeInfo.properties.push("🦴 Joints: " + node.skeleton.joints.length)
                        }
                    }

                    if (node.toString().includes("Joint") || typeof node.joint !== 'undefined') {
                        nodeInfo.isBone = true
                        nodeInfo.properties.push("🦴 Bone/Joint")
                    }

                    // Skin анализ
                    if (typeof node.skin !== 'undefined') {
                        nodeInfo.hasSkin = true
                        nodeInfo.properties.push("👤 Has Skin")
                    }

                    // Animation анализ
                    if (typeof node.animations !== 'undefined' && node.animations.length > 0) {
                        nodeInfo.hasAnimation = true
                        nodeInfo.properties.push("🎬 Animations: " + node.animations.length)
                    }

                    // Geometry анализ
                    if (typeof node.geometry !== 'undefined') {
                        nodeInfo.isGeometry = true
                        nodeInfo.properties.push("📐 Has Geometry")
                    }

                    // Material анализ
                    if (typeof node.materials !== 'undefined' && node.materials.length > 0) {
                        nodeInfo.isMaterial = true
                        nodeInfo.properties.push("🎨 Materials: " + node.materials.length)
                    }

                    // Source файл
                    if (typeof node.source !== 'undefined') {
                        nodeInfo.properties.push("📄 Source: " + extractFileName(node.source.toString()))
                    }

                    // Дополнительные свойства для отладки
                    if (typeof node.visible !== 'undefined' && !node.visible) {
                        nodeInfo.properties.push("👁️ Hidden")
                    }

                    if (typeof node.opacity !== 'undefined' && node.opacity < 1) {
                        nodeInfo.properties.push("🌫️ Opacity: " + node.opacity.toFixed(2))
                    }

                } catch (e) {
                    console.log("⚠️ Error analyzing enhanced properties:", e.toString())
                    nodeInfo.properties.push("⚠️ Analysis Error")
                }
            }

            function analyzeChildrenEnhanced(node, level, nodeName, hierarchyPath) {
                var childCount = 0
                try {
                    if (node.children && node.children.length > 0) {
                        childCount = node.children.length
                        console.log("    👥 Found", childCount, "children for", nodeName)
                        for (var i = 0; i < node.children.length; i++) {
                            traverseNodeEnhanced(node.children[i], level + 1, nodeName, hierarchyPath)
                        }
                    }
                } catch (e) {
                    console.log("    ⚠️ Could not access children for", nodeName, ":", e.toString())
                }

                return childCount
            }

            function analyzeSkeletonStructure(modelNode) {
                console.log("🦴 Analyzing skeleton structure...")

                var skeletonNodes = _internalSkeletonData.filter(function(node) {
                    return node.isSkeleton || node.isBone
                })

                if (skeletonNodes.length > 0) {
                    console.log("🎯 Found skeleton structure with", skeletonNodes.length, "skeleton-related nodes")
                    skeletonNodes.forEach(function(node) {
                        console.log("  - " + node.name + " (" + node.type + ") at level " + node.level)
                    })
                } else {
                    console.log("ℹ️ No explicit skeleton structure found")
                }
            }

            function getNodeIcon(nodeInfo) {
                if (nodeInfo.isSkeleton) return "🦴"
                if (nodeInfo.isBone) return "🦴"
                if (nodeInfo.hasSkin) return "👤"
                if (nodeInfo.hasAnimation) return "🎬"
                if (nodeInfo.isGeometry) return "📐"
                if (nodeInfo.isMaterial) return "🎨"
                if (nodeInfo.type === "Camera") return "📷"
                if (nodeInfo.type === "Light") return "💡"
                if (nodeInfo.hasChildren) return "📁"
                return "📄"
            }

            function extractFileName(path) {
                return path.split('/').pop().split('\\').pop()
            }

            function formatBounds(bounds) {
                try {
                    return "Size: " + formatVector3D(bounds.maximum.minus(bounds.minimum))
                } catch (e) {
                    return bounds.toString()
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

            function exportToConsole() {
                console.log("=== ENHANCED SKELETON ANALYSIS EXPORT ===")
                console.log("Model Info:", JSON.stringify(modelInfo, null, 2))
                console.log("\nHierarchy Tree:")
                _internalSkeletonData.forEach(function(node) {
                    var indent = "  ".repeat(node.level)
                    console.log(indent + node.icon + " " + node.name + " (" + node.type + ")")
                    if (node.properties.length > 0) {
                        node.properties.forEach(function(prop) {
                            console.log(indent + "  └─ " + prop)
                        })
                    }
                })
                console.log("=== END ENHANCED EXPORT ===")
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
