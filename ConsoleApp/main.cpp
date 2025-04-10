#include <QCoreApplication>
#include <QDir>
#include <QPluginLoader>
#include <QDebug>
#include <QtGui/QGuiApplication>
#include <QtQml/QQmlApplicationEngine>
#include "pluginInterface.h"

int main(int argc, char *argv[])
{
    QGuiApplication a(argc, argv);
    qDebug() << "Hello World";
    qDebug() << "Searching for plugins...";

    QDir pluginDir = QDir(QCoreApplication::applicationDirPath());
    pluginDir.cd("plugins");

    bool pluginFound = false;

    foreach (QString fileName, pluginDir.entryList(QDir::Files)) {
        QPluginLoader loader(pluginDir.absoluteFilePath(fileName));
        QObject *plugin = loader.instance();

        if (plugin) {
            PluginInterface *pluginInterface = qobject_cast<PluginInterface *>(plugin);
            if (pluginInterface) {
                pluginFound = true;
                qDebug() << "Plugin found: " << pluginInterface->name();

                if (pluginInterface->initialize()) {
                    qDebug() << "Plugin initialised successfuly";

                    pluginInterface->showUI();

                    return a.exec();
                } else {
                    qDebug() << "Error in plugin initialisation";
                }
            } else {
                loader.unload();
            }
        } else {
            qDebug() << "Error in download plugin: " << loader.errorString();
        }
    }

    if (!pluginFound) {
        qDebug() << "Plugins not found!";
    }


    return 0;
}
