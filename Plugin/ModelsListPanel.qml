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
    property var modelManager

    color: "#80000000"
    width: 250
    z: 5 // Панель поверх вида, но под основной панелью управления

    ColumnLayout {
        anchors.fill: parent
        spacing: 5

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 40
            color: "#505050"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 5

                Label {
                    text: "Загруженные модели"
                    color: "white"
                    font.pixelSize: 14
                    font.bold: true
                    Layout.fillWidth: true
                }

                Button {
                    text: "+"
                    Layout.preferredWidth: 30
                    Layout.preferredHeight: 30
                    font.pixelSize: 16
                    font.bold: true
                    onClicked: fileDialog.open()

                    background: Rectangle {
                        color: "#007acc"
                        radius: 4
                    }
                    contentItem: Text {
                        text: "+"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    ToolTip.visible: hovered
                    ToolTip.text: "Добавить новую модель"
                }
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ListView {
                id: modelsList
                anchors.fill: parent
                model: modelManager.modelListModel
                spacing: 2

                delegate: Rectangle {
                    width: modelsList.width
                    height: 50
                    color: modelManager.selectedModelIndex === index ? "#407acc" : "#303030"

                    MouseArea {
                        anchors.fill: parent
                        onClicked: modelManager.selectModel(index)
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 5
                        spacing: 5

                        CheckBox {
                            checked: visible
                            onClicked: modelManager.toggleModelVisibility(index)
                        }

                        Label {
                            text: name
                            color: "white"
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }

                        Button {
                            text: "×"
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            onClicked: confirmRemoveDialog.open()
                        }

                        // Используем DialogWindow вместо абстрактного Dialog
                        Popup {
                            id: confirmRemoveDialog
                            width: 300
                            height: 150
                            modal: true
                            closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
                            anchors.centerIn: Overlay.overlay

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                Label {
                                    text: "Удалить модель '" + name + "'?"
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    horizontalAlignment: Text.AlignHCenter
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 20

                                    Button {
                                        text: "Да"
                                        onClicked: {
                                            modelManager.removeModel(index)
                                            confirmRemoveDialog.close()
                                        }
                                    }

                                    Button {
                                        text: "Нет"
                                        onClicked: confirmRemoveDialog.close()
                                    }
                                }
                            }
                        }
                    }
                }

                // Сообщение, если нет моделей
                Rectangle {
                    anchors.centerIn: parent
                    width: parent.width * 0.8
                    height: 80
                    color: "#303030"
                    visible: modelsList.count === 0
                    radius: 5

                    Label {
                        anchors.centerIn: parent
                        text: "Нет загруженных моделей.\nНажмите + для добавления."
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }
        }
    }

    FileDialog {
        id: fileDialog
        nameFilters: ["glTF files (*.gltf *.glb)", "All files (*)"]
        onAccepted: modelManager.importModel(file)
    }
}
