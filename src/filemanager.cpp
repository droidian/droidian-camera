#include "filemanager.h"
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QDateTime>

FileManager::FileManager(QObject *parent) : QObject(parent) {
}

void FileManager::createDirectory(const QString &path) {
    QDir dir;

    if (!dir.exists(path)) {
        dir.mkpath(path);
    }
}

void FileManager::removeGStreamerCacheDirectory() {
    QString homePath = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    QString filePath = homePath + "/.cache/gstreamer-1.0/registry.aarch64.bin";
    QDir dir(homePath + "/.cache/gstreamer-1.0/");

    QFile file(filePath);

    if (file.exists()) {
         QFileInfo fileInfo(file);
         QDateTime lastModified = fileInfo.lastModified();

         if (lastModified.addDays(7) < QDateTime::currentDateTime()) {
             dir.removeRecursively();
         }
    }
}
