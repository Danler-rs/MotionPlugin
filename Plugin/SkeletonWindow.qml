import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 600
    height: 800
    visible: false
    title: "Skeleton Analysis"
    color: "#2a2a2a"

    property alias analyzer: analyzer

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
           Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint

    SkeletonAnalyzer {
        id: analyzer
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 15

        Column {
            spacing: 15
            width: root.width - 30

            Text {
                text: "🦴 Skeleton Analysis Results"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }

            // Статистика
            Rectangle {
                width: parent.width
                height: statsColumn.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5

                Column {
                    id: statsColumn
                    anchors.margins: 10
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.right: parent.right
                    spacing: 8

                    Text {
                        text: "📊 Statistics"
                        color: "lightgreen"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Text {
                        text: "• Total Nodes: " + analyzer.totalNodes
                        color: "lightgray"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "• Skeleton Nodes: " + analyzer.skeletonNodesCount
                        color: "lightgreen"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // Иерархия
            Rectangle {
                width: parent.width
                height: Math.min(400, hierarchyColumn.height + 20)
                color: "#333333"
                border.color: "#666666"
                radius: 5

                Column {
                    id: hierarchyColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "🌳 Scene Hierarchy"
                        color: "yellow"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    ScrollView {
                        width: parent.width
                        height: Math.min(350, contentHeight)
                        clip: true

                        Column {
                            spacing: 3
                            Repeater {
                                model: analyzer.displayModel

                                Rectangle {
                                    width: hierarchyColumn.width - 20
                                    height: nodeColumn.height + 8
                                    color: getNodeColor(modelData.type)
                                    border.color: "#666666"
                                    radius: 3

                                    Column {
                                        id: nodeColumn
                                        anchors.left: parent.left
                                        anchors.margins: 6
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 2

                                        Text {
                                            text: "  ".repeat(modelData.level) +
                                                  getTypeIcon(modelData.type) + " " +
                                                  modelData.name
                                            color: getTextColor(modelData.type)
                                            font.pixelSize: 11
                                            font.bold: modelData.hasChildren || isImportantType(modelData.type)
                                        }

                                        Text {
                                            text: "  ".repeat(modelData.level + 1) +
                                                  "→ " + modelData.type
                                            color: "lightgray"
                                            font.pixelSize: 9
                                            font.italic: true
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Кнопки управления
            Row {
                spacing: 10

                Button {
                    text: "❌ Close"
                    onClicked: root.visible = false
                    background: Rectangle {
                        color: parent.pressed ? "#664444" : "#442222"
                        border.color: "#777777"
                        radius: 4
                    }
                }
            }
        }
    }

    // Функции для стилизации как в Blender
    function getNodeColor(type) {
        switch(type) {
            case "Armature": return "#4a2d1a"
            case "Bone": return "#4a2d1a"
            case "Mesh": return "#1a4a2d"
            case "Camera": return "#1a2d4a"
            case "Light": return "#4a4a1a"
            case "Material": return "#4a1a4a"
            case "Empty": return "#3a3a3a"
            default: return "#2a2a2a"
        }
    }

    function getTextColor(type) {
        switch(type) {
            case "Armature": return "#ffa366"
            case "Bone": return "#ffb366"
            case "Mesh": return "#66ffa3"
            case "Camera": return "#66a3ff"
            case "Light": return "#ffff66"
            case "Material": return "#ff66ff"
            case "Empty": return "yellow"
            default: return "white"
        }
    }

    function getTypeIcon(type) {
        switch(type) {
            case "Armature": return "🦴"
            case "Bone": return "🦴"
            case "Mesh": return "▲"
            case "Camera": return "📷"
            case "Light": return "💡"
            case "Material": return "🎨"
            case "Texture": return "🖼️"
            case "Animation": return "🎬"
            case "Empty": return "📁"
            case "Object": return "🔳"
            default: return "❓"
        }
    }

    function isImportantType(type) {
        return ["Armature", "Bone", "Camera", "Light"].includes(type)
    }
}
