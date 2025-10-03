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

#include <media-scanner.h>

MediaScanner::MediaScanner(QObject *parent)
    : QAbstractListModel(parent)
{}

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

QHash<int, QByteArray> MediaScanner::roleNames() const
{
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

QString MediaScanner::generateVideoThumbnailFFmpeg(const QString &videoPath)
{
    const int maxWidth = 400;
    const int maxHeight = 300;

    QString cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation) + "/thumbnails";
    QDir().mkpath(cacheDir);

    QString thumbFile = cacheDir + "/" + QString::number(qHash(videoPath)) + ".jpg";
    if (QFile::exists(thumbFile))
        return thumbFile;

    AVFormatContext *fmtCtx = nullptr;
    if (avformat_open_input(&fmtCtx, videoPath.toUtf8().constData(), nullptr, nullptr) < 0)
        return "";

    if (avformat_find_stream_info(fmtCtx, nullptr) < 0) {
        avformat_close_input(&fmtCtx);
        return "";
    }

    int videoStreamIndex = av_find_best_stream(fmtCtx, AVMEDIA_TYPE_VIDEO, -1, -1, nullptr, 0);
    if (videoStreamIndex < 0) {
        avformat_close_input(&fmtCtx);
        return "";
    }

    AVCodecParameters *codecPar = fmtCtx->streams[videoStreamIndex]->codecpar;
    const AVCodec *codec = avcodec_find_decoder(codecPar->codec_id);
    if (!codec) {
        avformat_close_input(&fmtCtx);
        return "";
    }

    AVCodecContext *codecCtx = avcodec_alloc_context3(codec);
    if (!codecCtx || avcodec_parameters_to_context(codecCtx, codecPar) < 0 || avcodec_open2(codecCtx, codec, nullptr) < 0) {
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return "";
    }

    int64_t duration = fmtCtx->duration;
    if (duration > 0) {
        int64_t middle = duration / 2;
        av_seek_frame(fmtCtx, videoStreamIndex, middle, AVSEEK_FLAG_BACKWARD);
        avcodec_flush_buffers(codecCtx);
    }

    AVPacket *packet = av_packet_alloc();
    AVFrame *frame = av_frame_alloc();
    AVFrame *scaledFrame = av_frame_alloc();

    int srcWidth = codecCtx->width;
    int srcHeight = codecCtx->height;
    AVRational sar = codecCtx->sample_aspect_ratio.num != 0
                     ? codecCtx->sample_aspect_ratio
                     : AVRational{1,1};

    if (sar.num != sar.den) {
        srcWidth = srcWidth * sar.num / sar.den;
    }

    double scaleX = static_cast<double>(maxWidth) / srcWidth;
    double scaleY = static_cast<double>(maxHeight) / srcHeight;
    double scale = std::max(scaleX, scaleY);

    int scaledWidth = static_cast<int>(srcWidth * scale);
    int scaledHeight = static_cast<int>(srcHeight * scale);

    scaledFrame->format = AV_PIX_FMT_RGB24;
    scaledFrame->width = maxWidth;
    scaledFrame->height = maxHeight;

    int finalBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, maxWidth, maxHeight, 1);
    uint8_t *finalBuffer = (uint8_t *)av_malloc(finalBytes);
    memset(finalBuffer, 0, finalBytes);
    av_image_fill_arrays(scaledFrame->data, scaledFrame->linesize, finalBuffer,
                         AV_PIX_FMT_RGB24, maxWidth, maxHeight, 1);

    int scaledBytes = av_image_get_buffer_size(AV_PIX_FMT_RGB24, scaledWidth, scaledHeight, 1);
    uint8_t *scaledBuffer = (uint8_t *)av_malloc(scaledBytes);
    memset(scaledBuffer, 0, scaledBytes);

    AVFrame *intermediateFrame = av_frame_alloc();
    intermediateFrame->format = AV_PIX_FMT_RGB24;
    intermediateFrame->width = scaledWidth;
    intermediateFrame->height = scaledHeight;
    av_image_fill_arrays(intermediateFrame->data, intermediateFrame->linesize, scaledBuffer,
                         AV_PIX_FMT_RGB24, scaledWidth, scaledHeight, 1);

    SwsContext *swsCtx = sws_getContext(codecCtx->width, codecCtx->height, codecCtx->pix_fmt,
                                        scaledWidth, scaledHeight, AV_PIX_FMT_RGB24,
                                        SWS_BILINEAR, nullptr, nullptr, nullptr);

    if (!swsCtx) {
        av_free(scaledBuffer);
        av_free(finalBuffer);
        av_frame_free(&frame);
        av_frame_free(&scaledFrame);
        av_frame_free(&intermediateFrame);
        av_packet_free(&packet);
        avcodec_free_context(&codecCtx);
        avformat_close_input(&fmtCtx);
        return "";
    }

    bool frameReady = false;
    while (av_read_frame(fmtCtx, packet) >= 0) {
        if (packet->stream_index == videoStreamIndex) {
            if (avcodec_send_packet(codecCtx, packet) == 0) {
                while (avcodec_receive_frame(codecCtx, frame) == 0) {
                    sws_scale(swsCtx,
                              frame->data, frame->linesize,
                              0, codecCtx->height,
                              intermediateFrame->data, intermediateFrame->linesize);

                    frameReady = true;
                    break;
                }
            }
        }
        av_packet_unref(packet);
        if (frameReady)
            break;
    }

    QString resultThumb;
    if (frameReady) {
        int cropX = (scaledWidth - maxWidth) / 2;
        int cropY = (scaledHeight - maxHeight) / 2;

        for (int y = 0; y < maxHeight; ++y) {
            memcpy(
                scaledFrame->data[0] + y * scaledFrame->linesize[0],
                intermediateFrame->data[0] + (y + cropY) * intermediateFrame->linesize[0] + cropX * 3,
                maxWidth * 3
            );
        }

        QImage image(maxWidth, maxHeight, QImage::Format_RGB888);
        for (int y = 0; y < maxHeight; ++y) {
            memcpy(image.scanLine(y),
                   scaledFrame->data[0] + y * scaledFrame->linesize[0],
                   maxWidth * 3);
        }

        if (!image.isNull()) {
            image.save(thumbFile, "JPG", 90);
            resultThumb = thumbFile;
        }
    }

    sws_freeContext(swsCtx);
    av_free(scaledBuffer);
    av_free(finalBuffer);
    av_frame_free(&frame);
    av_frame_free(&intermediateFrame);
    av_frame_free(&scaledFrame);
    av_packet_free(&packet);
    avcodec_free_context(&codecCtx);
    avformat_close_input(&fmtCtx);

    return resultThumb;
}

