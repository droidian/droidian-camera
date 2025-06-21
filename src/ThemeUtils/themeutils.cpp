/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <QFile>
#include <QTextStream>
#include <QDebug>
#include <QDir>
#include <QColor>

#include <gnomeutils.h>
#include <themeutils.h>

ThemeUtils::ThemeUtils(QObject *parent)
	: QObject(parent)
{
}

QString ThemeUtils::getDesktopEnvironment()
{
	return detectDesktopEnvironment();
}

QString ThemeUtils::detectDesktopEnvironment()
{
	QString de = qEnvironmentVariable("XDG_CURRENT_DESKTOP");
	if (de.isEmpty())
		de = qEnvironmentVariable("DESKTOP_SESSION");
	if (de.isEmpty())
		de = qEnvironmentVariable("GDMSESSION");
	return de.toLower();
}

QString ThemeUtils::getAccentColor()
{
	QString de = detectDesktopEnvironment();

	if (de.contains("gnome")) {
		m_accentColor = getGnomeAccentColor();
		return m_accentColor;
	} else if (de.contains("plasma") || de.contains("kde")) {
		m_accentColor = getKdeAccentColor();
		return m_accentColor;
	}

	return "#90ee90";
}

QString ThemeUtils::getTextColor()
{
	return "#FFFFFF";
}

QString ThemeUtils::getKdeAccentColor()
{
	QString configPath = QDir::homePath() + "/.config/kdeglobals";
	QFile file(configPath);
	if (!file.open(QIODevice::ReadOnly | QIODevice::Text))
		return "#90EE90";

	QTextStream in(&file);
	bool inGeneralSection = false;

	while (!in.atEnd()) {
		QString line = in.readLine().trimmed();

		if (line.startsWith('[')) {
			inGeneralSection = (line == "[General]");
			continue;
		}

		if (inGeneralSection && line.startsWith("AccentColor=")) {
			QString value =
				line.mid(QString("AccentColor=").length())
					.trimmed();
			QStringList rgb = value.split(',');

			if (rgb.size() == 3) {
				bool okR, okG, okB;
				int r = rgb[0].toInt(&okR);
				int g = rgb[1].toInt(&okG);
				int b = rgb[2].toInt(&okB);

				if (okR && okG && okB) {
					QColor color(r, g, b);
					if (color.isValid())
						return color
							.name(QColor::HexRgb)
							.toUpper();
				}
			}
		}
	}

	return "#90EE90";
}

QString ThemeUtils::getGnomeAccentColor()
{
	return getGnomeAccentColorViaGSettings();
}

QString ThemeUtils::getReadableTextColor(const QString &backgroundHex)
{
	QColor bg(backgroundHex);
	if (!bg.isValid())
		return "#FFFFFF";

	int brightness = qGray(bg.red(), bg.green(), bg.blue());

	return (brightness < 128) ? "#FFFFFF" : "#000000";
}