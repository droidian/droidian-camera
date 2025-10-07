/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <videoquality.h>

VideoQuality::VideoQuality(const QString &name, const QSize &resolution)
	: m_name(name)
	, m_resolution(resolution)
{
}

QString VideoQuality::name() const
{
	return m_name;
}
QSize VideoQuality::resolution() const
{
	return m_resolution;
}

VideoModel::VideoModel(QObject *parent)
	: QAbstractListModel(parent)
{
	qRegisterMetaType<QSize>("QSize");
}

int VideoModel::rowCount(const QModelIndex &parent) const
{
	Q_UNUSED(parent);
	return m_videos.count();
}

QVariant VideoModel::data(const QModelIndex &index, int role) const
{
	if (!index.isValid() || index.row() >= m_videos.size())
		return QVariant();

	const VideoQuality &video = m_videos[index.row()];
	switch (role) {
	case NameRole:
		return video.name();
	case ResolutionRole:
		return QVariant::fromValue(video.resolution());
	default:
		return QVariant();
	}
}

QHash<int, QByteArray> VideoModel::roleNames() const
{
	return { { NameRole, "name" }, { ResolutionRole, "resolution" } };
}

QVariant VideoModel::get(int index) const
{
	if (index < 0 || index >= m_videos.size())
		return QVariant();

	const VideoQuality &video = m_videos[index];
	QVariantMap map;
	map["name"] = video.name();
	map["resolution"] = video.resolution();
	return map;
}

void VideoModel::addVideo(const QString &name, int width, int height)
{
	beginInsertRows(QModelIndex(), m_videos.size(), m_videos.size());
	m_videos.append(VideoQuality(name, QSize(width, height)));
	endInsertRows();
}

void VideoModel::clear()
{
	beginResetModel();
	m_videos.clear();
	endResetModel();
}

int VideoModel::currentIndex() const {
    return m_currentIndex;
}

void VideoModel::setCurrentIndex(int index) {
    if (index < 0 || index >= m_videos.size())
        return;

    if (m_currentIndex != index) {
        m_currentIndex = index;
        Q_EMIT currentIndexChanged();
    }
}
