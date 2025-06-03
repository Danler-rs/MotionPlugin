import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    // Публичные свойства
    property int totalFrames: 30
    property int currentFrame: 0
    property var keyframeManager: null // Ссылка на KeyframeManager

    // Внешний вид
    color: "#2a2a2a"
    border.color: "#666666"
    border.width: 1

    // Сигналы
    signal frameSelected(int frame)
    signal keyframeSaveRequested(int frame)
    signal keyframeLoadRequested(int frame)
    signal keyframeDeleteRequested(int frame)

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 5

        // Заголовок таймлайна
        Row {
            width: parent.width
            spacing: 10

            Text {
                text: "🎬 Timeline"
                color: "white"
                font.bold: true
                font.pixelSize: 14
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                text: "Frame: " + (currentFrame + 1) + "/" + totalFrames
                color: "#4CAF50"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Keyframes: " + (keyframeManager ? keyframeManager.getAllKeyframes().length : 0)
                color: "#FF9800"
                font.pixelSize: 12
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Rectangle {
            width: parent.width
            height: 1
            color: "#555555"
        }

        // Номера кадров
        Row {
            id: frameNumbers
            spacing: 1

            Repeater {
                model: totalFrames

                Rectangle {
                    width: (root.width - 16 - (totalFrames - 1)) / totalFrames
                    height: 20
                    color: "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: index + 1
                        color: "#888888"
                        font.pixelSize: 8
                    }
                }
            }
        }

        // Основная полоса таймлайна
        Row {
            id: timelineRow
            spacing: 1

            Repeater {
                id: frameRepeater
                model: totalFrames

                Rectangle {
                    id: frameRect
                    width: (root.width - 16 - (totalFrames - 1)) / totalFrames
                    height: 40

                    // Сохраняем index в property для использования в MouseArea
                    property int frameIndex: index

                    // Цвет кадра в зависимости от состояния
                    color: {
                        if (keyframeManager && keyframeManager.hasKeyframe(frameIndex)) {
                            return "#FF9800" // Оранжевый для ключевых кадров
                        } else if (frameIndex === currentFrame) {
                            return "#4CAF50" // Зеленый для текущего кадра
                        } else {
                            return "#666666" // Серый для обычных кадров
                        }
                    }

                    border.color: frameIndex === currentFrame ? "#81C784" : "#888888"
                    border.width: frameIndex === currentFrame ? 2 : 1
                    radius: 2

                    // Индикатор ключевого кадра
                    Rectangle {
                        anchors.centerIn: parent
                        width: 8
                        height: 8
                        radius: 4
                        color: "#FFF"
                        visible: keyframeManager ? keyframeManager.hasKeyframe(frameIndex) : false

                        Rectangle {
                            anchors.centerIn: parent
                            width: 4
                            height: 4
                            radius: 2
                            color: "#FF5722"
                        }
                    }

                    // Текст номера кадра
                    Text {
                        anchors.bottom: parent.bottom
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottomMargin: 2
                        text: frameIndex + 1
                        color: (keyframeManager ? keyframeManager.hasKeyframe(frameIndex) : false) ? "white" : "#cccccc"
                        font.pixelSize: 9
                        font.bold: keyframeManager ? keyframeManager.hasKeyframe(frameIndex) : false
                    }

                    // Обработка мыши
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                        hoverEnabled: true

                        onClicked: function(mouse) {
                            console.log("Mouse clicked on frame", frameRect.frameIndex + 1, "button:", mouse.button)
                            console.log("Has keyframe:", keyframeManager ? keyframeManager.hasKeyframe(frameRect.frameIndex) : false)

                            if (mouse.button === Qt.LeftButton) {
                                // Левый клик
                                if (frameRect.frameIndex !== currentFrame) {
                                    // Первый клик - переключение на кадр и загрузка ключевого кадра (если есть)
                                    currentFrame = frameRect.frameIndex
                                    frameSelected(frameRect.frameIndex)

                                    // Если это ключевой кадр, загружаем его
                                    if (keyframeManager && keyframeManager.hasKeyframe(frameRect.frameIndex)) {
                                        keyframeLoadRequested(frameRect.frameIndex)
                                        console.log("Loading keyframe for frame", frameRect.frameIndex + 1)
                                    }
                                } else {
                                    // Второй клик на тот же кадр - создание/обновление ключевого кадра
                                    keyframeSaveRequested(frameRect.frameIndex)
                                    console.log("Saving keyframe for frame", frameRect.frameIndex + 1)
                                }
                            } else if (mouse.button === Qt.RightButton) {
                                // Правый клик - удаление ключевого кадра
                                console.log("Right click detected on frame", frameRect.frameIndex + 1)
                                if (keyframeManager && keyframeManager.hasKeyframe(frameRect.frameIndex)) {
                                    keyframeDeleteRequested(frameRect.frameIndex)
                                    console.log("Requesting deletion of keyframe for frame", frameRect.frameIndex + 1)
                                } else {
                                    console.log("No keyframe to delete for frame", frameRect.frameIndex + 1)
                                }
                            }
                        }

                        onEntered: {
                            frameRect.opacity = 0.8
                        }

                        onExited: {
                            frameRect.opacity = 1.0
                        }
                    }

                    // Анимация при наведении
                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    // Анимация изменения цвета
                    Behavior on color {
                        ColorAnimation { duration: 200 }
                    }
                }
            }
        }

        // Дополнительная информация
        Row {
            width: parent.width
            spacing: 15

            Text {
                text: "💡 Left click: Select frame / Second click: Save keyframe"
                color: "#888888"
                font.pixelSize: 10
            }

            Text {
                text: "🗑️ Right click: Delete keyframe"
                color: "#888888"
                font.pixelSize: 10
            }
        }
    }

    // Функции для работы с ключевыми кадрами
    function setCurrentFrame(frame) {
        if (frame >= 0 && frame < totalFrames) {
            currentFrame = frame
            frameSelected(frame)

            // Автоматически загружаем ключевой кадр, если он есть
            if (keyframeManager && keyframeManager.hasKeyframe(frame)) {
                keyframeLoadRequested(frame)
            }
        }
    }

    function hasKeyframe(frame) {
        return keyframeManager ? keyframeManager.hasKeyframe(frame) : false
    }

    function getKeyframes() {
        return keyframeManager ? keyframeManager.getAllKeyframes() : []
    }

    function refreshDisplay() {
        // Принудительное обновление отображения
        frameRepeater.model = 0
        frameRepeater.model = totalFrames
    }

    // Соединения для обновления интерфейса
    Connections {
        target: keyframeManager

        function onKeyframeSaved(frame, data) {
            console.log("Timeline: Keyframe saved for frame", frame + 1)
            refreshDisplay()
        }

        function onKeyframeLoaded(frame, data) {
            console.log("Timeline: Keyframe loaded for frame", frame + 1)
        }

        function onKeyframeDeleted(frame) {
            console.log("Timeline: Keyframe deleted for frame", frame + 1)
            refreshDisplay()
        }
    }
}
