#include "modelimporter.h"

ModelImporter::ModelImporter(QObject *parent)
    : QObject(parent)
{
}

QString ModelImporter::inputFilePath() const
{
    return m_inputFilePath;
}

void ModelImporter::setInputFilePath(const QString &path)
{
    if (m_inputFilePath != path) {
        m_inputFilePath = path;
        emit inputFilePathChanged();
    }
}

QString ModelImporter::outputDirectory() const
{
    return m_outputDirectory;
}

void ModelImporter::setOutputDirectory(const QString &directory)
{
    if (m_outputDirectory != directory) {
        m_outputDirectory = directory;
        emit outputDirectoryChanged();
    }
}

int ModelImporter::processModel(const QString &inputFilePath, const QString &outputDirectory)
{
    // Get path to balsam.exe relative to application directory
    QString installRootDirectory = QCoreApplication::applicationDirPath();
    QString balsam = installRootDirectory + "/balsam.exe";
    qDebug() << "ModelImporter: Balsam.exe path:" << balsam;

    // Get the filename without extension
    QFileInfo fileInfo(inputFilePath);
    QString fileName = fileInfo.baseName();

    // Handle file:/// prefix if present
    QString cleanInputPath = inputFilePath;
    if (cleanInputPath.startsWith("file:///")) {
        cleanInputPath.remove(0, 8);  // Remove 'file:///'
    }

    QString cleanOutputDir = outputDirectory;
    if (cleanOutputDir.startsWith("file:///")) {
        cleanOutputDir.remove(0, 8);  // Remove 'file:///'
    }

    // Create output path with filename
    QString fullOutputPath = cleanOutputDir + "/" + fileName;

    qDebug() << "ModelImporter: Input file path:" << cleanInputPath;
    qDebug() << "ModelImporter: Output directory:" << fullOutputPath;

    // Prepare arguments for the process
    QStringList arguments = {cleanInputPath, "-o", fullOutputPath};

    // Create and start the process
    QProcess *process = new QProcess(this);

    process->start(balsam, arguments);

    // Wait for the process to start
    if (!process->waitForStarted()) {
        QString error = "Error starting balsam process: " + process->errorString();
        qDebug() << error;
        emit processingError(error);
        process->deleteLater();
        return -1;
    }

    // Wait for the process to finish
    process->waitForFinished(-1); // Wait indefinitely

    // Check exit code to determine success
    int exitCode = process->exitCode();

    if (exitCode == 0) {
        qDebug() << "ModelImporter: Model processed successfully!";

        // Look for the generated mesh file in the output directory
        QDir outputDir(fullOutputPath + "/meshes/");
        QStringList filters;
        filters << "*.mesh"; // Filter for .mesh files
        QFileInfoList files = outputDir.entryInfoList(filters, QDir::Files | QDir::NoDotAndDotDot);

        // Check if there is exactly one file
        if (!files.isEmpty()) {
            QString generatedMeshFile = files.first().absoluteFilePath(); // Get the absolute file path
            qDebug() << "ModelImporter: Found mesh file:" << generatedMeshFile;
            emit modelProcessed(QUrl::fromLocalFile(generatedMeshFile).toString());
        } else {
            QString error = "Error: No .mesh files found in output directory";
            qDebug() << error;
            emit processingError(error);
        }
    } else {
        QString error = "Model processing failed with exit code: " + QString::number(exitCode);
        qDebug() << error;
        emit processingError(error);
    }

    // Clean up
    process->deleteLater();
    return exitCode;
}
