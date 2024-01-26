// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2024 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#ifndef DROIDIAN_CAMERA_H
#define DROIDIAN_CAMERA_H

#include <QObject>
#include <QtQml/qqmlregistration.h>
#include <dc-device.h>

class DroidianCamera : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVideoSink* videoSink READ get_video_sink WRITE setVideoSink NOTIFY videoSinkChanged)
    Q_PROPERTY(int cameraId READ get_cameraId WRITE setCameraId NOTIFY cameraIdChanged)
    Q_PROPERTY(int maxZoom READ get_maxZoom NOTIFY maxZoomChanged)
    Q_PROPERTY(int aspectRatio READ get_aspectRatio WRITE setAspectRatio NOTIFY aspectRatioChanged)
    Q_PROPERTY(QStringList sceneModes READ get_sceneModes NOTIFY sceneModesChanged)
    Q_PROPERTY(int sceneModeIndex READ get_sceneModeIndex WRITE setSceneModeIndex NOTIFY sceneModeIndexChanged)
    Q_PROPERTY(QList<QSize> availableResolutions READ get_availableResolutions NOTIFY availableResolutionsChanged)
    Q_PROPERTY(int availableResolutionIndex READ get_availableResolutionIndex WRITE setAvailableResolutionIndex NOTIFY availableResolutionIndexChanged)
    QML_ELEMENT

public:
    DroidianCamera();
    ~DroidianCamera();

    void init();
    Q_INVOKABLE void takePicture();
    Q_INVOKABLE void setZoom(float zoom);
    QVideoSink* get_video_sink();
    void setVideoSink(QVideoSink *newVideoSink);
    int get_cameraId();
    int get_maxZoom();
    int get_aspectRatio();
    QStringList get_sceneModes();
    int get_sceneModeIndex();
    QList<QSize> get_availableResolutions();
    int get_availableResolutionIndex();
    void setCameraId(int id);
    void setAspectRatio(int asp);
    void setSceneModeIndex(int index);
    void setAvailableResolutionIndex(int index);

public Q_SLOTS:

signals:
    void videoSinkChanged();
    void cameraIdChanged();
    void maxZoomChanged();
    void aspectRatioChanged();
    void sceneModesChanged();
    void imageCaptured();
    void sceneModeIndexChanged();
    void availableResolutionsChanged();
    void availableResolutionIndexChanged();
    
private:
    QList<DcDevice*> m_cameras;
    QVideoSink* m_videoSink = nullptr;
    int m_cameraId = 0;
    int m_maxZoom = 1;
    int m_aspectWide = 0;
    QStringList m_sceneModes;
    int m_sceneModeIndex = 0;
    QList<QSize> m_availableResolutions;
    int m_availableResolutionIndex = 0;
    void init_cameras();
    void connectSignals();
    void saveCameraSettings();
    void loadCameraSettings();
    bool m_isFirstCall = true;
};

#endif // DROIDIAN_CAMERA_H