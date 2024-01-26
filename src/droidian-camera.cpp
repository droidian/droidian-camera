// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2024 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QtGui/QGuiApplication>
#include <QThread>

#include <droidian-camera.h>

DroidianCamera::DroidianCamera() {
    init_cameras();
    m_videoSink = new QVideoSink();
}

DroidianCamera::~DroidianCamera()
{
    saveCameraSettings();
}

void DroidianCamera::init_cameras()
{
    int numOfCameras;
    numOfCameras = droid_media_camera_get_number_of_cameras();
    for (int cam = 0; cam < numOfCameras; cam++) {
        DcDevice *newCam = new DcDevice(cam);
        m_cameras.append(newCam);
    }
}

void DroidianCamera::connectSignals()
{
    connect(m_cameras.at(m_cameraId), &DcDevice::imageCaptured, this, &DroidianCamera::imageCaptured);
}

QVideoSink* DroidianCamera::get_video_sink()
{
    return m_videoSink;
}

void DroidianCamera::setVideoSink(QVideoSink *newVideoSink)
{
    if (m_videoSink == newVideoSink)
        return;
    m_videoSink = newVideoSink;
    m_cameras.at(m_cameraId)->setVideoSink(m_videoSink);
    emit videoSinkChanged();
}

void DroidianCamera::takePicture()
{
    m_cameras.at(m_cameraId)->takePicture();
}

void DroidianCamera::setZoom(float zoom)
{
    m_cameras.at(m_cameraId)->setZoom(zoom);
}

int DroidianCamera::get_cameraId()
{
    return m_cameraId;
}

int DroidianCamera::get_maxZoom()
{
    return m_maxZoom;
}

int DroidianCamera::get_aspectRatio()
{
    return m_aspectWide;
}

QStringList DroidianCamera::get_sceneModes()
{
    return m_sceneModes;
}

int DroidianCamera::get_sceneModeIndex()
{
    return m_sceneModeIndex;
}

QList<QSize> DroidianCamera::get_availableResolutions()
{
    return m_availableResolutions;
}

int DroidianCamera::get_availableResolutionIndex()
{
    return m_availableResolutionIndex;
}

void DroidianCamera::setCameraId(int id)
{
    int counter = 0;

    if(m_isFirstCall)
        m_isFirstCall = false;
    else
        saveCameraSettings();

    if(id > m_cameras.size()-1)
        id = 0;

    m_cameras.at(m_cameraId)->stop();
    m_cameraId = id;

    while(m_cameras.at(m_cameraId)->isBlacklisted()){
        if(id == m_cameras.size()-1)
            id = 0;
        else
            id += 1;
        m_cameraId = id;
        counter += 1;

        if(counter > m_cameras.size())
            qFatal("No accessible cameras found");
    }

    qDebug()<<"Start camera"<<m_cameraId<<"|"<<m_cameras.at(m_cameraId)->getMP()<<"MP";
    m_cameras.at(m_cameraId)->start();
    m_cameras.at(m_cameraId)->setVideoSink(m_videoSink);
    emit cameraIdChanged();
    
    m_maxZoom = m_cameras.at(m_cameraId)->getMaxZoom();
    emit maxZoomChanged();
    
    m_sceneModes = m_cameras.at(m_cameraId)->getSceneModes();
    emit sceneModesChanged();

    m_availableResolutions = m_cameras.at(m_cameraId)->getResolutions(m_aspectWide);
    emit availableResolutionsChanged();

    loadCameraSettings();
    connectSignals();
}

void DroidianCamera::setAspectRatio(int asp)
{
    if(asp != m_aspectWide){
        m_aspectWide = asp;
        emit aspectRatioChanged();
    }
    m_availableResolutions = m_cameras.at(m_cameraId)->getResolutions(m_aspectWide);
    emit availableResolutionsChanged();

    setAvailableResolutionIndex(0);
    m_cameras.at(m_cameraId)->setResolution(m_availableResolutions.at(m_availableResolutionIndex));

    m_cameras.at(m_cameraId)->setSceneMode(m_sceneModes.at(m_sceneModeIndex));
}

void DroidianCamera::setSceneModeIndex(int index)
{
    if(index != m_sceneModeIndex){
        m_sceneModeIndex = index;
        m_cameras.at(m_cameraId)->setSceneMode(m_sceneModes.at(m_sceneModeIndex));
        emit sceneModeIndexChanged();
    }
}

void DroidianCamera::setAvailableResolutionIndex(int index)
{
    if(index != m_availableResolutionIndex){
        m_availableResolutionIndex = index;
        m_cameras.at(m_cameraId)->setResolution(m_availableResolutions.at(m_availableResolutionIndex));
        m_cameras.at(m_cameraId)->setSceneMode(m_sceneModes.at(m_sceneModeIndex));
        emit availableResolutionsChanged();
    }
}

void DroidianCamera::saveCameraSettings()
{
    QSettings settings;

    QString str = "Camera";
    str.append(QString::number(m_cameraId));

    settings.beginGroup(str);
    settings.setValue("aspectRatio", get_aspectRatio());
    settings.setValue("resolutionIndex", get_availableResolutionIndex());
    settings.setValue("sceneModeIndex", get_sceneModeIndex());
    settings.endGroup();

    settings.sync();
}

void DroidianCamera::loadCameraSettings()
{
    QSettings settings;

    QString str = "Camera";
    str.append(QString::number(m_cameraId));

    settings.beginGroup(str);
    setAspectRatio(settings.value("aspectRatio").toInt());
    setAvailableResolutionIndex(settings.value("resolutionIndex").toInt());
    setSceneModeIndex(settings.value("sceneModeIndex").toInt());
    settings.endGroup();

    qDebug()<<"Settings loaded for"<<str;
}