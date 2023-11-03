// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QIcon>
#include <QFile>
#include "flashlightcontroller.h"
#include "filemanager.h"
#include "thumbnailgenerator.h"
#include "capturefilter.h"
#include "gstdevicerange.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Droidian");
    app.setOrganizationDomain("Droidian.org");

    QIcon::setThemeName("default");
    QIcon::setThemeSearchPaths(QStringList("/usr/share/icons"));

    QQmlApplicationEngine engine;
    FlashlightController flashlightController;
    FileManager fileManager;
    ThumbnailGenerator thumbnailGenerator;
    CameraDeviceRangeWrapper cameraDeviceRangeWrapper;

    QString mainQmlPath = "qrc:/main.qml";

    QString configFilePath = fileManager.getConfigFile();

    qDebug() << "config file path: " << configFilePath;
    QFile configFile(configFilePath);

    bool backend_selected = false;

    if (configFile.open(QIODevice::ReadOnly)) {
        QTextStream in(&configFile);
        QString line;
        while (in.readLineInto(&line)) {
            if (line.startsWith("backend=")) {
                QString backendValue = line.split("=")[1].trimmed();
                if (backendValue == "aal") {
                    backend_selected = true;
                    mainQmlPath = "qrc:/main.qml";
                    qDebug() << "selected aal backend";
                } else if (backendValue == "gst") {
                    backend_selected = true;
                    mainQmlPath = "qrc:/main-gst.qml";
                    qDebug() << "selected gst backend";

                    cameraDeviceRangeWrapper.fetchCameraDeviceRange();
                    engine.rootContext()->setContextProperty("cameraDeviceRangeWrapper", &cameraDeviceRangeWrapper);
                    qmlRegisterType<CameraDeviceRangeWrapper>("org.droidian.CameraDeviceRangeWrapper", 1, 0, "CameraDeviceRangeWrapper");
                } else {
                    backend_selected = true;
                    qDebug() << "defaulting to aal backend";
                }

                break;
            }
        }

        configFile.close();
    } else {
        backend_selected = true;
        qWarning() << "could not open config file at " << configFilePath;
        qDebug() << "defaulting to aal backend";
    }

    if (backend_selected == false) {
        qDebug() << "defaulting to aal backend";
    }

    fileManager.removeGStreamerCacheDirectory();

    engine.rootContext()->setContextProperty("flashlightController", &flashlightController);
    engine.rootContext()->setContextProperty("fileManager", &fileManager);
    engine.rootContext()->setContextProperty("thumbnailGenerator", &thumbnailGenerator);

    const QUrl url(mainQmlPath);
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    qmlRegisterType<CaptureFilter>("org.droidian.Camera.CaptureFilter", 1, 0, "CaptureFilter");
    qmlRegisterType<CameraDeviceRangeWrapper>("org.droidian.CameraDeviceRangeWrapper", 1, 0, "CameraDeviceRangeWrapper");

    engine.load(url);

    return app.exec();
}
