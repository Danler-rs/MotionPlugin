import QtQuick
import QtQuick3D
import QtQuick3D.Helpers
import MotionPlugin 1.0

Node {
    id: modelNode

    property alias source: modelObject.source
    property alias material: modelObject.materials
    property bool gridEnabled: false
    property bool axisEnabled: false
    property bool wireframeEnabled: false

    // Сигналы для обработки изменений
    signal modelLoaded(string modelSource)

    Model {
        id: modelObject
        source: "#Cube" // По умолчанию показываем куб
        materials: PrincipledMaterial {
            baseColor: "lightgray"
            metalness: 0.1
            roughness: 0.5
        }

        AxisHelper {
            id: axisHelper
            enableAxisLines: axisEnabled
            enableXYGrid: false
            enableXZGrid: gridEnabled
        }
    }

    // Функция для загрузки модели
    function loadModel(modelSource) {
        console.log("Loading model from:", modelSource)
        modelObject.source = modelSource
        modelLoaded(modelSource)
    }
}
