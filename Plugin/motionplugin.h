#ifndef MOTIONPLUGIN_H
#define MOTIONPLUGIN_H

#include <QObject>
#include <QtQml/QQmlApplicationEngine>
#include <QDebug>
#include <QUrl>
#include <QtQml/QQmlContext>
#include "pluginInterface.h"
#include "modelimporter.h"

class MotionPlugin : public QObject, public PluginInterface
{
    Q_OBJECT
    Q_INTERFACES(PluginInterface)
    Q_PLUGIN_METADATA(IID PluginInterface_iid FILE "Plugin.json")

public:
    explicit MotionPlugin(QObject *parent = nullptr);
    ~MotionPlugin();

    QString name() const override;
    bool initialize() override;
    void showUI() override;

private:
    QQmlApplicationEngine *m_engine;
    ModelImporter *m_modelImporter = nullptr;

};

#endif // MOTIONPLUGIN_H
