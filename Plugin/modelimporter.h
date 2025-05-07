#ifndef MODELIMPORTER_H
#define MODELIMPORTER_H

#include <QObject>
#include <QString>
#include <QCoreApplication>
#include <QProcess>
#include <QStringList>
#include <QDebug>
#include <QDir>
#include <QFileInfoList>
#include <QFileInfo>

class ModelImporter : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString inputFilePath READ inputFilePath WRITE setInputFilePath NOTIFY inputFilePathChanged)
    Q_PROPERTY(QString outputDirectory READ outputDirectory WRITE setOutputDirectory NOTIFY outputDirectoryChanged)

public:
    explicit ModelImporter(QObject *parent = nullptr);

    QString inputFilePath() const;
    void setInputFilePath(const QString &path);

    QString outputDirectory() const;
    void setOutputDirectory(const QString &directory);

    Q_INVOKABLE int processModel(const QString &inputFilePath, const QString &outputDirectory);

signals:
    void inputFilePathChanged();
    void outputDirectoryChanged();
    void modelProcessed(const QString &filePath);
    void processingError(const QString &errorMessage);

private:
    QString m_inputFilePath;
    QString m_outputDirectory;
};

#endif // MODELIMPORTER_H
