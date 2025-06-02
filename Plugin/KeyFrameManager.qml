import QtQuick
import QtQuick3D

QtObject {
    id: root

    // Ссылки на объекты сцены
    property var view3d
    property var orbitCameraNode
    property var orbitCamera
    property var wasdCamera
    property var cameraHelper
    property var gridManager
    property var boneManipulator
    property var loadedModel
    property var directionalLight
    property var pointLight

    // Хранилище ключевых кадров
    property var keyframes: ({})

    // Сигналы
    signal keyframeSaved(int frame, var data)
    signal keyframeLoaded(int frame, var data)
    signal keyframeDeleted(int frame)

    // Сохранить текущее состояние сцены как ключевой кадр
    function saveKeyframe(frame) {
        console.log("Saving keyframe for frame:", frame + 1)

        var keyframeData = {
            version: "1.0",
            timestamp: new Date().toISOString(),
            frame: frame,

            // Состояние камеры
            camera: {
                mode: cameraHelper.orbitControllerEnabled ? "orbit" : "wasd",

                // Orbit камера
                orbitCameraNode: {
                    position: {
                        x: orbitCameraNode.position.x,
                        y: orbitCameraNode.position.y,
                        z: orbitCameraNode.position.z
                    },
                    rotation: {
                        x: orbitCameraNode.eulerRotation.x,
                        y: orbitCameraNode.eulerRotation.y,
                        z: orbitCameraNode.eulerRotation.z
                    }
                },
                orbitCamera: {
                    position: {
                        x: orbitCamera.position.x,
                        y: orbitCamera.position.y,
                        z: orbitCamera.position.z
                    },
                    rotation: {
                        x: orbitCamera.eulerRotation.x,
                        y: orbitCamera.eulerRotation.y,
                        z: orbitCamera.eulerRotation.z
                    },
                    fieldOfView: orbitCamera.fieldOfView,
                    clipNear: orbitCamera.clipNear,
                    clipFar: orbitCamera.clipFar
                },

                // WASD камера
                wasdCamera: {
                    position: {
                        x: wasdCamera.position.x,
                        y: wasdCamera.position.y,
                        z: wasdCamera.position.z
                    },
                    rotation: {
                        x: wasdCamera.eulerRotation.x,
                        y: wasdCamera.eulerRotation.y,
                        z: wasdCamera.eulerRotation.z
                    },
                    fieldOfView: wasdCamera.fieldOfView,
                    clipNear: wasdCamera.clipNear,
                    clipFar: wasdCamera.clipFar
                }
            },

            // Состояние модели
            model: loadedModel ? {
                source: loadedModel.source.toString(),
                position: {
                    x: loadedModel.position.x,
                    y: loadedModel.position.y,
                    z: loadedModel.position.z
                },
                rotation: {
                    x: loadedModel.eulerRotation.x,
                    y: loadedModel.eulerRotation.y,
                    z: loadedModel.eulerRotation.z
                },
                scale: {
                    x: loadedModel.scale.x,
                    y: loadedModel.scale.y,
                    z: loadedModel.scale.z
                }
            } : null,

            // Состояние костей (если включено управление костями)
            bones: boneManipulator && boneManipulator.manipulationEnabled ? {
                enabled: true,
                selectedBoneIndex: boneManipulator.selectedBoneIndex,
                transforms: JSON.parse(JSON.stringify(boneManipulator.boneTransforms))
            } : {
                enabled: false
            },

            // Состояние освещения
            lighting: {
                directionalLight: {
                    position: {
                        x: directionalLight.position.x,
                        y: directionalLight.position.y,
                        z: directionalLight.position.z
                    },
                    rotation: {
                        x: directionalLight.eulerRotation.x,
                        y: directionalLight.eulerRotation.y,
                        z: directionalLight.eulerRotation.z
                    },
                    brightness: directionalLight.brightness,
                    castsShadow: directionalLight.castsShadow
                },
                pointLight: {
                    position: {
                        x: pointLight.position.x,
                        y: pointLight.position.y,
                        z: pointLight.position.z
                    },
                    brightness: pointLight.brightness,
                    castsShadow: pointLight.castsShadow
                }
            },

            // Состояние сцены
            scene: {
                backgroundColor: view3d.environment.clearColor,
                gridEnabled: gridManager.gridEnabled,
                gridInterval: gridManager.gridInterval,
                antialiasingMode: view3d.environment.antialiasingMode,
                antialiasingQuality: view3d.environment.antialiasingQuality
            }
        }

        keyframes[frame] = keyframeData

        console.log("Keyframe saved for frame", frame + 1, "- Data size:", JSON.stringify(keyframeData).length, "characters")
        keyframeSaved(frame, keyframeData)

        return keyframeData
    }

    // Загрузить ключевой кадр и применить к сцене
    function loadKeyframe(frame) {
        console.log("Loading keyframe for frame:", frame + 1)

        var keyframeData = keyframes[frame]
        if (!keyframeData) {
            console.log("No keyframe data found for frame", frame + 1)
            return false
        }

        console.log("Applying keyframe data for frame", frame + 1)

        try {
            // Применяем состояние камеры
            if (keyframeData.camera) {
                // Переключаем режим камеры
                var targetMode = keyframeData.camera.mode === "orbit"
                cameraHelper.switchController(targetMode)

                // Orbit камера
                if (keyframeData.camera.orbitCameraNode) {
                    var orbNodePos = keyframeData.camera.orbitCameraNode.position
                    var orbNodeRot = keyframeData.camera.orbitCameraNode.rotation

                    orbitCameraNode.position = Qt.vector3d(orbNodePos.x, orbNodePos.y, orbNodePos.z)
                    orbitCameraNode.eulerRotation = Qt.vector3d(orbNodeRot.x, orbNodeRot.y, orbNodeRot.z)
                }

                if (keyframeData.camera.orbitCamera) {
                    var orbCamPos = keyframeData.camera.orbitCamera.position
                    var orbCamRot = keyframeData.camera.orbitCamera.rotation

                    orbitCamera.position = Qt.vector3d(orbCamPos.x, orbCamPos.y, orbCamPos.z)
                    orbitCamera.eulerRotation = Qt.vector3d(orbCamRot.x, orbCamRot.y, orbCamRot.z)
                    orbitCamera.fieldOfView = keyframeData.camera.orbitCamera.fieldOfView
                    orbitCamera.clipNear = keyframeData.camera.orbitCamera.clipNear
                    orbitCamera.clipFar = keyframeData.camera.orbitCamera.clipFar
                }

                // WASD камера
                if (keyframeData.camera.wasdCamera) {
                    var wasdCamPos = keyframeData.camera.wasdCamera.position
                    var wasdCamRot = keyframeData.camera.wasdCamera.rotation

                    wasdCamera.position = Qt.vector3d(wasdCamPos.x, wasdCamPos.y, wasdCamPos.z)
                    wasdCamera.eulerRotation = Qt.vector3d(wasdCamRot.x, wasdCamRot.y, wasdCamRot.z)
                    wasdCamera.fieldOfView = keyframeData.camera.wasdCamera.fieldOfView
                    wasdCamera.clipNear = keyframeData.camera.wasdCamera.clipNear
                    wasdCamera.clipFar = keyframeData.camera.wasdCamera.clipFar
                }
            }

            // Применяем состояние модели
            if (keyframeData.model && loadedModel) {
                var modelPos = keyframeData.model.position
                var modelRot = keyframeData.model.rotation
                var modelScale = keyframeData.model.scale

                loadedModel.position = Qt.vector3d(modelPos.x, modelPos.y, modelPos.z)
                loadedModel.eulerRotation = Qt.vector3d(modelRot.x, modelRot.y, modelRot.z)
                loadedModel.scale = Qt.vector3d(modelScale.x, modelScale.y, modelScale.z)
            }

            // Применяем состояние костей
            if (keyframeData.bones && boneManipulator) {
                if (keyframeData.bones.enabled && boneManipulator.manipulationEnabled) {
                    // Восстанавливаем трансформации костей
                    boneManipulator.boneTransforms = JSON.parse(JSON.stringify(keyframeData.bones.transforms))

                    // Применяем все трансформации к модели
                    for (var boneIndex in keyframeData.bones.transforms) {
                        var transform = keyframeData.bones.transforms[boneIndex]
                        boneManipulator.setBoneTransform(parseInt(boneIndex), transform)
                    }

                    // Восстанавливаем выбранную кость
                    if (keyframeData.bones.selectedBoneIndex !== null) {
                        boneManipulator.selectBone(keyframeData.bones.selectedBoneIndex)
                    }
                }
            }

            // Применяем состояние освещения
            if (keyframeData.lighting) {
                // Directional Light
                if (keyframeData.lighting.directionalLight) {
                    var dirLightPos = keyframeData.lighting.directionalLight.position
                    var dirLightRot = keyframeData.lighting.directionalLight.rotation

                    directionalLight.position = Qt.vector3d(dirLightPos.x, dirLightPos.y, dirLightPos.z)
                    directionalLight.eulerRotation = Qt.vector3d(dirLightRot.x, dirLightRot.y, dirLightRot.z)
                    directionalLight.brightness = keyframeData.lighting.directionalLight.brightness
                    directionalLight.castsShadow = keyframeData.lighting.directionalLight.castsShadow
                }

                // Point Light
                if (keyframeData.lighting.pointLight) {
                    var pointLightPos = keyframeData.lighting.pointLight.position

                    pointLight.position = Qt.vector3d(pointLightPos.x, pointLightPos.y, pointLightPos.z)
                    pointLight.brightness = keyframeData.lighting.pointLight.brightness
                    pointLight.castsShadow = keyframeData.lighting.pointLight.castsShadow
                }
            }

            // Применяем состояние сцены
            if (keyframeData.scene) {
                view3d.environment.clearColor = keyframeData.scene.backgroundColor

                if (keyframeData.scene.gridEnabled !== gridManager.gridEnabled) {
                    gridManager.toggleGrid()
                }

                view3d.environment.antialiasingMode = keyframeData.scene.antialiasingMode
                view3d.environment.antialiasingQuality = keyframeData.scene.antialiasingQuality
            }

            console.log("Keyframe", frame + 1, "applied successfully")
            keyframeLoaded(frame, keyframeData)
            return true

        } catch (error) {
            console.log("Error applying keyframe", frame + 1, ":", error)
            return false
        }
    }

    // Удалить ключевой кадр
    function deleteKeyframe(frame) {
        console.log("KeyframeManager: Deleting keyframe for frame:", frame + 1)
        console.log("Keyframes before deletion:", Object.keys(keyframes))

        if (keyframes[frame]) {
            delete keyframes[frame]
            console.log("Keyframes after deletion:", Object.keys(keyframes))
            keyframeDeleted(frame)
            console.log("KeyframeManager: Keyframe", frame + 1, "deleted successfully")
            return true
        } else {
            console.log("KeyframeManager: No keyframe to delete for frame", frame + 1)
            return false
        }
    }

    // Проверить наличие ключевого кадра
    function hasKeyframe(frame) {
        return keyframes[frame] !== undefined
    }

    // Получить данные ключевого кадра
    function getKeyframe(frame) {
        return keyframes[frame] || null
    }

    // Получить список всех ключевых кадров
    function getAllKeyframes() {
        return Object.keys(keyframes).map(function(key) {
            return parseInt(key)
        }).sort(function(a, b) {
            return a - b
        })
    }

    // Экспорт всех ключевых кадров
    function exportKeyframes() {
        var exportData = {
            metadata: {
                version: "1.0",
                timestamp: new Date().toISOString(),
                totalFrames: Object.keys(keyframes).length,
                application: "Motion Plugin"
            },
            keyframes: keyframes
        }

        var json = JSON.stringify(exportData, null, 2)
        console.log("=== EXPORTED KEYFRAMES ===")
        console.log(json)
        console.log("=== END KEYFRAMES ===")

        return json
    }

    // Импорт ключевых кадров
    function importKeyframes(jsonData) {
        try {
            var importData = JSON.parse(jsonData)

            if (importData.keyframes) {
                keyframes = importData.keyframes
                console.log("Keyframes imported successfully. Total:", Object.keys(keyframes).length)
                return true
            } else {
                console.log("Invalid keyframes format")
                return false
            }
        } catch (error) {
            console.log("Error importing keyframes:", error)
            return false
        }
    }

    // Очистить все ключевые кадры
    function clearAllKeyframes() {
        keyframes = {}
        console.log("All keyframes cleared")
    }
}
