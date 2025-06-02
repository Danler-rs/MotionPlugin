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

Rectangle {
    id: root

    // Публичные свойства
    property var cameraHelper
    property var gridManager
    property var boneManipulator
    property var keyframeManager

    color: "#80000000"
    height: 50
    z: 10 // Панель поверх всего

    // Сигналы для обработки событий кнопок
    signal orbitModeRequested()
    signal wasdModeRequested()
    signal resetViewRequested()
    signal toggleGridRequested()
    signal importModelRequested()
    signal toggleSkeletonRequested()
    signal toggleBoneManipulationRequested()
    signal exportKeyframesRequested()

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
                color: cameraHelper.orbitControllerEnabled ? "#007acc" : "#444444"
                radius: 4
            }
            contentItem: Text {
                text: orbitButton.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: orbitModeRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Переключиться на режим Orbit камеры"
        }

        Button {
            id: wasdButton
            text: "Режим WASD"
            Layout.preferredWidth: 120
            background: Rectangle {
                color: !cameraHelper.orbitControllerEnabled ? "#007acc" : "#444444"
                radius: 4
            }
            contentItem: Text {
                text: wasdButton.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: wasdModeRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Переключиться на режим WASD камеры"
        }

        Button {
            text: "Сброс вида"
            Layout.preferredWidth: 120
            onClicked: resetViewRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Сбросить положение камеры"
        }

        Button {
            id: gridButton
            property bool gridState: gridManager.gridEnabled
            text: gridState ? "Скрыть сетку" : "Показать сетку"
            Layout.preferredWidth: 120
            onClicked: {
                toggleGridRequested()
                gridState = gridManager.gridEnabled // Обновляем локальное свойство для обновления текста
            }
            ToolTip.visible: hovered
            ToolTip.text: "Показать/скрыть вспомогательную сетку"
        }

        Button {
            text: "Загрузить модель"
            Layout.preferredWidth: 120
            onClicked: importModelRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Загрузить 3D модель (glTF, GLB)"
        }

        Button {
            text: "Skeleton Analysis"
            Layout.preferredWidth: 120
            onClicked: toggleSkeletonRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Открыть окно анализа скелета"
        }

        Button {
            id: boneManipulationButton
            text: "🦴 Bone Control"
            Layout.preferredWidth: 120
            background: Rectangle {
                color: (boneManipulator && boneManipulator.manipulationEnabled) ? "#007acc" : "#444444"
                radius: 4
            }
            contentItem: Text {
                text: boneManipulationButton.text
                color: "white"
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
            onClicked: toggleBoneManipulationRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Открыть окно управления костями"
        }

        Button {
            text: "💾 Export Keyframes"
            Layout.preferredWidth: 140
            onClicked: exportKeyframesRequested()
            ToolTip.visible: hovered
            ToolTip.text: "Экспорт всех ключевых кадров в консоль"
        }

        Item { Layout.fillWidth: true } // Расширитель

        // Индикаторы состояния
        Column {
            Layout.alignment: Qt.AlignRight
            spacing: 2

            Label {
                text: cameraHelper.orbitControllerEnabled ? "Режим: Orbit" : "Режим: WASD"
                color: "white"
                font.pixelSize: 12
                horizontalAlignment: Text.AlignRight
            }

            Label {
                text: (boneManipulator && boneManipulator.manipulationEnabled) ?
                      "🦴 Bone Control: ON" :
                      "🦴 Bone Control: OFF"
                color: (boneManipulator && boneManipulator.manipulationEnabled) ? "#00ff00" : "#888888"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
            }

            Label {
                text: keyframeManager ?
                      ("🎬 Keyframes: " + keyframeManager.getAllKeyframes().length) :
                      "🎬 Keyframes: 0"
                color: (keyframeManager && keyframeManager.getAllKeyframes().length > 0) ? "#FF9800" : "#888888"
                font.pixelSize: 10
                horizontalAlignment: Text.AlignRight
            }
        }
    }
}
