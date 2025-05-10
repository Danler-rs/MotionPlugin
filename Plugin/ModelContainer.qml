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

Node {
    id: modelContainer

    // Публичные свойства
    property url source // URL к файлу модели
    property var modelManager // Ссылка на ModelManager
    property int modelIndex // Индекс в массиве моделей
    property string modelName // Имя модели для отображения
    property bool loaded: runtimeLoader.status === RuntimeLoader.Success
    property int status: runtimeLoader.status
    property bool selected: modelManager.selectedModelIndex === modelIndex

    // Свойство для доступа к границам модели
    property var bounds: runtimeLoader.bounds

    RuntimeLoader {
        id: runtimeLoader
        source: modelContainer.source

        onStatusChanged: {
            if (status === RuntimeLoader.Success) {
                // Когда модель загружена успешно
                console.log("Модель загружена успешно:", modelName);

                // Создаем бокс-контейнер, если модель выбрана
                if (modelContainer.selected) {
                    boundingBox.visible = true;
                }
            } else if (status === RuntimeLoader.Error) {
                console.error("Ошибка загрузки модели:", modelName, errorString);
            }
        }
    }

    // Контейнер для выделения выбранной модели
    Model {
        id: boundingBox
        visible: modelContainer.selected

        // Геометрия и материал будут устанавливаться динамически
        // при изменении bounds

        opacity: 0.2
        scale: Qt.vector3d(1.01, 1.01, 1.01) // Немного больше, чем сама модель

        // Обновляем позицию и размер контейнера при изменении границ
        Connections {
            target: runtimeLoader
            function onBoundsChanged() {
                if (runtimeLoader.bounds) {
                    var centerX = (runtimeLoader.bounds.maximum.x + runtimeLoader.bounds.minimum.x) / 2;
                    var centerY = (runtimeLoader.bounds.maximum.y + runtimeLoader.bounds.minimum.y) / 2;
                    var centerZ = (runtimeLoader.bounds.maximum.z + runtimeLoader.bounds.minimum.z) / 2;

                    var sizeX = runtimeLoader.bounds.maximum.x - runtimeLoader.bounds.minimum.x;
                    var sizeY = runtimeLoader.bounds.maximum.y - runtimeLoader.bounds.minimum.y;
                    var sizeZ = runtimeLoader.bounds.maximum.z - runtimeLoader.bounds.minimum.z;

                    boundingBox.position = Qt.vector3d(centerX, centerY, centerZ);
                    boundingBox.scale = Qt.vector3d(sizeX / 100, sizeY / 100, sizeZ / 100);
                }
            }
        }

        // Материал для выделения
        materials: [
            DefaultMaterial {
                diffuseColor: "skyblue"
                opacity: 0.2
            }
        ]
    }

    // Обновляем видимость bounding box при изменении selected
    onSelectedChanged: {
        if (runtimeLoader.status === RuntimeLoader.Success) {
            boundingBox.visible = selected;
        }
    }
}
