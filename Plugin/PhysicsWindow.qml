import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick3D
import QtQuick3D.Physics
import QtQuick3D.Helpers
import QtQuick3D.AssetUtils

Window {
    id: root
    width: 1280
    height: 720
    visible: false
    title: "Physics Simulation"
    color: "#404040"

    property var sourceModel: null  // Reference to loaded model from main.qml
    property bool hasLoadedModel: sourceModel && (sourceModel.status === RuntimeLoader.Success || sourceModel.status === 1)
    property bool modelReady: sourceModel && sourceModel.source.toString().length > 0

    // Get bounds from main model if available
    property var mainModelBounds: sourceModel && sourceModel.bounds ? sourceModel.bounds : null

    // Debug information
    onSourceModelChanged: {
        console.log("PhysicsWindow: sourceModel changed to:", sourceModel)
        if (sourceModel) {
            console.log("PhysicsWindow: sourceModel.source:", sourceModel.source)
            console.log("PhysicsWindow: sourceModel.status:", sourceModel.status)

            // Update model when it's loaded
            if (sourceModel.status === RuntimeLoader.Success) {
                updateLoadedModel()
            }
        }
    }

    flags: Qt.Window | Qt.WindowSystemMenuHint | Qt.WindowTitleHint |
           Qt.WindowMinMaxButtonsHint | Qt.WindowCloseButtonHint

    //! [world]
    PhysicsWorld {
        id: physicsWorld
        running: true
        typicalLength: 100
        enableCCD: true
        maximumTimestep: 20
        gravity: Qt.vector3d(0, -981, 0)
        scene: viewport.scene
    }
    //! [world]

    View3D {
        id: viewport
        anchors.fill: parent

        //! [environment]
        environment: ExtendedSceneEnvironment {
            id: env
            backgroundMode: SceneEnvironment.SkyBox
            lightProbe: Texture {
                textureData: ProceduralSkyTextureData{}
            }
            skyboxBlurAmount: 0.1
            exposure: 1.0
            lensFlareBloomBias: 2.75
            lensFlareApplyDirtTexture: true
            lensFlareApplyStarburstTexture: true
        }
        //! [environment]

        Node {
            id: scene

            //! [camera]
            PerspectiveCamera {
                id: camera
                position: Qt.vector3d(0, 200, 600)
                eulerRotation: Qt.vector3d(-15, 0, 0)
                clipFar: 10000
                clipNear: 1
                fieldOfView: 45
            }
            //! [camera]

            //! [lighting]
            DirectionalLight {
                eulerRotation: Qt.vector3d(-35, -90, 0)
                castsShadow: true
                brightness: 1.0
                shadowMapQuality: Light.ShadowMapQualityHigh
                shadowBias: 0.1
            }

            PointLight {
                position: camera.position
                brightness: 0.3
                castsShadow: false
            }
            //! [lighting]

            //! [floor]
            StaticRigidBody {
                id: floorBody
                position: Qt.vector3d(0, -200, 0)
                eulerRotation: Qt.vector3d(floorRotXSlider.value, 0, floorRotZSlider.value)
                collisionShapes: BoxShape {
                    extents: Qt.vector3d(800, 10, 800)
                }
                Model {
                    source: "#Cube"
                    scale: Qt.vector3d(8, 0.1, 8)
                    materials: PrincipledMaterial {
                        baseColor: "#666666"
                        roughness: 0.8
                        metalness: 0.1
                    }
                    castsShadows: false
                    receivesShadows: true
                }
            }
            //! [floor]

            //! [physics material]
            PhysicsMaterial {
                id: physicsMaterial
                staticFriction: staticFrictionSlider.value
                dynamicFriction: dynamicFrictionSlider.value
                restitution: restitutionSlider.value
            }
            //! [physics material]

            //! [loaded model]
            DynamicRigidBody {
                id: loadedModelBody
                visible: hasLoadedModel || modelReady
                physicsMaterial: physicsMaterial
                massMode: DynamicRigidBody.CustomDensity
                density: 10
                property vector3d startPosition: Qt.vector3d(0, 100, 0)
                position: startPosition

                // Use CapsuleShape - better for humanoid models
                collisionShapes: CapsuleShape {
                    id: modelCollisionShape
                    height: {
                        if (mainModelBounds) {
                            return Math.abs(mainModelBounds.maximum.y - mainModelBounds.minimum.y) * 0.9
                        }
                        return 150 // Default human height
                    }
                    diameter: {
                        if (mainModelBounds) {
                            var xSize = Math.abs(mainModelBounds.maximum.x - mainModelBounds.minimum.x)
                            var zSize = Math.abs(mainModelBounds.maximum.z - mainModelBounds.minimum.z)
                            return Math.max(xSize, zSize) * 0.7
                        }
                        return 40 // Default human width
                    }
                }

                RuntimeLoader {
                    id: physicsModelLoader
                    source: (hasLoadedModel || modelReady) ? sourceModel.source : ""

                    onStatusChanged: {
                        console.log("PhysicsWindow: Physics model loader status:", status)
                        if (status === RuntimeLoader.Success) {
                            console.log("PhysicsWindow: Physics model loaded successfully")
                            applyPhysicsMaterial()
                            // No need to set collision shape source for BoxShape
                        }
                    }

                    function applyPhysicsMaterial() {
                        var material = Qt.createQmlObject(`
                            import QtQuick3D
                            PrincipledMaterial {
                                baseColor: "purple"
                                metalness: 0.2
                                roughness: 0.3
                            }
                        `, physicsModelLoader)

                        applyMaterialRecursively(physicsModelLoader, material)
                    }

                    function applyMaterialRecursively(node, material) {
                        if (!node) return

                        if (node.toString().includes("Model")) {
                            try {
                                node.materials = [material]
                            } catch (e) {
                                console.log("Could not apply material to node:", e)
                            }
                        }

                        if (node.children) {
                            for (var i = 0; i < node.children.length; i++) {
                                applyMaterialRecursively(node.children[i], material)
                            }
                        }
                    }
                }

                Component.onCompleted: {
                    console.log("PhysicsWindow: loadedModelBody created")
                }
            }
            //! [loaded model]

            //! [collision debug]
            Model {
                id: collisionDebug
                visible: showCollisionBounds.checked && (hasLoadedModel || modelReady)
                position: loadedModelBody.position
                source: "#Sphere"

                // Use the same scale as the collision box
                scale: {
                    if (mainModelBounds) {
                        var size = Qt.vector3d(
                            Math.abs(mainModelBounds.maximum.x - mainModelBounds.minimum.x),
                            Math.abs(mainModelBounds.maximum.y - mainModelBounds.minimum.y),
                            Math.abs(mainModelBounds.maximum.z - mainModelBounds.minimum.z)
                        )
                        // Match the collision box scaling
                        return Qt.vector3d(
                            (size.x * 0.8) / 100,
                            (size.y * 0.9) / 100,
                            (size.z * 0.6) / 100
                        )
                    }
                    return Qt.vector3d(0.5, 1.0, 0.3) // Default humanoid proportions
                }

                materials: PrincipledMaterial {
                    baseColor: "red"
                    alphaMode: PrincipledMaterial.Blend
                    opacity: 0.3
                    metalness: 0
                    roughness: 1
                }
                castsShadows: false
                receivesShadows: false
            }
            //! [collision debug]

        } // scene
    } // View3D

    //! [controller - same as example]
    WasdController {
        keysEnabled: true
        controlledObject: camera
        speed: 5.0
        shiftSpeed: 15.0
    }
    //! [controller]

    // Control panel - simplified
    Frame {
        id: controlPanel
        background: Rectangle {
            color: "#c0c0c0"
            border.color: "#202020"
            radius: 5
        }
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10

        ColumnLayout {
            spacing: 10

            Text {
                text: "⚛️ Physics Control Panel"
                font.bold: true
                font.pixelSize: 14
                color: "#202020"
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#666666"
            }

            // Floor controls
            ColumnLayout {
                spacing: 8

                Text {
                    text: "🏢 Floor Controls"
                    color: "#FFB74D"
                    font.bold: true
                    font.pixelSize: 12
                }

                // Floor rotation X (tilt forward/backward)
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Tilt Forward/Back: " + floorRotXSlider.value.toFixed(0) + "°"
                        color: "#202020"
                        font.pixelSize: 10
                    }

                    Row {
                        width: parent.width
                        spacing: 5
                        Text {
                            text: "X:"
                            color: "#ff6666"
                            width: 15
                            font.pixelSize: 10
                        }
                        Slider {
                            id: floorRotXSlider
                            width: parent.width - 60
                            from: -30
                            to: 30
                            value: 0
                            focusPolicy: Qt.NoFocus
                        }
                        Text {
                            text: floorRotXSlider.value.toFixed(0) + "°"
                            color: "#202020"
                            width: 35
                            font.pixelSize: 9
                        }
                    }
                }

                // Floor rotation Z (tilt left/right)
                Column {
                    width: parent.width
                    spacing: 5

                    Text {
                        text: "Tilt Left/Right: " + floorRotZSlider.value.toFixed(0) + "°"
                        color: "#202020"
                        font.pixelSize: 10
                    }

                    Row {
                        width: parent.width
                        spacing: 5
                        Text {
                            text: "Z:"
                            color: "#6666ff"
                            width: 15
                            font.pixelSize: 10
                        }
                        Slider {
                            id: floorRotZSlider
                            width: parent.width - 60
                            from: -30
                            to: 30
                            value: 0
                            focusPolicy: Qt.NoFocus
                        }
                        Text {
                            text: floorRotZSlider.value.toFixed(0) + "°"
                            color: "#202020"
                            width: 35
                            font.pixelSize: 9
                        }
                    }
                }

                Button {
                    text: "🏠 Reset Floor"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: {
                        floorRotXSlider.value = 0
                        floorRotZSlider.value = 0
                    }
                    background: Rectangle {
                        color: parent.pressed ? "#888888" : "#5D4E75"
                        border.color: "#666666"
                        radius: 3
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                    }
                }
            }

            // Model status
            Text {
                text: (hasLoadedModel || modelReady) ? "🟣 Model Loaded" : "💡 Load model in main window"
                color: (hasLoadedModel || modelReady) ? "#8833cc" : "#666666"
                font.pixelSize: 10
                font.italic: !(hasLoadedModel || modelReady)
                wrapMode: Text.WordWrap
                width: parent.width
            }

            // Model controls
            ColumnLayout {
                spacing: 5
                visible: hasLoadedModel || modelReady
                enabled: hasLoadedModel || modelReady

                Button {
                    text: "🔄 Reset Model"
                    Layout.alignment: Qt.AlignHCenter
                    onClicked: {
                        if (hasLoadedModel || modelReady) {
                            loadedModelBody.reset(loadedModelBody.startPosition, Qt.vector3d(0, 0, 0))
                        }
                    }
                    background: Rectangle {
                        color: parent.pressed ? "#888888" : "#4CAF50"
                        border.color: "#666666"
                        radius: 3
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                    }
                }

                CheckBox {
                    id: showCollisionBounds
                    text: "Show collision bounds (capsule)"
                    checked: true

                    contentItem: Text {
                        text: showCollisionBounds.text
                        font.pixelSize: 10
                        color: "#202020"
                        leftPadding: showCollisionBounds.indicator.width + 5
                        verticalAlignment: Text.AlignVCenter
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#666666"
            }

            // Physics controls
            Label {
                text: "Static friction: " + staticFrictionSlider.value.toFixed(2)
                color: "#202020"
                font.pixelSize: 10
            }
            Slider {
                id: staticFrictionSlider
                focusPolicy: Qt.NoFocus
                from: 0
                to: 1
                value: 0.3
                Layout.fillWidth: true
            }

            Label {
                text: "Dynamic friction: " + dynamicFrictionSlider.value.toFixed(2)
                color: "#202020"
                font.pixelSize: 10
            }
            Slider {
                id: dynamicFrictionSlider
                focusPolicy: Qt.NoFocus
                from: 0
                to: 1
                value: 0.3
                Layout.fillWidth: true
            }

            Label {
                text: "Restitution: " + restitutionSlider.value.toFixed(2)
                color: "#202020"
                font.pixelSize: 10
            }
            Slider {
                id: restitutionSlider
                focusPolicy: Qt.NoFocus
                from: 0
                to: 1
                value: 0.1
                Layout.fillWidth: true
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#666666"
            }

            // Simulation controls
            Label {
                text: "Gravity: " + gravitySlider.value.toFixed(0)
                color: "#202020"
                font.pixelSize: 10
            }
            Slider {
                id: gravitySlider
                focusPolicy: Qt.NoFocus
                from: -2000
                to: 0
                value: physicsWorld.gravity.y
                onValueChanged: physicsWorld.gravity = Qt.vector3d(0, value, 0)
                Layout.fillWidth: true
            }

            Row {
                spacing: 10
                Layout.alignment: Qt.AlignHCenter

                Button {
                    text: physicsWorld.running ? "⏸️ Pause" : "▶️ Play"
                    onClicked: physicsWorld.running = !physicsWorld.running
                    background: Rectangle {
                        color: parent.pressed ? "#888888" : (physicsWorld.running ? "#4CAF50" : "#FF9800")
                        border.color: "#666666"
                        radius: 3
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.bold: true
                        font.pixelSize: 10
                    }
                }

                Button {
                    text: "🔄 Reset Scene"
                    onClicked: resetScene()
                    background: Rectangle {
                        color: parent.pressed ? "#888888" : "#666666"
                        border.color: "#444444"
                        radius: 3
                    }
                    contentItem: Text {
                        text: parent.text
                        color: "white"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: 10
                    }
                }
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#666666"
            }

            Button {
                text: "❌ Close"
                Layout.alignment: Qt.AlignHCenter
                onClicked: root.visible = false
                background: Rectangle {
                    color: parent.pressed ? "#666666" : "#442222"
                    border.color: "#333333"
                    radius: 3
                }
                contentItem: Text {
                    text: parent.text
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 10
                }
            }
        }
    }

    // Info panel
    Frame {
        background: Rectangle {
            color: "#e0e0e0"
            border.color: "#808080"
            radius: 5
        }
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.margins: 10

        ColumnLayout {
            spacing: 5

            Text {
                text: "📋 Controls"
                font.bold: true
                font.pixelSize: 12
                color: "#202020"
            }

            Text {
                text: "🟥 Red cylinder = capsule collision"
                color: "#cc2222"
                font.pixelSize: 9
                visible: hasLoadedModel || modelReady
            }

            Text {
                text: "WASD: Move camera"
                color: "#404040"
                font.pixelSize: 9
            }

            Text {
                text: "Mouse: Look around"
                color: "#404040"
                font.pixelSize: 9
            }

            Text {
                text: "Shift: Move faster"
                color: "#404040"
                font.pixelSize: 9
            }

            Text {
                text: "Floor: " + floorRotXSlider.value.toFixed(0) + "°/" + floorRotZSlider.value.toFixed(0) + "°"
                color: "#404040"
                font.pixelSize: 9
            }

            Rectangle {
                width: parent.width
                height: 1
                color: "#999999"
            }

            Text {
                text: physicsWorld.running ? "Status: Running ✅" : "Status: Paused ⏸️"
                color: physicsWorld.running ? "#4CAF50" : "#FF9800"
                font.pixelSize: 10
                font.bold: true
            }

            Text {
                text: (hasLoadedModel || modelReady) ? "Model: Loaded 🟣" : "Model: None ⚪"
                color: (hasLoadedModel || modelReady) ? "#8833cc" : "#888888"
                font.pixelSize: 9
            }
        }
    }

    // Functions
    function resetScene() {
        physicsWorld.running = false

        if (hasLoadedModel || modelReady) {
            loadedModelBody.reset(loadedModelBody.startPosition, Qt.vector3d(0, 0, 0))
        }

        // Reset camera
        camera.position = Qt.vector3d(0, 200, 600)
        camera.eulerRotation = Qt.vector3d(-15, 0, 0)

        // Reset floor
        floorRotXSlider.value = 0
        floorRotZSlider.value = 0

        resetTimer.start()
    }

    function updateLoadedModel() {
        console.log("PhysicsWindow: Updating loaded model")
        // BoxShape will automatically use the extents we defined
        console.log("PhysicsWindow: Using BoxShape collision for glTF/GLB model")
    }

    Timer {
        id: resetTimer
        interval: 200
        repeat: false
        onTriggered: physicsWorld.running = true
    }

    Component.onCompleted: {
        console.log("Physics window initialized following Qt Quick 3D Physics example pattern")
        if (hasLoadedModel) {
            console.log("Loaded model detected:", sourceModel.source)
            updateLoadedModel()
        } else {
            console.log("No model loaded - load a model in main window first")
        }
    }
}
