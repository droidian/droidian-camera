// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include "capturefilter.h"
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>
#include <QStandardPaths>
#include <QCoreApplication>

QVideoFrame MyFilterRunnable::run(QVideoFrame *input, const QVideoSurfaceFormat &surfaceFormat, RunFlags flags) {
    Q_UNUSED(surfaceFormat);
    Q_UNUSED(flags);

    if (*m_capture) {
        QString picturesLocation = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        QDir photoDir(picturesLocation);

        if (!photoDir.exists("droidian-camera")) {
            photoDir.mkdir("droidian-camera");
        }

        photoDir.cd("droidian-camera");

        QString filename = "image" + QDateTime::currentDateTime().toString("yyyyMMdd_hhmmsszzz") + ".jpg";
        input->image().save(photoDir.filePath(filename));

        *m_capture = false;
    }

    return *input;
}

CaptureFilter::CaptureFilter() : m_capture(false) {}

QVideoFilterRunnable *CaptureFilter::createFilterRunnable() {
    return new MyFilterRunnable(&m_capture);
}

void CaptureFilter::capture() {
    m_capture = true;
}
