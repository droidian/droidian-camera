/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QtQml/qqml.h>
#include <QAbstractListModel>
#include <QObject>
#include <QVector>
#include <QDir>
#include <QFileInfo>
#include <QStandardPaths>

extern "C" {
    #include <libavformat/avformat.h>
    #include <libavcodec/avcodec.h>
    #include <libswscale/swscale.h>
    #include <libavutil/imgutils.h>
}

struct MediaItem {
    QString path;
    QString type;
    qint64 timestamp;
    QString thumbnailPath;
};

struct MediaGroup {
    QString label;
    QVector<MediaItem> items;
};

class MediaScanner : public QAbstractListModel
{
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(bool scanning READ isScanning NOTIFY scanningChanged)
    Q_PROPERTY(QVariantList groups READ groups NOTIFY groupsChanged)

public:
    enum Roles {
        PathRole = Qt::UserRole + 1,
        TypeRole,
        TimestampRole,
        ThumbnailRole,
        LabelRole
    };

    explicit MediaScanner(QObject *parent = nullptr);

    bool isScanning() const { return m_isScanning; }

    Q_INVOKABLE void scan();
    QVariantList groups() const;

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

signals:
    void scanningChanged();
    void scanningFinished();
    void groupsChanged();

private:
    QString getMediaType(const QString &filePath) const;
    QString generateImageThumbnail(const QString &filePath);
    QString generateVideoThumbnailFFmpeg(const QString &videoPath);

    QVector<MediaItem> m_items;

    QStringList imageExtensions {".png", ".jpg", ".jpeg", ".bmp", ".gif"};
    QStringList videoExtensions {".mp4", ".avi", ".mkv", ".mov", ".webm"};

    bool m_isScanning = false;

    QVector<MediaGroup> m_groups;
};
