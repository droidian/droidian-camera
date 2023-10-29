// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include "filemanager.h"
#include <QDir>
#include <QStandardPaths>
#include <QFile>
#include <QDateTime>
#include <QDebug>

FileManager::FileManager(QObject *parent) : QObject(parent) {
}

void FileManager::createDirectory(const QString &path) {
    QDir dir;

    QString homePath = QStandardPaths::writableLocation(QStandardPaths::HomeLocation);
    if (!dir.exists(homePath + path)) {
        dir.mkpath(homePath + path);
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

QString FileManager::getConfigFile() {
    QFileInfo primaryConfig("/usr/lib/droidian/device/droidian-camera.conf");
    QFileInfo secodaryConfig("/etc/droidian-camera.conf");

    if (primaryConfig.exists()) {
        return primaryConfig.absoluteFilePath();
    } else if (secodaryConfig.exists()) {
        return secodaryConfig.absoluteFilePath();
    } else {
        return "None";
    }
}
