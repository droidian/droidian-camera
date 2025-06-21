/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QObject>
#include <QtQml/qqml.h>

class ThemeUtils : public QObject {
	Q_OBJECT
	QML_ELEMENT
	QML_SINGLETON

    public:
	explicit ThemeUtils(QObject *parent = nullptr);

	Q_INVOKABLE QString getAccentColor();
	Q_INVOKABLE QString getTextColor();
	Q_INVOKABLE QString getDesktopEnvironment();

    private:
	QString m_accentColor;
	QString detectDesktopEnvironment();
	QString getGnomeAccentColor();
	QString getKdeAccentColor();
	QString getReadableTextColor(const QString &backgroundHex);
};