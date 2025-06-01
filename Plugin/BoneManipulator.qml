import QtQuick
import QtQuick3D

QtObject {
    id: root

    // Основные свойства
    property var skeletonAnalyzer
    property bool manipulationEnabled: false
    property var selectedBoneIndex: null
    property var selectedBoneData: null

    // Ссылка на загруженную модель для применения трансформаций
    property var loadedModel: null

    // Список всех костей из анализатора
    property var bonesList: []

    // Трансформации костей (относительные изменения)
    property var boneTransforms: ({})

    // Исходные трансформации костей (для правильного reset)
    property var originalTransforms: ({})

    // Кэш реальных узлов модели для быстрого доступа
    property var modelNodes: []

    // Сигналы
    signal boneSelected(var boneIndex, var boneData)
    signal boneTransformChanged(var boneIndex, var transform)
    signal bonesListUpdated()

    function enableManipulation(enabled) {
        manipulationEnabled = enabled
        if (enabled) {
            updateBonesList()
            cacheModelNodes()
            saveOriginalTransforms()
        } else {
            clearBonesList()
        }
    }

    function setLoadedModel(model) {
        loadedModel = model
        if (manipulationEnabled) {
            cacheModelNodes()
            saveOriginalTransforms()
        }
    }

    function cacheModelNodes() {
        if (!loadedModel) {
            console.log("No loaded model available for bone manipulation")
            return
        }

        console.log("Caching model nodes for bone manipulation...")
        modelNodes = []

        // Рекурсивно собираем все узлы модели
        collectNodes(loadedModel, 0)

        console.log("Cached", modelNodes.length, "model nodes")
    }

    function collectNodes(node, index) {
        if (!node) return index

        modelNodes[index] = node

        try {
            if (node.children && node.children.length > 0) {
                for (var i = 0; i < node.children.length; i++) {
                    index = collectNodes(node.children[i], index + 1)
                }
            }
        } catch (e) {
            console.log("Error collecting child nodes:", e)
        }

        return index
    }

    function saveOriginalTransforms() {
        console.log("Saving original transforms...")

        for (var i = 0; i < modelNodes.length; i++) {
            var node = modelNodes[i]
            if (node) {
                try {
                    originalTransforms[i] = {
                        position: {
                            x: node.position ? node.position.x : 0,
                            y: node.position ? node.position.y : 0,
                            z: node.position ? node.position.z : 0
                        },
                        rotation: {
                            x: node.eulerRotation ? node.eulerRotation.x : 0,
                            y: node.eulerRotation ? node.eulerRotation.y : 0,
                            z: node.eulerRotation ? node.eulerRotation.z : 0
                        },
                        scale: {
                            x: node.scale ? node.scale.x : 1,
                            y: node.scale ? node.scale.y : 1,
                            z: node.scale ? node.scale.z : 1
                        }
                    }
                } catch (e) {
                    console.log("Error saving original transform for node", i, ":", e)
                }
            }
        }

        console.log("Saved original transforms for", Object.keys(originalTransforms).length, "nodes")
    }

    function updateBonesList() {
        if (!skeletonAnalyzer) {
            console.log("No skeleton analyzer available")
            return
        }

        console.log("Updating bones list...")

        var bones = []
        var nodes = skeletonAnalyzer.displayModel

        for (var i = 0; i < nodes.length; i++) {
            var nodeData = nodes[i]
            if (nodeData.type === "Bone" || nodeData.type === "Armature") {
                bones.push({
                    index: i,
                    name: nodeData.name || ("Bone_" + i),
                    type: nodeData.type,
                    level: nodeData.level || 0,
                    hasChildren: nodeData.hasChildren || false
                })

                // Инициализируем трансформацию кости (значения по умолчанию - без изменений)
                if (!boneTransforms[i]) {
                    boneTransforms[i] = {
                        position: { x: 0, y: 0, z: 0 },
                        rotation: { x: 0, y: 0, z: 0 },
                        scale: { x: 1, y: 1, z: 1 }
                    }
                }
            }
        }

        bonesList = bones
        console.log("Found", bones.length, "bones")
        bonesListUpdated()
    }

    function clearBonesList() {
        bonesList = []
        boneTransforms = {}
        originalTransforms = {}
        modelNodes = []
        selectedBoneIndex = null
        selectedBoneData = null
        bonesListUpdated()
    }

    function selectBone(boneIndex) {
        console.log("Selecting bone:", boneIndex)

        selectedBoneIndex = boneIndex

        if (boneIndex !== null && boneIndex < bonesList.length) {
            selectedBoneData = bonesList[boneIndex]
        } else {
            selectedBoneData = null
        }

        boneSelected(selectedBoneIndex, selectedBoneData)
    }

    function getBoneTransform(boneIndex) {
        return boneTransforms[boneIndex] || {
            position: { x: 0, y: 0, z: 0 },
            rotation: { x: 0, y: 0, z: 0 },
            scale: { x: 1, y: 1, z: 1 }
        }
    }

    function setBoneTransform(boneIndex, transform) {
        if (boneIndex === null || boneIndex < 0) return

        console.log("Setting bone transform for bone", boneIndex, ":", JSON.stringify(transform))

        boneTransforms[boneIndex] = {
            position: {
                x: transform.position ? transform.position.x : 0,
                y: transform.position ? transform.position.y : 0,
                z: transform.position ? transform.position.z : 0
            },
            rotation: {
                x: transform.rotation ? transform.rotation.x : 0,
                y: transform.rotation ? transform.rotation.y : 0,
                z: transform.rotation ? transform.rotation.z : 0
            },
            scale: {
                x: transform.scale ? transform.scale.x : 1,
                y: transform.scale ? transform.scale.y : 1,
                z: transform.scale ? transform.scale.z : 1
            }
        }

        // Применяем трансформацию к реальной модели
        applyTransformToModel(boneIndex, boneTransforms[boneIndex])

        boneTransformChanged(boneIndex, boneTransforms[boneIndex])
    }

    function applyTransformToModel(boneIndex, transform) {
        if (!loadedModel || boneIndex >= modelNodes.length) {
            console.log("Cannot apply transform: no model or invalid bone index")
            return
        }

        var targetNode = modelNodes[boneIndex]
        if (!targetNode) {
            console.log("Target node not found for bone index:", boneIndex)
            return
        }

        var original = originalTransforms[boneIndex]
        if (!original) {
            console.log("No original transform found for bone index:", boneIndex)
            return
        }

        try {
            // Применяем позицию (исходная + изменение)
            if (transform.position) {
                var newPosition = Qt.vector3d(
                    original.position.x + transform.position.x,
                    original.position.y + transform.position.y,
                    original.position.z + transform.position.z
                )
                targetNode.position = newPosition
            }

            // Применяем поворот (исходный + изменение)
            if (transform.rotation) {
                var newRotation = Qt.vector3d(
                    original.rotation.x + transform.rotation.x,
                    original.rotation.y + transform.rotation.y,
                    original.rotation.z + transform.rotation.z
                )
                targetNode.eulerRotation = newRotation
            }

            // Применяем масштаб (исходный * изменение)
            if (transform.scale) {
                var newScale = Qt.vector3d(
                    original.scale.x * transform.scale.x,
                    original.scale.y * transform.scale.y,
                    original.scale.z * transform.scale.z
                )
                targetNode.scale = newScale
            }

            console.log("Applied transform to node", boneIndex, "successfully")
        } catch (e) {
            console.log("Error applying transform to node", boneIndex, ":", e)
        }
    }

    function updateBonePosition(boneIndex, x, y, z) {
        if (boneIndex === null) return

        var transform = getBoneTransform(boneIndex)
        transform.position = { x: x, y: y, z: z }
        setBoneTransform(boneIndex, transform)
    }

    function updateBoneRotation(boneIndex, x, y, z) {
        if (boneIndex === null) return

        var transform = getBoneTransform(boneIndex)
        transform.rotation = { x: x, y: y, z: z }
        setBoneTransform(boneIndex, transform)
    }

    function updateBoneScale(boneIndex, x, y, z) {
        if (boneIndex === null) return

        var transform = getBoneTransform(boneIndex)
        transform.scale = { x: x, y: y, z: z }
        setBoneTransform(boneIndex, transform)
    }

    function resetBone(boneIndex) {
        if (boneIndex === null) return

        console.log("Resetting bone:", boneIndex)

        var defaultTransform = {
            position: { x: 0, y: 0, z: 0 },
            rotation: { x: 0, y: 0, z: 0 },
            scale: { x: 1, y: 1, z: 1 }
        }

        setBoneTransform(boneIndex, defaultTransform)
    }

    function resetAllBones() {
        console.log("Resetting all bones")

        for (var i = 0; i < bonesList.length; i++) {
            resetBone(bonesList[i].index)
        }
    }

    function exportPose() {
        var pose = {
            metadata: {
                version: "1.0",
                timestamp: new Date().toISOString(),
                boneCount: bonesList.length
            },
            bones: {}
        }

        for (var key in boneTransforms) {
            pose.bones[key] = boneTransforms[key]
        }

        return JSON.stringify(pose, null, 2)
    }

    function importPose(poseJson) {
        try {
            var pose = JSON.parse(poseJson)

            if (pose.bones) {
                for (var key in pose.bones) {
                    var boneIndex = parseInt(key)
                    if (boneIndex >= 0 && boneIndex < bonesList.length) {
                        setBoneTransform(boneIndex, pose.bones[key])
                    }
                }
                console.log("Pose imported successfully")
                return true
            } else {
                console.log("Invalid pose format")
                return false
            }
        } catch (e) {
            console.log("Error importing pose:", e)
            return false
        }
    }

    function getBoneDisplayName(boneData) {
        if (!boneData) return "Unknown"

        var indent = "  ".repeat(boneData.level || 0)
        var icon = boneData.type === "Armature" ? "🦴" : "🔗"

        return indent + icon + " " + boneData.name
    }
}
