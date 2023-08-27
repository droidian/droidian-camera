// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#ifndef THUMBNAILGENERATOR_H
#define THUMBNAILGENERATOR_H

#include <QObject>
#include <QMediaPlayer>
#include <QVideoProbe>
#include <QVideoFrame>
#include <QImage>
#include <QBuffer>

class ThumbnailGenerator : public QObject
{
    Q_OBJECT
public:
    ThumbnailGenerator(QObject *parent = nullptr);
    Q_INVOKABLE void setVideoSource(const QString &videoSource);
    Q_INVOKABLE QString toQmlImage(const QImage &image);

signals:
    void thumbnailGenerated(const QImage &image);

private slots:
    void processFrame(const QVideoFrame &frame);

private:
    QMediaPlayer m_mediaPlayer;
    QVideoProbe m_probe;
};

#endif // THUMBNAILGENERATOR_H
