#include "AnimationExporter.h"
#include <QCoreApplication>
#include <QFileInfo>
#include <QImageWriter>
#include <QMetaObject>
#include <QVariant>
#include <algorithm>

AnimationExporter::AnimationExporter(QObject *parent)
    : QObject(parent)
    , m_keyframeManager(nullptr)
    , m_view3d(nullptr)
    , m_isExporting(false)
    , m_currentFrame(0)
    , m_totalFrames(0)
    , m_frameRate(24)
    , m_status("Ready")
    , m_renderWidth(1920)
    , m_renderHeight(1080)
    , m_captureTimer(new QTimer(this))
    , m_ffmpegProcess(new QProcess(this))
    , m_context(nullptr)
    , m_surface(nullptr)
    , m_fbo(nullptr)
{
    m_captureTimer->setSingleShot(true);
    connect(m_captureTimer, &QTimer::timeout, this, &AnimationExporter::captureNextFrame);

    connect(m_ffmpegProcess, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &AnimationExporter::onFFmpegFinished);
    connect(m_ffmpegProcess, &QProcess::errorOccurred,
            this, &AnimationExporter::onFFmpegError);

    // Setup default export path
    QString defaultPath = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
    if (defaultPath.isEmpty()) {
        defaultPath = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    }
    m_exportPath = defaultPath + "/animation.mp4";
}

AnimationExporter::~AnimationExporter()
{
    cleanup();
}

void AnimationExporter::setExportPath(const QString &path)
{
    if (m_exportPath != path) {
        // ИСПРАВЛЕНО: Очистка пути от file:// и неправильных слешей
        QString cleanPath = path;
        if (cleanPath.startsWith("file:///")) {
            cleanPath = cleanPath.mid(8); // Убираем "file:///"
        } else if (cleanPath.startsWith("file://")) {
            cleanPath = cleanPath.mid(7); // Убираем "file://"
        }

        // Убираем лишний слеш в начале для Windows путей
        if (cleanPath.startsWith("/") && cleanPath.length() > 1 && cleanPath.at(2) == ':') {
            cleanPath = cleanPath.mid(1);
        }

        m_exportPath = QDir::toNativeSeparators(cleanPath);
        emit exportPathChanged();
        qDebug() << "Export path set to:" << m_exportPath;
    }
}

void AnimationExporter::setFrameRate(int rate)
{
    if (m_frameRate != rate && rate >= 2) {
        m_frameRate = rate;
        emit frameRateChanged();
    }
}

void AnimationExporter::startExport(QObject *keyframeManager, QObject *view3d, int width, int height)
{
    if (m_isExporting) {
        qDebug() << "Export already in progress";
        return;
    }

    if (!keyframeManager || !view3d) {
        setStatus("Error: Invalid keyframe manager or view3d");
        emit exportCompleted(false, "Invalid objects provided");
        return;
    }

    // Check FFmpeg availability
    if (!checkFFmpegAvailable()) {
        setStatus("Error: FFmpeg not found");
        emit exportCompleted(false, "FFmpeg executable not found. Please ensure ffmpeg.exe is in the project directory.");
        return;
    }

    m_keyframeManager = keyframeManager;
    m_view3d = view3d;
    m_renderWidth = width;
    m_renderHeight = height;

    // Get keyframes list from keyframe manager
    QVariant keyframesVar;
    bool success = QMetaObject::invokeMethod(m_keyframeManager, "getAllKeyframes",
                                             Q_RETURN_ARG(QVariant, keyframesVar));

    if (!success) {
        setStatus("Error: Failed to get keyframes");
        emit exportCompleted(false, "Failed to get keyframes from manager");
        return;
    }

    QVariantList keyframesList = keyframesVar.toList();
    if (keyframesList.isEmpty()) {
        setStatus("Error: No keyframes found");
        emit exportCompleted(false, "No keyframes found. Please create some keyframes first.");
        return;
    }

    // Convert to string list and sort
    m_keyframes.clear();
    QList<int> frameNumbers;
    for (const QVariant &frame : keyframesList) {
        frameNumbers.append(frame.toInt());
    }

    // Sort frame numbers
    std::sort(frameNumbers.begin(), frameNumbers.end());

    // Convert back to string list
    for (int frameNum : frameNumbers) {
        m_keyframes.append(QString::number(frameNum));
    }

    m_totalFrames = m_keyframes.size();
    m_currentFrame = 0;
    m_capturedFrames.clear();

    emit totalFramesChanged();
    emit currentFrameChanged();

    setupDirectories();

    m_isExporting = true;
    emit isExportingChanged();

    setStatus("Starting export...");
    qDebug() << "Starting animation export with" << m_totalFrames << "keyframes";

    // Start capturing frames
    m_captureTimer->start(100); // Small delay to let UI update
}

