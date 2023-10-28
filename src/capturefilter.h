// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QAbstractVideoFilter>
#include <QVideoFilterRunnable>

class MyFilter;
class MyFilterRunnable : public QVideoFilterRunnable {
public:
    MyFilterRunnable(bool *capture) : m_capture(capture) {}
    QVideoFrame run(QVideoFrame *input, const QVideoSurfaceFormat &surfaceFormat, RunFlags flags);
private:
    bool *m_capture;
};

class CaptureFilter : public QAbstractVideoFilter {
    Q_OBJECT
public:
    CaptureFilter();
    QVideoFilterRunnable *createFilterRunnable();
    Q_INVOKABLE void capture();
signals:
    void finished(QObject *result);
private:
    bool m_capture;
};
