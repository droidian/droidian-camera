#ifndef FILEMANAGER_H
#define FILEMANAGER_H

#include <QObject>
#include <QString>

class FileManager : public QObject
{
    Q_OBJECT
public:
    explicit FileManager(QObject *parent = nullptr);

    Q_INVOKABLE void createDirectory(const QString &path);
    Q_INVOKABLE void removeGStreamerCacheDirectory();
};

#endif // FILEMANAGER_H