void AnimationExporter::stopExport()
{
    if (!m_isExporting) return;

    m_captureTimer->stop();

    if (m_ffmpegProcess->state() != QProcess::NotRunning) {
        m_ffmpegProcess->kill();
        m_ffmpegProcess->waitForFinished(3000);
    }

    m_isExporting = false;
    emit isExportingChanged();

    setStatus("Export cancelled");
    cleanup();

    emit exportCompleted(false, "Export was cancelled by user");
}

bool AnimationExporter::checkFFmpegAvailable()
{
    QString ffmpegPath = getFFmpegPath();
    QFileInfo ffmpegInfo(ffmpegPath);

    bool available = ffmpegInfo.exists() && ffmpegInfo.isExecutable();
    qDebug() << "FFmpeg check:" << ffmpegPath << "- Available:" << available;

    return available;
}

void AnimationExporter::captureNextFrame()
{
    if (!m_isExporting || m_currentFrame >= m_totalFrames) {
        // All frames captured, generate video
        generateVideo();
        return;
    }

    int frameIndex = m_keyframes[m_currentFrame].toInt();
    setStatus(QString("Capturing frame %1 of %2 (keyframe %3)")
                  .arg(m_currentFrame + 1)
                  .arg(m_totalFrames)
                  .arg(frameIndex + 1));

    emit exportProgress(m_currentFrame + 1, m_totalFrames, m_status);

    // Load keyframe
    loadKeyframe(frameIndex);

    // Capture frame after small delay to let scene update
    QTimer::singleShot(200, [this, frameIndex]() {
        captureFrame(frameIndex);
        m_currentFrame++;
        emit currentFrameChanged();

        // Schedule next frame capture
        m_captureTimer->start(100);
    });
}

void AnimationExporter::setupDirectories()
{
    // Create temporary directory for frames
    m_tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation) +
                "/MotionPlugin_" + QString::number(QCoreApplication::applicationPid());

    QDir().mkpath(m_tempDir);
    qDebug() << "Created temp directory:" << m_tempDir;
}

void AnimationExporter::captureFrame(int frameIndex)
{
    // Находим и временно скрываем таймлайн
    QQuickItem *timeline = nullptr;
    if (m_view3d) {
        QQuickItem *view3dItem = qobject_cast<QQuickItem*>(m_view3d);
        if (view3dItem && view3dItem->window()) {
            // Ищем таймлайн в корневом элементе окна
            QQuickItem *rootItem = view3dItem->window()->contentItem();
            timeline = findTimelineItem(rootItem);
        }
    }

    bool timelineWasVisible = false;
    if (timeline) {
        timelineWasVisible = timeline->isVisible();
        timeline->setVisible(false);
        qDebug() << "Timeline hidden for capture";
    }

    // Небольшая задержка для обновления UI
    QTimer::singleShot(50, [this, frameIndex, timeline, timelineWasVisible]() {
        QImage frame = captureView3D();

        // Восстанавливаем видимость таймлайна
        if (timeline) {
            timeline->setVisible(timelineWasVisible);
            qDebug() << "Timeline visibility restored";
        }

        if (frame.isNull()) {
            qDebug() << "Failed to capture frame" << frameIndex;
            setStatus("Error: Failed to capture frame " + QString::number(frameIndex));
            stopExport();
            return;
        }

        // Save frame with sequential numbering for FFmpeg
        QString frameFileName = QString("%1/frame_%2.png")
                                    .arg(m_tempDir)
                                    .arg(m_currentFrame, 6, 10, QChar('0'));

        if (!frame.save(frameFileName, "PNG")) {
            qDebug() << "Failed to save frame" << frameIndex;
            setStatus("Error: Failed to save frame " + QString::number(frameIndex));
            stopExport();
            return;
        }

        m_capturedFrames.append(frameFileName);
        qDebug() << "Captured frame" << frameIndex << "as" << frameFileName;
    });
}

