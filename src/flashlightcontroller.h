#ifndef FLASHLIGHTCONTROLLER_H
#define FLASHLIGHTCONTROLLER_H

#include <QObject>
#include <QFile>

class FlashlightController : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool flashlightOn READ isFlashlightOn NOTIFY flashlightOnChanged)

public:
    explicit FlashlightController(QObject *parent = nullptr);
    ~FlashlightController();

    Q_INVOKABLE void turnFlashlightOn();
    Q_INVOKABLE void turnFlashlightOff();

    bool isFlashlightOn() const;

signals:
    void flashlightOnChanged(bool flashlightOn);

private:
    QList<QFile*> m_flashlightFiles;
    bool m_flashlightOn = false;

    void writeFile(QFile *file, const QString &value);
};

#endif // FLASHLIGHT
