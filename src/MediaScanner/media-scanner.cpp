/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <QDirIterator>
#include <QDateTime>
#include <QImage>
#include <QDebug>
#include <QtConcurrent/QtConcurrent>
#include <QFileInfo>
#include <QMutex>
#include <QVideoFrame>
#include <QEventLoop>
#include <QTimer>

#include <media-scanner.h>

MediaScanner::MediaScanner(QObject *parent)
    : QAbstractListModel(parent)
{
    m_player = new QMediaPlayer(this);
    m_videoSink = new QVideoSink(this);
    m_player->setVideoSink(m_videoSink);
}

int MediaScanner::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid())
        return 0;
    return m_items.size();
}

QVariant MediaScanner::data(const QModelIndex &index, int role) const
{
    if (!index.isValid())
        return {};

    const MediaItem &item = m_items.at(index.row());
    switch (role) {
    case PathRole:
        return item.path;
    case TypeRole:
        return item.type;
    case TimestampRole:
        return item.timestamp;
    case ThumbnailRole:
        return item.thumbnailPath;
    default:
        return {};
    }
}

QHash<int, QByteArray> MediaScanner::roleNames() const {
    QHash<int, QByteArray> roles;
    roles[PathRole] = "path";
    roles[TypeRole] = "type";
    roles[TimestampRole] = "timestamp";
    roles[ThumbnailRole] = "thumbnailPath";
    roles[LabelRole] = "label";
    return roles;
}

QString MediaScanner::getMediaType(const QString &filePath) const {
    QString suffix = QFileInfo(filePath).suffix().toLower();

    if (imageExtensions.contains("." + suffix))
        return "image";

    if (videoExtensions.contains("." + suffix))
        return "video";

    return "";
}

QString MediaScanner::generateVideoThumbnail(const QString &videoPath)
{
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
    QDir().mkpath(cacheDir);

    QString thumbFile = cacheDir + "/" + QString::number(qHash(videoPath)) + ".jpg";
    if (QFile::exists(thumbFile)){
        return thumbFile;
    }

    QEventLoop loop;
    m_player->setSource(QUrl::fromLocalFile(videoPath));

    QTimer timer;
    timer.setSingleShot(true);
    timer.start(5000);
    QObject::connect(&timer, &QTimer::timeout, &loop, &QEventLoop::quit);

    QObject::connect(m_videoSink, &QVideoSink::videoFrameChanged,
                     &loop, [&](const QVideoFrame &frame){
        if (frame.isValid()) {
            loop.quit();
            QImage img = frame.toImage();
            if (!img.isNull()) {
                QImage thumb = img.scaled(400, 300, Qt::KeepAspectRatio, Qt::SmoothTransformation);
                thumb.save(thumbFile, "JPG");
            }
        }
    });

    m_player->play();
    loop.exec();

    m_player->stop();
    m_videoSink->setVideoFrame(QVideoFrame());

    return QFile::exists(thumbFile) ? thumbFile : QString();
}

QString MediaScanner::generateImageThumbnail(const QString &filePath)
{
    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
    QDir().mkpath(cacheDir);

    QFileInfo fi(filePath);
    QString thumbFile = cacheDir + "/" + QString::number(qHash(filePath)) + ".jpg";

    if (QFile::exists(thumbFile))
        return thumbFile;

    QImage image(filePath);
    if (image.isNull()) {
        qWarning() << "Failed to load image for thumbnail:" << filePath;
        return "";
    }

    QImage thumb = image.scaled(400, 300, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    thumb.save(thumbFile, "JPG");
    return thumbFile;
}

void MediaScanner::scan()
{
    if (m_isScanning)
        return;

    QMetaObject::invokeMethod(this, [this]() {
        m_isScanning = true;
        emit scanningChanged();
    }, Qt::QueuedConnection);

    beginResetModel();
    m_items.clear();
    endResetModel();

    (void) QtConcurrent::run([this]() {
        QVector<MediaItem> collectedItems;

        QStringList baseDirs = {
            QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
            QStandardPaths::writableLocation(QStandardPaths::MoviesLocation)
        };

        for (const QString &baseDir : baseDirs) {
            QDir targetDir(baseDir + "/droidian-camera");
            if (!targetDir.exists())
                continue;

            QDirIterator it(targetDir.absolutePath(), QDir::Files | QDir::NoSymLinks, QDirIterator::Subdirectories);

            while (it.hasNext()) {
                QString filePath = it.next();
                QString mediaType = getMediaType(filePath);
                if (mediaType.isEmpty())
                    continue;

                QFileInfo fi(filePath);
                MediaItem item;
                item.path = QUrl::fromLocalFile(filePath).toString();
                item.type = mediaType;
                item.timestamp = fi.lastModified().toSecsSinceEpoch();

                QString thumb;
                if (mediaType == "image") {
                    thumb = generateImageThumbnail(fi.absoluteFilePath());
                    item.thumbnailPath = thumb.isEmpty() ? item.path : "file://" + thumb;
                } else if (mediaType == "video") {
                    thumb = generateVideoThumbnail(fi.absoluteFilePath());
                    item.thumbnailPath = thumb.isEmpty() ? "" : "file://" + thumb;
                }

                collectedItems.append(item);
            }
        }

        std::sort(collectedItems.begin(), collectedItems.end(), [](const MediaItem &a, const MediaItem &b) {
            return a.timestamp > b.timestamp;
        });

        QVector<MediaGroup> grouped;
        QString currentMonth;
        MediaGroup currentGroup;

        for (const auto &item : collectedItems) {
            QString thisMonth = QDateTime::fromSecsSinceEpoch(item.timestamp).toString("MMMM yyyy");

            if (thisMonth != currentMonth) {
                if (!currentGroup.items.isEmpty())
                    grouped.append(currentGroup);

                currentGroup = MediaGroup{thisMonth, {}};
                currentMonth = thisMonth;
            }
            currentGroup.items.append(item);
        }

        if (!currentGroup.items.isEmpty())
            grouped.append(currentGroup);

        QMetaObject::invokeMethod(this, [this, grouped]() {
            m_groups = grouped;
            emit groupsChanged();
            emit scanningFinished();
            m_isScanning = false;
            emit scanningChanged();
        }, Qt::QueuedConnection);
    });
}

QVariantList MediaScanner::groups() const {
    QVariantList list;
    for (const auto &group : m_groups) {
        QVariantMap map;
        map["label"] = group.label;

        QVariantList items;
        for (const auto &item : group.items) {
            QVariantMap i;
            i["path"] = item.path;
            i["type"] = item.type;
            i["timestamp"] = item.timestamp;
            i["thumbnailPath"] = item.thumbnailPath;
            items.append(i);
        }

        map["items"] = items;
        list.append(map);
    }
    return list;
}