#ifndef ANIMATIONEXPORTER_H
#define ANIMATIONEXPORTER_H

#include <QObject>
#include <QProcess>
#include <QTimer>
#include <QQuickItem>
#include <QQuickWindow>
#include <QQuickRenderControl>
#include <QOpenGLFramebufferObject>
#include <QOpenGLContext>
#include <QOffscreenSurface>
#include <QQmlEngine>
#include <QQmlComponent>
#include <QDir>
#include <QStandardPaths>
#include <QDebug>
#include <QImage>
#include <QGuiApplication>

class AnimationExporter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isExporting READ isExporting NOTIFY isExportingChanged)
    Q_PROPERTY(int currentFrame READ currentFrame NOTIFY currentFrameChanged)
    Q_PROPERTY(int totalFrames READ totalFrames NOTIFY totalFramesChanged)
    Q_PROPERTY(QString exportPath READ exportPath WRITE setExportPath NOTIFY exportPathChanged)
    Q_PROPERTY(int frameRate READ frameRate WRITE setFrameRate NOTIFY frameRateChanged)
    Q_PROPERTY(QString status READ status NOTIFY statusChanged)

public:
    explicit AnimationExporter(QObject *parent = nullptr);
    ~AnimationExporter();

    // Properties
    bool isExporting() const { return m_isExporting; }
    int currentFrame() const { return m_currentFrame; }
    int totalFrames() const { return m_totalFrames; }
    QString exportPath() const { return m_exportPath; }
    int frameRate() const { return m_frameRate; }
    QString status() const { return m_status; }

    void setExportPath(const QString &path);
    void setFrameRate(int rate);

public slots:
    void startExport(QObject *keyframeManager, QObject *view3d, int width = 1920, int height = 1080);
    void stopExport();
    bool checkFFmpegAvailable();

signals:
    void isExportingChanged();
    void currentFrameChanged();
    void totalFramesChanged();
    void exportPathChanged();
    void frameRateChanged();
    void statusChanged();
    void exportCompleted(bool success, const QString &message);
    void exportProgress(int frame, int total, const QString &status);

private slots:
    void captureNextFrame();
    void onFFmpegFinished(int exitCode, QProcess::ExitStatus exitStatus);
    void onFFmpegError(QProcess::ProcessError error);

private:
    void setupDirectories();
    void captureFrame(int frameIndex);
    void loadKeyframe(int frameIndex);
    void generateVideo();
    void cleanup();
    void setStatus(const QString &status);
    QString getFFmpegPath();
    QImage captureView3D();

    // Core objects
    QObject *m_keyframeManager;
    QObject *m_view3d;

    // Export settings
    bool m_isExporting;
    int m_currentFrame;
    int m_totalFrames;
    QString m_exportPath;
    int m_frameRate;
    QString m_status;

    // Rendering
    int m_renderWidth;
    int m_renderHeight;

    // Frame capture
    QTimer *m_captureTimer;
    QStringList m_keyframes;
    QString m_tempDir;
    QStringList m_capturedFrames;

    // FFmpeg process
    QProcess *m_ffmpegProcess;

    // Rendering context
    QOpenGLContext *m_context;
    QOffscreenSurface *m_surface;
    QOpenGLFramebufferObject *m_fbo;
};

#endif // ANIMATIONEXPORTER_H
