// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2024 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#ifndef DC_DEVICE_H
#define DC_DEVICE_H

#include <droidmedia/droidmedia.h>
#include <droidmedia/droidmediacamera.h>
#include <droidmedia/droidmediaconstants.h>

#include <QObject>
#include <QVideoFrame>
#include <QVideoSink>
#include <QDebug>

#include <QSettings>

class DcDevice : public QObject
{
    Q_OBJECT

public:
    DcDevice(int id);
    bool start();
    void stop();
    float getMaxZoom();
    void takePicture();
    QStringList getSceneModes();
    QList<QSize> getResolutions(bool wide);
    bool setResolution(QSize res);
    void setZoom(float zoom);
    void setSceneMode(QString mode);
    void setVideoSink(QVideoSink* videoSink);
    double getMP();
    bool isBlacklisted();

public Q_SLOTS:

signals:
    void imageCaptured();

private:
    void init();
    void setAvailableResolutions(QString type, QStringList values);
    void setupCb();
    QStringList m_focus_modes;
    QStringList m_scene_modes;
    QStringList m_whitebalance_values;
    float m_maxZoom;
    QStringList m_flash_modes;
    QList<QSize> m_pictureResolutions;
    QList<QSize> m_previewResolutions;
    QList<QSize> m_videoResolutions;
    DroidMediaCameraInfo m_camInfo;
    QSize m_currentRes;
    int m_camId;
    DroidMediaCamera *m_camera = nullptr;
    QVideoSink* m_videoSink = nullptr;
    DroidMediaCameraCallbacks m_cb;
    DroidMediaBufferQueueCallbacks m_cbBuffer;
    DroidMediaBufferQueue *m_bufQueue = nullptr;
    bool m_isWide = false;
    bool m_saveFrame = false;
    bool m_isBlacklisted = false;
    QString m_picturesLocation;
    QString m_videosLocation;
    void loadCommonSettings();
    QString getFilename(int type);
    static bool dc_buffer_created(void *data, DroidMediaBuffer *buffer);
    static bool dc_frame_available(void *data, DroidMediaBuffer *buffer);
    static void dc_compressed_image_callback(void *data, DroidMediaData *mem);
    static void dc_shutter_callback(void *data);

    int m_maxResolutionOnly = 0;
};

#endif // DC_DEVICE_H