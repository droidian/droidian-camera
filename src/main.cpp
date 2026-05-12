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

    bool qrMode = false;

    const QStringList args = app.arguments();
    if (args.contains("-qr") || args.contains("--qr")) {
        qrMode = true;
    }

	QQuickWindow::setGraphicsApi(QSGRendererInterface::OpenGL);

	QQuickView view;
	view.setResizeMode(QQuickView::SizeRootObjectToView);
	view.setSource(QUrl("qrc:/qml/main.qml"));

	QObject *root = view.rootObject();
    if (root) {
    	qDebug()<<"QR"<<root;
        root->setProperty("startupQrMode", qrMode);
    }

	view.show();

	return QGuiApplication::exec();
}
