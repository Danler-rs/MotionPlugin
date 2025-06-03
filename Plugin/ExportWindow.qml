import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import MotionPlugin 1.0

Window {
    id: root
    width: 500
    height: 600
    visible: false
    title: "Export Animation"
    color: "#2a2a2a"

    property alias exporter: exporter
    property var keyframeManager: null
    property var view3d: null

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
           Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint

    AnimationExporter {
        id: exporter

        onExportCompleted: function(success, message) {
            if (success) {
                statusText.color = "#4CAF50"
                statusText.text = "✅ " + message
            } else {
                statusText.color = "#f44336"
                statusText.text = "❌ " + message
            }

            // Show completion dialog
            messageDialog.title = success ? "Export Successful" : "Export Failed"
            messageDialog.text = message
            messageDialog.open()
        }

        onExportProgress: function(frame, total, status) {
            progressBar.value = frame / total
            progressText.text = status
        }
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20

        Column {
            spacing: 20
            width: root.width - 40

            Text {
                text: "🎬 Export Animation to Video"
                color: "white"
                font.bold: true
                font.pixelSize: 18
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#666666"
            }

            // Export Settings
            Rectangle {
                width: parent.width
                height: settingsColumn.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5

                Column {
                    id: settingsColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 15
                    spacing: 15

                    Text {
                        text: "⚙️ Export Settings"
                        color: "lightblue"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    // Frame Rate Setting
                    Row {
                        width: parent.width
                        spacing: 10

                        Text {
                            text: "Frame Rate (FPS):"
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            width: 120
                        }

                        SpinBox {
                            id: frameRateSpinBox
                            from: 2
                            to: 60
                            value: exporter.frameRate
                            onValueChanged: exporter.frameRate = value

                            background: Rectangle {
                                color: "#444444"
                                border.color: "#666666"
                                radius: 3
                            }

                            contentItem: TextInput {
                                text: frameRateSpinBox.displayText
                                color: "white"
                                horizontalAlignment: Qt.AlignHCenter
                                verticalAlignment: Qt.AlignVCenter
                                readOnly: !frameRateSpinBox.editable
                                validator: frameRateSpinBox.validator
                                inputMethodHints: frameRateSpinBox.inputMethodHints
                            }
                        }

                        Text {
                            text: "fps (2-60)"
                            color: "#888888"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    // Resolution Setting
                    Row {
                        width: parent.width
                        spacing: 10

                        Text {
                            text: "Resolution:"
                            color: "white"
                            anchors.verticalCenter: parent.verticalCenter
                            width: 120
                        }

                        ComboBox {
                            id: resolutionComboBox
                            width: 200
                            model: [
                                "1920x1080 (Full HD)",
                                "1280x720 (HD)",
                                "1366x768 (HD+)",
                                "1600x900 (HD+)",
                                "2560x1440 (2K)",
                                "3840x2160 (4K)"
                            ]
                            currentIndex: 0

                            background: Rectangle {
                                color: "#444444"
                                border.color: "#666666"
                                radius: 3
                            }

                            contentItem: Text {
                                text: resolutionComboBox.displayText
                                color: "white"
                                verticalAlignment: Text.AlignVCenter
                                leftPadding: 10
                            }

                            popup: Popup {
                                y: resolutionComboBox.height - 1
                                width: resolutionComboBox.width
                                implicitHeight: contentItem.implicitHeight
                                padding: 1

                                contentItem: ListView {
                                    clip: true
                                    implicitHeight: contentHeight
                                    model: resolutionComboBox.popup.visible ? resolutionComboBox.delegateModel : null
                                    currentIndex: resolutionComboBox.highlightedIndex

                                    ScrollIndicator.vertical: ScrollIndicator { }
                                }

                                background: Rectangle {
                                    color: "#444444"
                                    border.color: "#666666"
                                    radius: 3
                                }
                            }

                            delegate: ItemDelegate {
                                width: resolutionComboBox.width
                                contentItem: Text {
                                    text: modelData
                                    color: "white"
                                    verticalAlignment: Text.AlignVCenter
                                }
                                highlighted: resolutionComboBox.highlightedIndex === index
                                background: Rectangle {
                                    color: highlighted ? "#555555" : "transparent"
                                }
                            }
                        }
                    }

                    // Output Path Setting
                    Column {
                        width: parent.width
                        spacing: 8

                        Text {
                            text: "Output File:"
                            color: "white"
                        }

                        Row {
                            width: parent.width
                            spacing: 10

                            Rectangle {
                                width: parent.width - exportBrowseButton.width - 10
                                height: 35
                                color: "#444444"
                                border.color: "#666666"
                                radius: 3

                                TextInput {
                                    id: pathInput
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    text: exporter.exportPath
                                    color: "white"
                                    verticalAlignment: TextInput.AlignVCenter
                                    selectByMouse: true
                                    onTextChanged: exporter.exportPath = text
                                }
                            }

                            Button {
                                id: exportBrowseButton
                                text: "Browse..."
                                width: 80
                                height: 35
                                onClicked: saveDialog.open()

                                background: Rectangle {
                                    color: parent.pressed ? "#555555" : "#666666"
                                    border.color: "#888888"
                                    radius: 3
                                }

                                contentItem: Text {
                                    text: exportBrowseButton.text
                                    color: "white"
                                    horizontalAlignment: Text.AlignHCenter
                                    verticalAlignment: Text.AlignVCenter
                                }
                            }
                        }
                    }
                }
            }

            // Keyframes Info
            Rectangle {
                width: parent.width
                height: keyframesColumn.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5

                Column {
                    id: keyframesColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "📊 Animation Info"
                        color: "lightgreen"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Text {
                        text: "• Total Keyframes: " + getKeyframeCount()
                        color: "lightgray"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "• Animation Duration: " + getAnimationDuration() + " seconds"
                        color: "lightgray"
                        font.pixelSize: 12
                    }

                    Text {
                        text: "• Output File Size: ~" + getEstimatedFileSize()
                        color: "lightgray"
                        font.pixelSize: 12
                    }
                }
            }

            // Progress Section
            Rectangle {
                width: parent.width
                height: progressColumn.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5
                visible: exporter.isExporting

                Column {
                    id: progressColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 15
                    spacing: 15

                    Text {
                        text: "🔄 Export Progress"
                        color: "yellow"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    ProgressBar {
                        id: progressBar
                        width: parent.width
                        from: 0
                        to: 1
                        value: 0

                        background: Rectangle {
                            color: "#666666"
                            radius: 3
                        }

                        contentItem: Item {
                            Rectangle {
                                width: progressBar.visualPosition * parent.width
                                height: parent.height
                                radius: 3
                                color: "#4CAF50"
                            }
                        }
                    }

                    Text {
                        id: progressText
                        text: "Preparing export..."
                        color: "white"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Text {
                        text: "Frame: " + exporter.currentFrame + " / " + exporter.totalFrames
                        color: "#4CAF50"
                        font.pixelSize: 12
                    }
                }
            }

            // Status
            Rectangle {
                width: parent.width
                height: statusColumn.height + 20
                color: "#333333"
                border.color: "#666666"
                radius: 5

                Column {
                    id: statusColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 15
                    spacing: 10

                    Text {
                        text: "📋 Status"
                        color: "lightblue"
                        font.bold: true
                        font.pixelSize: 14
                    }

                    Text {
                        id: statusText
                        text: exporter.status
                        color: "white"
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Text {
                        text: "FFmpeg Status: " + (exporter.checkFFmpegAvailable() ? "✅ Available" : "❌ Not Found")
                        color: exporter.checkFFmpegAvailable() ? "#4CAF50" : "#f44336"
                        font.pixelSize: 11
                    }
                }
            }

            // Export Controls
            Row {
                spacing: 15
                anchors.horizontalCenter: parent.horizontalCenter

                Button {
                    id: exportButton
                    text: exporter.isExporting ? "⏹️ Stop Export" : "🎬 Start Export"
                    width: 150
                    height: 40
                    enabled: !exporter.isExporting || exporter.isExporting

                    onClicked: {
                        if (exporter.isExporting) {
                            exporter.stopExport()
                        } else {
                            startExport()
                        }
                    }

                    background: Rectangle {
                        color: {
                            if (!exportButton.enabled) return "#333333"
                            if (exporter.isExporting) return exportButton.pressed ? "#c62828" : "#f44336"
                            return exportButton.pressed ? "#388e3c" : "#4CAF50"
                        }
                        border.color: "#777777"
                        radius: 5
                    }

                    contentItem: Text {
                        text: exportButton.text
                        color: exportButton.enabled ? "white" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                    }
                }

                Button {
                    text: "❌ Close"
                    width: 100
                    height: 40
                    enabled: !exporter.isExporting
                    onClicked: root.visible = false

                    background: Rectangle {
                        color: parent.pressed ? "#664444" : "#442222"
                        border.color: "#777777"
                        radius: 5
                    }

                    contentItem: Text {
                        text: parent.text
                        color: parent.enabled ? "white" : "#888888"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            // Help Section
            Rectangle {
                width: parent.width
                height: helpColumn.height + 20
                color: "#2a2a2a"
                border.color: "#555555"
                radius: 5

                Column {
                    id: helpColumn
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 15
                    spacing: 8

                    Text {
                        text: "💡 Help & Tips"
                        color: "orange"
                        font.bold: true
                        font.pixelSize: 12
                    }

                    Text {
                        text: "• Make sure you have created keyframes before exporting"
                        color: "#cccccc"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Text {
                        text: "• Place ffmpeg.exe in your project directory for video encoding"
                        color: "#cccccc"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Text {
                        text: "• Higher frame rates create smoother animations but larger files"
                        color: "#cccccc"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }

                    Text {
                        text: "• Export time depends on number of keyframes and resolution"
                        color: "#cccccc"
                        font.pixelSize: 10
                        wrapMode: Text.WordWrap
                        width: parent.width
                    }
                }
            }
        }
    }

    // File Dialog for save location
    FileDialog {
        id: saveDialog
        title: "Save Animation As..."
        fileMode: FileDialog.SaveFile
        nameFilters: ["MP4 Video (*.mp4)", "AVI Video (*.avi)", "MOV Video (*.mov)"]
        defaultSuffix: "mp4"
        onAccepted: {
            exporter.exportPath = selectedFile.toString().replace("file://", "")
        }
    }

    // Message Dialog for completion notification
    Dialog {
        id: messageDialog
        title: "Export Status"
        modal: true
        anchors.centerIn: parent
        width: 400
        height: 200

        background: Rectangle {
            color: "#2a2a2a"
            border.color: "#666666"
            radius: 5
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 15

            Text {
                id: messageText
                text: messageDialog.text
                color: "white"
                wrapMode: Text.WordWrap
                width: parent.width
            }

            Button {
                text: "OK"
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: messageDialog.close()

                background: Rectangle {
                    color: parent.pressed ? "#555555" : "#4CAF50"
                    radius: 3
                }

                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
            }
        }

        property alias text: messageText.text
    }

    // Functions
    function startExport() {
        if (!keyframeManager) {
            statusText.color = "#f44336"
            statusText.text = "❌ Error: No keyframe manager available"
            return
        }

        if (!view3d) {
            statusText.color = "#f44336"
            statusText.text = "❌ Error: No view3d available"
            return
        }

        if (getKeyframeCount() === 0) {
            statusText.color = "#f44336"
            statusText.text = "❌ Error: No keyframes found. Create some keyframes first."
            return
        }

        // Get resolution from combo box
        var resolutions = {
            0: {width: 1920, height: 1080},
            1: {width: 1280, height: 720},
            2: {width: 1366, height: 768},
            3: {width: 1600, height: 900},
            4: {width: 2560, height: 1440},
            5: {width: 3840, height: 2160}
        }

        var resolution = resolutions[resolutionComboBox.currentIndex] || {width: 1920, height: 1080}

        statusText.color = "white"
        statusText.text = "🔄 Starting export..."

        exporter.startExport(keyframeManager, view3d, resolution.width, resolution.height)
    }

    function getKeyframeCount() {
        if (!keyframeManager) return 0

        try {
            var keyframes = keyframeManager.getAllKeyframes()
            console.log("ExportWindow: Getting keyframes:", keyframes, "Type:", typeof keyframes)

            if (Array.isArray(keyframes)) {
                console.log("ExportWindow: Keyframe count:", keyframes.length)
                return keyframes.length
            } else if (typeof keyframes === 'object' && keyframes !== null) {
                // Если это объект, получаем количество ключей
                var count = Object.keys(keyframes).length
                console.log("ExportWindow: Keyframe count from object:", count)
                return count
            }
        } catch (e) {
            console.log("ExportWindow: Error getting keyframe count:", e)
        }

        console.log("ExportWindow: No keyframes found")
        return 0
    }

    function getAnimationDuration() {
        var keyframeCount = getKeyframeCount()
        if (keyframeCount === 0) return "0.0"

        var duration = keyframeCount / frameRateSpinBox.value
        return duration.toFixed(1)
    }

    function getEstimatedFileSize() {
        var keyframeCount = getKeyframeCount()
        var resolution = resolutionComboBox.currentIndex

        if (keyframeCount === 0) return "0 MB"

        // Rough estimation based on resolution and frame count
        var baseSizePerFrame = [2.5, 1.2, 1.4, 1.8, 5.0, 15.0] // MB per frame for each resolution
        var sizePerFrame = baseSizePerFrame[resolution] || 2.5

        var totalSize = keyframeCount * sizePerFrame

        if (totalSize < 1) {
            return (totalSize * 1024).toFixed(0) + " KB"
        } else if (totalSize < 1024) {
            return totalSize.toFixed(1) + " MB"
        } else {
            return (totalSize / 1024).toFixed(1) + " GB"
        }
    }

    Component.onCompleted: {
        console.log("Export window initialized")
    }
}