QQuickItem* AnimationExporter::findTimelineItem(QQuickItem* parent)
{
    if (!parent) return nullptr;

    // Проверяем текущий элемент
    QString objectName = parent->objectName();
    if (objectName.contains("timeline", Qt::CaseInsensitive) ||
        objectName.contains("TimeLineView", Qt::CaseInsensitive)) {
        return parent;
    }

    // Проверяем по типу
    QString className = parent->metaObject()->className();
    if (className.contains("TimeLineView")) {
        return parent;
    }

    // Рекурсивно ищем в детях
    const auto children = parent->childItems();
    for (QQuickItem* child : children) {
        QQuickItem* result = findTimelineItem(child);
        if (result) return result;
    }

    return nullptr;
}

void AnimationExporter::loadKeyframe(int frameIndex)
{
    if (!m_keyframeManager) return;

    qDebug() << "Loading keyframe for frame" << frameIndex;

    // Load keyframe using the keyframe manager
    bool success = QMetaObject::invokeMethod(m_keyframeManager, "loadKeyframe",
                                             Q_ARG(QVariant, frameIndex));

    if (!success) {
        qDebug() << "Failed to load keyframe" << frameIndex;
    }
}

QImage AnimationExporter::captureView3D()
{
    if (!m_view3d) {
        qDebug() << "No view3d object available";
        return QImage();
    }

    // Try to get the QQuickItem from the view3d object
    QQuickItem *view3dItem = qobject_cast<QQuickItem*>(m_view3d);
    if (!view3dItem) {
        qDebug() << "view3d is not a QQuickItem";
        return QImage();
    }

    // Get the window
    QQuickWindow *window = view3dItem->window();
    if (!window) {
        qDebug() << "No window found for view3d";
        return QImage();
    }

    // ИСПРАВЛЕНО: Получаем правильные координаты View3D в окне
    QRectF view3dBounds = view3dItem->boundingRect();

    // Используем mapRectToScene для получения правильной позиции
    QRectF sceneRect = view3dItem->mapRectToScene(view3dBounds);

    // Преобразуем в координаты окна
    QRect captureRect(
        static_cast<int>(sceneRect.x()),
        static_cast<int>(sceneRect.y()),
        static_cast<int>(sceneRect.width()),
        static_cast<int>(sceneRect.height())
        );

    qDebug() << "View3D bounds:" << view3dBounds;
    qDebug() << "View3D scene rect:" << sceneRect;
    qDebug() << "Capture rect:" << captureRect;
    qDebug() << "Window size:" << window->size();

    // Захватываем всё окно
    QImage windowImage = window->grabWindow();
    if (windowImage.isNull()) {
        qDebug() << "Failed to grab window";
        return QImage();
    }

    qDebug() << "Window image size:" << windowImage.size();

    // ИСПРАВЛЕНО: Более точное определение области захвата
    // Убеждаемся что область захвата в пределах окна
    QRect windowRect(0, 0, windowImage.width(), windowImage.height());
    captureRect = captureRect.intersected(windowRect);

    // ИСПРАВЛЕНО: Добавляем проверку на разумность размеров
    if (captureRect.isEmpty() || captureRect.width() < 50 || captureRect.height() < 50) {
        qDebug() << "Capture rect is too small or empty:" << captureRect;
        qDebug() << "Falling back to window center crop";

        // Fallback: берем центральную часть окна, исключая верх и низ (где UI)
        int margin = 60; // Отступ для UI элементов
        captureRect = QRect(
            0,
            margin,
            windowImage.width(),
            windowImage.height() - margin * 2
            );
    }

    qDebug() << "Final capture rect:" << captureRect;

    // Извлекаем только область View3D
    QImage view3dImage = windowImage.copy(captureRect);
    if (view3dImage.isNull()) {
        qDebug() << "Failed to extract view3d area";
        return windowImage; // Return full window if extraction fails
    }

    qDebug() << "Extracted image size:" << view3dImage.size();

    // Масштабируем до желаемого разрешения
    QImage scaledImage = view3dImage.scaled(m_renderWidth, m_renderHeight,
                                            Qt::IgnoreAspectRatio,
                                            Qt::SmoothTransformation);

    qDebug() << "Final scaled image size:" << scaledImage.size();

    return scaledImage;
}

