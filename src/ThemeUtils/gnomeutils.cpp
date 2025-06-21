/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#undef signals
#include <gio/gio.h>

#include <QColor>
#include <QDebug>

#include <gnomeutils.h>

QString getGnomeAccentColorViaGSettings()
{
	GSettings *settings = g_settings_new("org.gnome.desktop.interface");
	if (!settings) {
		qDebug() << "No GNOME settings, using fallback color.";
		return "#90EE90";
	}

	gchar *value = g_settings_get_string(settings, "accent-color");
	QString color = "#90EE90";

	if (value && *value) {
		QString accent =
			QString::fromUtf8(value).remove('\'').toLower();

		QColor qcolor(accent);
		if (qcolor.isValid()) {
			color = qcolor.name(QColor::HexRgb).toUpper();
		} else {
			qDebug() << "Unknown color name:" << accent
				 << ", using fallback.";
		}
	} else {
		qDebug() << "No GNOME accent-color set, using fallback.";
	}

	if (value)
		g_free(value);
	g_object_unref(settings);

	return color;
}