#include "motionplugin.h"

MotionPlugin::MotionPlugin(QObject *parent)
    : QObject(parent)
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
    return true;
}

void MotionPlugin::showUI()
{
    if (!m_engine) {
        qDebug() << "Error: engine Qml is not initialized";
        return;
    }

    m_engine->rootContext()->setContextProperty("plugin", this);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    m_engine->load(url);
}


