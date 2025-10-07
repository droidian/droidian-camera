/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <QGuiApplication>
#include <QtQuick/QQuickView>
#include <hybris-camera.h>

int main(int argc, char **argv)
{
	QGuiApplication app(argc, argv);

	app.setOrganizationName("Droidian");
    app.setOrganizationDomain("droidian.org");
    app.setApplicationName("droidian-camera");

	QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

	QQuickView view;
	view.setResizeMode(QQuickView::SizeRootObjectToView);
	view.setSource(QUrl("qrc:/qml/main.qml"));
	view.show();

	return QGuiApplication::exec();
}