void MediaScanner::addMediaItem(QString filePath)
{
    QString mediaType = getMediaType(filePath);
    if (mediaType.isEmpty())
        return;

    QFileInfo fi(filePath);

    MediaItem item;
    item.path = QUrl::fromLocalFile(filePath).toString();
    item.type = mediaType;
    item.timestamp = fi.lastModified().toSecsSinceEpoch();

    if (mediaType == "image") {
        QString thumb = generateImageThumbnail(fi.absoluteFilePath());
        item.thumbnailPath = thumb.isEmpty() ? item.path : "file://" + thumb;
    } else if (mediaType == "video") {
        QString thumb = generateVideoThumbnailFFmpeg(fi.absoluteFilePath());
        item.thumbnailPath = thumb.isEmpty() ? "" : "file://" + thumb;
    }

    beginInsertRows(QModelIndex(), m_items.size(), m_items.size());
    m_items.append(item);
    endInsertRows();

    updateGroupsWithNewItems({item});
    emit groupsChanged();
}

void MediaScanner::updateGroupsWithNewItems(const QVector<MediaItem> &newItems)
{
    for (const MediaItem &item : newItems) {
        QString label = QDateTime::fromSecsSinceEpoch(item.timestamp).toString("MMMM yyyy");

        auto it = std::find_if(m_groups.begin(), m_groups.end(), [&](const MediaGroup &group) {
            return group.label == label;
        });

        if (it != m_groups.end()) {
            it->items.prepend(item);
        } else {
            MediaGroup group;
            group.label = label;
            group.items.append(item);
            m_groups.prepend(group);
        }
    }

    std::sort(m_groups.begin(), m_groups.end(), [](const MediaGroup &a, const MediaGroup &b) {
        if (a.items.isEmpty() || b.items.isEmpty()) return false;
        return a.items.first().timestamp > b.items.first().timestamp;
    });
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

                if (mediaType == "image") {
                    QString thumb = generateImageThumbnail(fi.absoluteFilePath());
                    item.thumbnailPath = thumb.isEmpty() ? item.path : "file://" + thumb;
                } else if (mediaType == "video") {
                    QString thumb = generateVideoThumbnailFFmpeg(fi.absoluteFilePath());
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

            for (auto &group : m_groups) {
                for (auto &item : group.items) {
                    if (item.type == "video" && item.thumbnailPath.isEmpty()) {
                        (void) QtConcurrent::run([this, path = QUrl(item.path).toLocalFile()]() {
                            generateVideoThumbnailFFmpeg(path);
                        });
                    }
                }
            }
        }, Qt::QueuedConnection);
    });
}

QVariantList MediaScanner::groups() const
{
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