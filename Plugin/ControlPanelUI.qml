import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    // Публичные свойства
    property var cameraHelper
    property var gridManager

    color: "#80000000"
    height: 50
    z: 10 // Панель поверх всего

    // Сигналы для обработки событий кнопок
    signal orbitModeRequested()
    signal wasdModeRequested()
    signal resetViewRequested()
    signal toggleGridRequested()

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

        Item { Layout.fillWidth: true } // Расширитель

        Label {
            text: cameraHelper.orbitControllerEnabled ? "Текущий режим: Orbit" : "Текущий режим: WASD"
            color: "white"
            font.pixelSize: 14
            Layout.alignment: Qt.AlignRight
        }
    }
}