void AnimationExporter::generateVideo()
{
    if (m_capturedFrames.isEmpty()) {
        setStatus("Error: No frames captured");
        emit exportCompleted(false, "No frames were captured");
        m_isExporting = false;
        emit isExportingChanged();
        return;
    }

    setStatus("Generating video...");

    QString ffmpegPath = getFFmpegPath();
    QString inputPattern = QDir::toNativeSeparators(m_tempDir + "/frame_%06d.png");

    // ИСПРАВЛЕНО: Убеждаемся что выходной путь правильный
    QString outputPath = QDir::toNativeSeparators(m_exportPath);

    // ИСПРАВЛЕНО: Создаем папку для выходного файла если она не существует
    QFileInfo outputInfo(outputPath);
    QDir outputDir = outputInfo.dir();
    if (!outputDir.exists()) {
        outputDir.mkpath(".");
        qDebug() << "Created output directory:" << outputDir.absolutePath();
    }

    QStringList arguments;
    arguments << "-y" // Overwrite output file
              << "-framerate" << QString::number(m_frameRate)
              << "-i" << inputPattern
              << "-c:v" << "libx264"
              << "-pix_fmt" << "yuv420p"
              << "-preset" << "medium"
              << "-crf" << "18" // High quality
              << outputPath;

    qDebug() << "Starting FFmpeg with arguments:" << arguments;
    qDebug() << "Input pattern:" << inputPattern;
    qDebug() << "Output path:" << outputPath;

    m_ffmpegProcess->start(ffmpegPath, arguments);

    if (!m_ffmpegProcess->waitForStarted(5000)) {
        setStatus("Error: Failed to start FFmpeg");
        emit exportCompleted(false, "Failed to start FFmpeg process");
        m_isExporting = false;
        emit isExportingChanged();
        cleanup();
    }
}

void AnimationExporter::onFFmpegFinished(int exitCode, QProcess::ExitStatus exitStatus)
{
    qDebug() << "FFmpeg finished with exit code:" << exitCode << "status:" << exitStatus;

    m_isExporting = false;
    emit isExportingChanged();

    if (exitStatus == QProcess::NormalExit && exitCode == 0) {
        setStatus("Export completed successfully!");
        emit exportCompleted(true, "Animation exported to: " + m_exportPath);
    } else {
        QString error = m_ffmpegProcess->readAllStandardError();
        setStatus("Error: FFmpeg failed");
        qDebug() << "FFmpeg error output:" << error;
        emit exportCompleted(false, "FFmpeg failed with exit code " + QString::number(exitCode) + "\n" + error);
    }

    cleanup();
}

void AnimationExporter::onFFmpegError(QProcess::ProcessError error)
{
    qDebug() << "FFmpeg process error:" << error;

    m_isExporting = false;
    emit isExportingChanged();

    QString errorString;
    switch (error) {
    case QProcess::FailedToStart:
        errorString = "Failed to start FFmpeg process";
        break;
    case QProcess::Crashed:
        errorString = "FFmpeg process crashed";
        break;
    case QProcess::Timedout:
        errorString = "FFmpeg process timed out";
        break;
    default:
        errorString = "Unknown FFmpeg process error";
        break;
    }

    setStatus("Error: " + errorString);
    emit exportCompleted(false, errorString);

    cleanup();
}

void AnimationExporter::cleanup()
{
    // Clean up temporary files
    if (!m_tempDir.isEmpty()) {
        QDir tempDir(m_tempDir);
        if (tempDir.exists()) {
            tempDir.removeRecursively();
            qDebug() << "Cleaned up temp directory:" << m_tempDir;
        }
    }

    m_capturedFrames.clear();

    // Clean up OpenGL resources
    if (m_fbo) {
        delete m_fbo;
        m_fbo = nullptr;
    }

    if (m_context) {
        delete m_context;
        m_context = nullptr;
    }

    if (m_surface) {
        delete m_surface;
        m_surface = nullptr;
    }
}

void AnimationExporter::setStatus(const QString &status)
{
    if (m_status != status) {
        m_status = status;
        emit statusChanged();
        qDebug() << "Export status:" << status;
    }
}

QString AnimationExporter::getFFmpegPath()
{
    // Try application directory first
    QString appDir = QCoreApplication::applicationDirPath();
    QString ffmpegPath = "K:/QtProj/MotionPlugin/Plugin/ffmpeg.exe";

    QFileInfo ffmpegInfo(ffmpegPath);
    if (ffmpegInfo.exists()) {
        return ffmpegPath;
    }

    // Try parent directory (project root)
    ffmpegPath = appDir + "/../ffmpeg.exe";
    ffmpegInfo.setFile(ffmpegPath);
    if (ffmpegInfo.exists()) {
        return QFileInfo(ffmpegPath).absoluteFilePath();
    }

    // Try system PATH
    return "K:/QtProj/MotionPlugin/Plugin/ffmpeg.exe";
}
