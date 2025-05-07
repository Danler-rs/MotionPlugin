#include "motionplugin.h"
#include "modelimporter.h"
#include <QQmlContext>

MotionPlugin::MotionPlugin(QObject *parent)
    : QObject(parent)
    , m_modelImporter(new ModelImporter(this))
{}

MotionPlugin::~MotionPlugin()
{
    if (m_engine) {
        delete m_engine;
    }
}

QString MotionPlugin::name() const
{
    return "Motion Qml Plugin";
}

bool MotionPlugin::initialize()
{
    m_engine = new QQmlApplicationEngine();

    // Register the ModelImporter class with QML
    qmlRegisterType<ModelImporter>("MotionPlugin", 1, 0, "ModelImporter");

    return true;
}

void MotionPlugin::showUI()
{
    if (!m_engine) {
        qDebug() << "Error: engine Qml is not initialized";
        return;
    }

    m_engine->rootContext()->setContextProperty("plugin", this);
    m_engine->rootContext()->setContextProperty("modelImporter", m_modelImporter);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    m_engine->load(url);
}
