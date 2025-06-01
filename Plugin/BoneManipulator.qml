import QtQuick
import QtQuick3D

QtObject {
    id: root

    // Основные свойства
    property var skeletonAnalyzer
    property bool manipulationEnabled: false
    property var selectedBoneIndex: null
    property var selectedBoneData: null

    // Список всех костей из анализатора
    property var bonesList: []

    // Трансформации костей (виртуальные - не применяются к реальной модели)
    property var boneTransforms: ({})

    // Сигналы
    signal boneSelected(var boneIndex, var boneData)
    signal boneTransformChanged(var boneIndex, var transform)
    signal bonesListUpdated()

    function enableManipulation(enabled) {
        manipulationEnabled = enabled
        if (enabled) {
            updateBonesList()
        } else {
            clearBonesList()
        }
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

                // Инициализируем трансформацию кости (значения по умолчанию)
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

        boneTransformChanged(boneIndex, boneTransforms[boneIndex])
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
