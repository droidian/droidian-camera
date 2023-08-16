#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "flashlightcontroller.h"
#include "filemanager.h"

int main(int argc, char *argv[])
{
#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);

    app.setOrganizationName("Droidian");
    app.setOrganizationDomain("Droidian.org");

    QQmlApplicationEngine engine;
    FileManager fileManager;
    FlashlightController flashlightController;

    fileManager.removeGStreamerCacheDirectory();

    engine.rootContext()->setContextProperty("flashlightController", &flashlightController);
    engine.rootContext()->setContextProperty("fileManager", &fileManager);

    const QUrl url(QStringLiteral("qrc:/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
