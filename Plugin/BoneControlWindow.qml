import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts

Window {
    id: root
    width: 400
    height: 700
    visible: false
    title: "Bone Control"
    color: "#2a2a2a"

    property alias manipulator: manipulator

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
           Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint

    BoneManipulator {
        id: manipulator
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 15

        Column {
            spacing: 15
            width: root.width - 30

            Text {
                text: "🦴 Bone Control Panel"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }

            // Включение/выключение
            Rectangle {
                width: parent.width
                height: enableRow.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5

                Row {
                    id: enableRow
                    anchors.centerIn: parent
                    spacing: 15

                    Text {
                        text: "Enable Bone Control:"
                        color: "white"
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: 12
                    }

                    Switch {
                        id: enableSwitch
                        checked: manipulator.manipulationEnabled
                        onCheckedChanged: manipulator.enableManipulation(checked)
                    }

                    Text {
                        text: enableSwitch.checked ? "ON" : "OFF"
                        color: enableSwitch.checked ? "#00ff00" : "#ff0000"
                        font.bold: true
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
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
                        text: "• Total Bones: " + manipulator.bonesList.length
                        color: "lightgray"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "• Selected: " + (manipulator.selectedBoneData ? manipulator.selectedBoneData.name : "None")
                        color: manipulator.selectedBoneIndex !== null ? "lightgreen" : "gray"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }
            }

            // Список костей
            Rectangle {
                width: parent.width
                height: Math.min(200, boneListColumn.height + 40)
                color: "#333333"
                border.color: "#666666"
                radius: 5
                visible: enableSwitch.checked

                Column {
                    id: boneListColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 10
                    spacing: 8

                    Text {
                        text: "🗂️ Bone List"
                        color: "yellow"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    ScrollView {
                        width: parent.width
                        height: Math.min(150, boneRepeater.count * 35 + 10)
                        clip: true

                        Column {
                            spacing: 3

                            Repeater {
                                id: boneRepeater
                                model: manipulator.bonesList

                                Rectangle {
                                    width: boneListColumn.width - 20
                                    height: 30
                                    color: manipulator.selectedBoneIndex === modelData.index ? "#4CAF50" :
                                           (boneMouseArea.containsMouse ? "#444444" : "#2a2a2a")
                                    border.color: "#666666"
                                    border.width: 1
                                    radius: 3

                                    Text {
                                        anchors.left: parent.left
                                        anchors.leftMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: manipulator.getBoneDisplayName(modelData)
                                        color: manipulator.selectedBoneIndex === modelData.index ? "white" : "#cccccc"
                                        font.pixelSize: 10
                                        font.bold: manipulator.selectedBoneIndex === modelData.index
                                    }

                                    Text {
                                        anchors.right: parent.right
                                        anchors.rightMargin: 8
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: "#" + modelData.index
                                        color: "#888888"
                                        font.pixelSize: 8
                                    }

                                    MouseArea {
                                        id: boneMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        onClicked: manipulator.selectBone(modelData.index)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Контролы трансформации
            Rectangle {
                width: parent.width
                height: transformColumn.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5
                visible: enableSwitch.checked && manipulator.selectedBoneIndex !== null

                Column {
                    id: transformColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 15
                    spacing: 15

                    Text {
                        text: "🎛️ Transform Controls"
                        color: "cyan"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    // Position
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "📍 Position"
                            color: "#66BB6A"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "X:"; color: "#ff6666"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: posXSlider
                                width: parent.width - 60
                                from: -100; to: 100
                                value: getTransformValue("position", "x")
                                onValueChanged: updatePosition()
                            }
                            Text {
                                text: posXSlider.value.toFixed(1)
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "Y:"; color: "#66ff66"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: posYSlider
                                width: parent.width - 60
                                from: -100; to: 100
                                value: getTransformValue("position", "y")
                                onValueChanged: updatePosition()
                            }
                            Text {
                                text: posYSlider.value.toFixed(1)
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "Z:"; color: "#6666ff"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: posZSlider
                                width: parent.width - 60
                                from: -100; to: 100
                                value: getTransformValue("position", "z")
                                onValueChanged: updatePosition()
                            }
                            Text {
                                text: posZSlider.value.toFixed(1)
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: "#555555" }

                    // Rotation
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "🔄 Rotation (degrees)"
                            color: "#FFB74D"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "X:"; color: "#ff6666"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: rotXSlider
                                width: parent.width - 60
                                from: -180; to: 180
                                value: getTransformValue("rotation", "x")
                                onValueChanged: updateRotation()
                            }
                            Text {
                                text: rotXSlider.value.toFixed(0) + "°"
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "Y:"; color: "#66ff66"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: rotYSlider
                                width: parent.width - 60
                                from: -180; to: 180
                                value: getTransformValue("rotation", "y")
                                onValueChanged: updateRotation()
                            }
                            Text {
                                text: rotYSlider.value.toFixed(0) + "°"
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "Z:"; color: "#6666ff"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: rotZSlider
                                width: parent.width - 60
                                from: -180; to: 180
                                value: getTransformValue("rotation", "z")
                                onValueChanged: updateRotation()
                            }
                            Text {
                                text: rotZSlider.value.toFixed(0) + "°"
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: "#555555" }

                    // Scale
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "📏 Scale"
                            color: "#BA68C8"
                            font.bold: true
                            font.pixelSize: 12
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "X:"; color: "#ff6666"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: scaleXSlider
                                width: parent.width - 60
                                from: 0.1; to: 3.0
                                value: getTransformValue("scale", "x")
                                onValueChanged: updateScale()
                            }
                            Text {
                                text: scaleXSlider.value.toFixed(2)
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "Y:"; color: "#66ff66"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: scaleYSlider
                                width: parent.width - 60
                                from: 0.1; to: 3.0
                                value: getTransformValue("scale", "y")
                                onValueChanged: updateScale()
                            }
                            Text {
                                text: scaleYSlider.value.toFixed(2)
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: 5
                            Text { text: "Z:"; color: "#6666ff"; width: 15; font.pixelSize: 10 }
                            Slider {
                                id: scaleZSlider
                                width: parent.width - 60
                                from: 0.1; to: 3.0
                                value: getTransformValue("scale", "z")
                                onValueChanged: updateScale()
                            }
                            Text {
                                text: scaleZSlider.value.toFixed(2)
                                color: "white"; width: 35; font.pixelSize: 9
                            }
                        }
                    }
                }
            }

            // Кнопки управления
            Row {
                spacing: 10
                visible: enableSwitch.checked

                Button {
                    text: "🔄 Reset Bone"
                    enabled: manipulator.selectedBoneIndex !== null
                    onClicked: {
                        if (manipulator.selectedBoneIndex !== null) {
                            manipulator.resetBone(manipulator.selectedBoneIndex)
                        }
                    }
                    background: Rectangle {
                        color: parent.pressed ? "#664444" : "#442222"
                        border.color: "#777777"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "white" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "🔄 Reset All"
                    onClicked: manipulator.resetAllBones()
                    background: Rectangle {
                        color: parent.pressed ? "#664444" : "#442222"
                        border.color: "#777777"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    text: "💾 Export"
                    onClicked: {
                        var poseData = manipulator.exportPose()
                        console.log("=== EXPORTED POSE ===")
                        console.log(poseData)
                        console.log("=== END POSE ===")
                    }
                    background: Rectangle {
                        color: parent.pressed ? "#446644" : "#224422"
                        border.color: "#777777"
                        radius: 4
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Кнопка закрытия
            Button {
                text: "❌ Close"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: root.visible = false
                background: Rectangle {
                    color: parent.pressed ? "#664444" : "#442222"
                    border.color: "#777777"
                    radius: 4
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }
    }

    // Функции для получения значений трансформации
    function getTransformValue(type, axis) {
        if (manipulator.selectedBoneIndex === null) {
            return type === "scale" ? 1.0 : 0.0
        }

        var transform = manipulator.getBoneTransform(manipulator.selectedBoneIndex)
        if (transform && transform[type] && transform[type][axis] !== undefined) {
            return transform[type][axis]
        }

        return type === "scale" ? 1.0 : 0.0
    }

    function updatePosition() {
        if (manipulator.selectedBoneIndex !== null) {
            manipulator.updateBonePosition(
                manipulator.selectedBoneIndex,
                posXSlider.value,
                posYSlider.value,
                posZSlider.value
            )
        }
    }

    function updateRotation() {
        if (manipulator.selectedBoneIndex !== null) {
            manipulator.updateBoneRotation(
                manipulator.selectedBoneIndex,
                rotXSlider.value,
                rotYSlider.value,
                rotZSlider.value
            )
        }
    }

    function updateScale() {
        if (manipulator.selectedBoneIndex !== null) {
            manipulator.updateBoneScale(
                manipulator.selectedBoneIndex,
                scaleXSlider.value,
                scaleYSlider.value,
                scaleZSlider.value
            )
        }
    }

    // Соединения для обновления интерфейса
    Connections {
        target: manipulator

        function onBoneSelected(boneIndex, boneData) {
            console.log("Bone selected:", boneIndex, boneData ? boneData.name : "none")
        }

        function onBoneTransformChanged(boneIndex, transform) {
            console.log("Transform changed for bone", boneIndex, ":", JSON.stringify(transform))
        }

        function onBonesListUpdated() {
            console.log("Bones list updated, count:", manipulator.bonesList.length)
        }
    }
}
