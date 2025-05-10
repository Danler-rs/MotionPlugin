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

QtObject {
    id: root

    // Публичные свойства
    property Node parentNode // Родительский узел для моделей
    property CameraHelper cameraHelper
    property var models: [] // Массив моделей

    // Модель данных для ListView
    property ListModel modelListModel: ListModel {}

    // Свойство для текущей выбранной модели
    property int selectedModelIndex: -1

    // Сигналы
    signal modelAdded(string name, int index)
    signal modelRemoved(int index)
    signal modelSelected(int index)

    // Метод для импорта новой модели
    function importModel(url) {
        if (!url || url.toString() === "") {
            console.warn("Пустой URL при попытке импорта модели");
            return;
        }

        console.log("Импорт модели:", url.toString());

        // Создаём компонент RuntimeLoader
        var component = Qt.createComponent("ModelContainer.qml");
        if (component.status === Component.Ready) {
            // Создаём экземпляр с уникальным ID
            var modelName = getModelName(url.toString());
            var modelContainer = component.createObject(parentNode, {
                "source": url,
                "modelManager": root,
                "modelIndex": models.length,
                "modelName": modelName
            });

            // Добавляем в массив моделей
            models.push(modelContainer);

            // Добавляем в модель для ListView
            modelListModel.append({
                "name": modelName,
                "visible": true,
                "index": models.length - 1
            });

            // Устанавливаем новую модель как выбранную
            selectedModelIndex = models.length - 1;

            // Настраиваем обработку событий загрузки
            modelContainer.loadedChanged.connect(function() {
                if (modelContainer.loaded) {
                    console.log("Модель успешно загружена:", modelName);
                    updateBounds();
                } else if (modelContainer.status === RuntimeLoader.Error) {
                    console.error("Ошибка загрузки модели:", modelName);
                }
            });

            // Отправляем сигнал о добавлении модели
            modelAdded(modelName, models.length - 1);
        } else {
            console.error("Ошибка создания компонента:", component.errorString());
        }
    }

    // Метод для получения имени модели из URL
    function getModelName(urlString) {
        var pathParts = urlString.split('/');
        var fileName = pathParts[pathParts.length - 1];
        // Убираем параметры URL, если они есть
        var cleanFileName = fileName.split('?')[0];
        return decodeURIComponent(cleanFileName);
    }

    // Метод для выбора модели
    function selectModel(index) {
        if (index >= 0 && index < models.length) {
            selectedModelIndex = index;
            modelSelected(index);
        }
    }

    // Метод для переключения видимости модели
    function toggleModelVisibility(index) {
        if (index >= 0 && index < models.length) {
            var model = models[index];
            model.visible = !model.visible;

            // Обновляем данные в модели списка
            modelListModel.setProperty(index, "visible", model.visible);
        }
    }

    // Метод для удаления модели
    function removeModel(index) {
        if (index >= 0 && index < models.length) {
            // Удаляем объект 3D модели
            var modelToRemove = models[index];
            modelToRemove.destroy();

            // Удаляем элемент из массива моделей
            models.splice(index, 1);

            // Удаляем из модели списка
            modelListModel.remove(index);

            // Корректируем индексы оставшихся моделей
            for (var i = index; i < models.length; i++) {
                models[i].modelIndex = i;
                modelListModel.setProperty(i, "index", i);
            }

            // Если удалили выбранную модель, сбрасываем выбор или выбираем другую
            if (selectedModelIndex === index) {
                if (models.length > 0) {
                    selectedModelIndex = Math.min(index, models.length - 1);
                    modelSelected(selectedModelIndex);
                } else {
                    selectedModelIndex = -1;
                }
            } else if (selectedModelIndex > index) {
                // Если удаленная модель была перед выбранной, корректируем индекс
                selectedModelIndex--;
            }

            // Обновляем границы сцены
            updateBounds();

            // Отправляем сигнал об удалении модели
            modelRemoved(index);
        }
    }

    // Метод для обновления границ сцены на основе всех моделей
    function updateBounds() {
        if (models.length === 0) {
            // Если моделей нет, устанавливаем какие-то базовые границы
            var defaultBounds = {
                minimum: Qt.vector3d(-100, -100, -100),
                maximum: Qt.vector3d(100, 100, 100)
            };
            cameraHelper.updateBounds(defaultBounds);
            return;
        }

        // Инициализируем общие границы первой видимой моделью
        var combinedBounds = null;

        for (var i = 0; i < models.length; i++) {
            if (!models[i].visible || !models[i].loaded) continue;

            var modelBounds = models[i].bounds;
            if (!modelBounds) continue;

            if (!combinedBounds) {
                combinedBounds = {
                    minimum: Qt.vector3d(modelBounds.minimum.x, modelBounds.minimum.y, modelBounds.minimum.z),
                    maximum: Qt.vector3d(modelBounds.maximum.x, modelBounds.maximum.y, modelBounds.maximum.z)
                };
            } else {
                // Расширяем общие границы
                combinedBounds.minimum.x = Math.min(combinedBounds.minimum.x, modelBounds.minimum.x);
                combinedBounds.minimum.y = Math.min(combinedBounds.minimum.y, modelBounds.minimum.y);
                combinedBounds.minimum.z = Math.min(combinedBounds.minimum.z, modelBounds.minimum.z);

                combinedBounds.maximum.x = Math.max(combinedBounds.maximum.x, modelBounds.maximum.x);
                combinedBounds.maximum.y = Math.max(combinedBounds.maximum.y, modelBounds.maximum.y);
                combinedBounds.maximum.z = Math.max(combinedBounds.maximum.z, modelBounds.maximum.z);
            }
        }

        if (combinedBounds) {
            cameraHelper.updateBounds(combinedBounds);
        } else {
            // Если не нашли ни одной видимой модели с границами
            var defaultBounds = {
                minimum: Qt.vector3d(-100, -100, -100),
                maximum: Qt.vector3d(100, 100, 100)
            };
            cameraHelper.updateBounds(defaultBounds);
        }
    }
}
