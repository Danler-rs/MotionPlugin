import QtQuick
import QtQuick3D.AssetUtils

QtObject {
    id: root

    // Основные свойства
    property var modelInfo: ({})
    property var displayModel: []
    property int totalNodes: 0
    property int skeletonNodesCount: 0

    // Внутренние данные
    property var _nodes: []

    function analyzeSkeleton(modelNode) {
        reset()

        if (!modelNode || modelNode.status !== RuntimeLoader.Success) {
            modelInfo = {"Status": "❌ Failed", "Error": "No model loaded"}
            return
        }

        modelInfo = {
            "Status": "✅ Success",
            "Source": extractFileName(modelNode.source.toString()),
            "Analysis Time": new Date().toLocaleTimeString()
        }

        console.log("=== Starting skeleton analysis ===")
        console.log("Analyzing model:", modelInfo["Source"])

        // Сначала собираем всю структуру
        traverseNode(modelNode, 0)

        // Затем анализируем на предмет скелетных структур
        analyzeSkeletonStructure()

        updateStats()
        displayModel = _nodes.slice()
        console.log("Analysis complete. Found", totalNodes, "nodes,", skeletonNodesCount, "skeleton nodes")
    }

    function analyzeSkeletonStructure() {
        // Постобработка для более точного определения костей
        // Ищем иерархические цепочки узлов без геометрии - потенциальные кости

        for (var i = 0; i < _nodes.length; i++) {
            var node = _nodes[i]

            // Если узел имеет детей, не имеет геометрии и является частью цепочки
            if (node.type === "Empty" && node.hasChildren) {
                var childrenAreEmpty = true
                var hasDeepHierarchy = false

                // Проверяем глубину иерархии
                for (var j = i + 1; j < _nodes.length && _nodes[j].level > node.level; j++) {
                    if (_nodes[j].level > node.level + 2) {
                        hasDeepHierarchy = true
                        break
                    }
                }

                // Если это глубокая иерархия узлов без геометрии - вероятно скелет
                if (hasDeepHierarchy) {
                    console.log("Potential skeleton chain detected starting from:", node.name)
                    _nodes[i].type = "Bone"
                    _nodes[i].name = "Bone_" + node.name.replace("Node_", "")

                    // Помечаем детей как кости тоже
                    for (var k = i + 1; k < _nodes.length && _nodes[k].level > node.level; k++) {
                        if (_nodes[k].type === "Empty") {
                            _nodes[k].type = "Bone"
                            _nodes[k].name = "Bone_" + _nodes[k].name.replace("Node_", "")
                        }
                    }
                }
            }
        }
    }

    function traverseNode(node, level) {
        if (!node) return

        var name = getNodeName(node)
        var type = getNodeType(node)
        var isSkeleton = isSkeletonNode(node, type)

        var nodeInfo = {
            level: level,
            name: name,
            type: type,
            hasChildren: hasChildren(node),
            properties: getNodeProperties(node, isSkeleton)
        }

        _nodes.push(nodeInfo)
        console.log("  ".repeat(level) + "Found:", name, "(" + type + ")")

        // Рекурсивно обходим детей
        try {
            if (node.children && node.children.length > 0) {
                for (var i = 0; i < node.children.length; i++) {
                    traverseNode(node.children[i], level + 1)
                }
            }
        } catch (e) {
            console.log("Could not access children for", name, ":", e.toString())
        }
    }

    function getNodeName(node) {
        try {
            // Пытаемся получить имя из разных источников
            if (node.objectName && node.objectName !== "") return node.objectName
            if (typeof node.name !== 'undefined' && node.name !== "") return node.name

            // Для glTF узлов пробуем получить имя из внутренней структуры
            var nodeStr = node.toString()

            // Ищем паттерны имен костей/узлов
            var patterns = [
                /objectName["\s]*[:=]["\s]*([^"'\s,}]+)/,
                /name["\s]*[:=]["\s]*([^"'\s,}]+)/,
                /"([^"]*(?:bone|joint|armature|spine|head|arm|leg|foot|hand)[^"]*)"?/i
            ]

            for (var i = 0; i < patterns.length; i++) {
                var match = nodeStr.match(patterns[i])
                if (match && match[1] && match[1].length > 0) {
                    return match[1].replace(/['"]/g, '')
                }
            }

            // Если это потенциально кость, даем осмысленное имя
            if (isPotentialBone(node)) {
                return "Bone_" + _nodes.length
            }

            return "Node_" + _nodes.length
        } catch (e) {
            return "UnknownNode_" + _nodes.length
        }
    }

    function getNodeType(node) {
        try {
            var str = node.toString()

            // Улучшенное определение скелетных структур
            if (str.includes("Skeleton") || str.includes("Armature")) return "Armature"
            if (str.includes("Joint") || str.includes("Bone")) return "Bone"

            // Проверяем по структуре узла - если это потенциально кость
            if (isPotentialBone(node)) return "Bone"

            // Геометрия и меши
            if (str.includes("Model") && hasGeometry(node)) return "Mesh"
            if (str.includes("Geometry")) return "Geometry"

            // Камеры
            if (str.includes("Camera") || str.includes("PerspectiveCamera") ||
                str.includes("OrthographicCamera")) return "Camera"

            // Освещение
            if (str.includes("Light") || str.includes("DirectionalLight") ||
                str.includes("PointLight") || str.includes("SpotLight")) return "Light"

            // Материалы и текстуры
            if (str.includes("Material")) return "Material"
            if (str.includes("Texture")) return "Texture"

            // Анимация
            if (str.includes("Animation")) return "Animation"

            // Проверяем, является ли узел частью скелетной иерархии
            if (isPartOfSkeleton(node)) return "Bone"

            // Группы и Empty объекты
            if (str.includes("Node") && hasChildren(node) && !hasGeometry(node)) return "Empty"
            if (str.includes("Model") && !hasGeometry(node)) return "Empty"

            // Обычные узлы
            if (str.includes("Node")) return "Object"
            if (str.includes("Model")) return "Object"

            return "Unknown"
        } catch (e) {
            return "Unknown"
        }
    }

    function isPotentialBone(node) {
        try {
            // Проверяем признаки кости:
            // 1. Имеет детей но не имеет геометрии
            // 2. Имеет трансформацию (позицию/поворот)
            // 3. Является частью иерархической структуры

            var hasChildrenButNoGeometry = hasChildren(node) && !hasGeometry(node)
            var hasTransform = hasTransformation(node)
            var str = node.toString()

            // Дополнительные признаки костей в glTF
            var hasJointIndicators = str.includes("joint") ||
                                   str.includes("transform") ||
                                   str.includes("matrix") ||
                                   str.includes("skin")

            return (hasChildrenButNoGeometry && hasTransform) || hasJointIndicators
        } catch (e) {
            return false
        }
    }

    function isPartOfSkeleton(node) {
        try {
            // Проверяем, является ли узел частью скелетной структуры
            // по косвенным признакам

            var parentHasSkin = false
            var siblingIsBone = false

            // Дополнительные проверки можно добавить здесь
            // для более точного определения скелетной структуры

            return parentHasSkin || siblingIsBone
        } catch (e) {
            return false
        }
    }

    function hasGeometry(node) {
        try {
            return typeof node.geometry !== 'undefined' ||
                   typeof node.source !== 'undefined'
        } catch (e) {
            return false
        }
    }

    function getNodeIcon(type, isSkeleton) {
        switch(type) {
            case "Armature": return "🦴"
            case "Bone": return "🦴"
            case "Mesh": return "▲"
            case "Geometry": return "📐"
            case "Camera": return "📷"
            case "Light": return "💡"
            case "Material": return "🎨"
            case "Texture": return "🖼️"
            case "Animation": return "🎬"
            case "Empty": return "📁"
            case "Object": return "🔳"
            default: return "❓"
        }
    }

    function hasChildren(node) {
        try {
            return node.children && node.children.length > 0
        } catch (e) {
            return false
        }
    }

    function isSkeletonNode(node, type) {
        try {
            return type === "Bone" || type === "Armature" ||
                   (typeof node.skeleton !== 'undefined') ||
                   (typeof node.skin !== 'undefined') ||
                   node.toString().includes("Joint")
        } catch (e) {
            return false
        }
    }

    function getNodeProperties(node, isSkeleton) {
        var props = []

        try {
            var type = getNodeType(node)

            // Добавляем иконку и тип как в Blender
            props.push(getNodeIcon(type, isSkeleton) + " " + type)

            if (isSkeleton) {
                props.push("🦴 Skeleton Component")
            }

            // Информация о детях
            if (hasChildren(node)) {
                props.push("👥 Children: " + node.children.length)
            }

            // Дополнительная информация по типам
            if (type === "Mesh" || type === "Object") {
                if (typeof node.source !== 'undefined') {
                    props.push("📄 Source: " + extractFileName(node.source.toString()))
                }
            }

            if (type === "Camera") {
                if (typeof node.fieldOfView !== 'undefined') {
                    props.push("🔍 FOV: " + node.fieldOfView + "°")
                }
            }

            if (type === "Light") {
                if (typeof node.brightness !== 'undefined') {
                    props.push("💡 Brightness: " + node.brightness)
                }
            }

            // Информация о трансформации (если не нулевая)
            if (hasTransformation(node)) {
                props.push("🔄 Has Transformation")
            }

        } catch (e) {
            props.push("⚠️ Property access error")
        }

        return props
    }

    function hasTransformation(node) {
        try {
            var pos = node.position
            var rot = node.eulerRotation
            var scale = node.scale

            return (pos && (pos.x !== 0 || pos.y !== 0 || pos.z !== 0)) ||
                   (rot && (rot.x !== 0 || rot.y !== 0 || rot.z !== 0)) ||
                   (scale && (scale.x !== 1 || scale.y !== 1 || scale.z !== 1))
        } catch (e) {
            return false
        }
    }

    function updateStats() {
        totalNodes = _nodes.length
        skeletonNodesCount = _nodes.filter(function(n) {
            return n.type === "Bone" || n.type === "Armature"
        }).length

        // Статистика по типам (как в Blender)
        var stats = {}
        _nodes.forEach(function(node) {
            stats[node.type] = (stats[node.type] || 0) + 1
        })

        console.log("=== Node Type Statistics ===")
        Object.keys(stats).forEach(function(type) {
            console.log(type + ":", stats[type])
        })
    }

    function reset() {
        _nodes = []
        displayModel = []
        totalNodes = 0
        skeletonNodesCount = 0
        modelInfo = {}
    }

    function extractFileName(path) {
        return path.split('/').pop().split('\\').pop()
    }

    function exportToConsole() {
        console.log("=== SKELETON ANALYSIS ===")
        console.log("Nodes:", totalNodes, "Skeleton nodes:", skeletonNodesCount)
        _nodes.forEach(function(node) {
            console.log("  ".repeat(node.level) + node.name + " (" + node.type + ")")
        })
    }
}
