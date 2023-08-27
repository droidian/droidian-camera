// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include "thumbnailgenerator.h"

ThumbnailGenerator::ThumbnailGenerator(QObject *parent) : QObject(parent) {
    connect(&m_probe, &QVideoProbe::videoFrameProbed, this, &ThumbnailGenerator::processFrame);
    m_probe.setSource(&m_mediaPlayer);
}

void ThumbnailGenerator::setVideoSource(const QString &videoSource) {
    m_mediaPlayer.setMedia(QUrl(videoSource));
    m_mediaPlayer.play();
}

QString ThumbnailGenerator::toQmlImage(const QImage &image) {
    QByteArray byteArray;
    QBuffer buffer(&byteArray);
    image.save(&buffer, "PNG");
    return QString("data:image/png;base64,") + QString(byteArray.toBase64());
}

void ThumbnailGenerator::processFrame(const QVideoFrame &frame) {
    if (frame.isValid()) {
        QVideoFrame cloneFrame(frame);
        cloneFrame.map(QAbstractVideoBuffer::ReadOnly);
        QImage image(cloneFrame.bits(),
                     cloneFrame.width(),
                     cloneFrame.height(),
                     QVideoFrame::imageFormatFromPixelFormat(cloneFrame.pixelFormat()));
        emit thumbnailGenerated(image);
        m_mediaPlayer.stop();
        cloneFrame.unmap();
    }
}
