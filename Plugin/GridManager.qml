import QtQuick

QtObject {
    id: root

    property bool gridEnabled: true

    function toggleGrid() {
        gridEnabled = !gridEnabled
    }

}
