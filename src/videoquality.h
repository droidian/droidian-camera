/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QAbstractListModel>
#include <QString>
#include <QSize>
#include <QList>
#include <QMetaType>

class VideoQuality {
    public:
	VideoQuality(const QString &name, const QSize &resolution);
	QString name() const;
	QSize resolution() const;

    private:
	QString m_name;
	QSize m_resolution;
};

class VideoModel : public QAbstractListModel {
	Q_OBJECT

    public:
	enum VideoRoles { NameRole = Qt::UserRole + 1, ResolutionRole };

	explicit VideoModel(QObject *parent = nullptr);

	int rowCount(const QModelIndex &parent = QModelIndex()) const override;
	QVariant data(const QModelIndex &index,
		      int role = Qt::DisplayRole) const override;
	QHash<int, QByteArray> roleNames() const override;

	Q_INVOKABLE QVariant get(int index) const;
	Q_INVOKABLE void addVideo(const QString &name, int width, int height);
	Q_INVOKABLE void clear();

    private:
	QList<VideoQuality> m_videos;
};

Q_DECLARE_METATYPE(QSize)