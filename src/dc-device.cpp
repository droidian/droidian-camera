// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2024 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include <dc-device.h>
#include <QFileInfo>
#include <QStandardPaths>
#include <QDir>

void dc_focus_callback(void *data, int arg)
{
    //qDebug()<<"dc_focus_callback"<<data<<arg;
}

void dc_focus_move_callback(void *data, int arg)
{
    qDebug()<<"dc_focus_move_callback";
}

void dc_error_callback(void *data, int arg)
{
    qDebug()<<"dc_error_callback";
}

void dc_zoom_callback(void *data, int value, int arg)
{
    qDebug()<<"dc_zoom_callback";
}

void dc_raw_image_callback(void *data, DroidMediaData *mem)
{
    qDebug()<<"dc_raw_image_callback";
}

void dc_postview_frame_callback(void *data, DroidMediaData *mem)
{
    qDebug()<<"dc_postview_frame_callback";
}

void dc_raw_image_notify_callback(void *data)
{
    qDebug()<<"dc_raw_image_notify_callback";
}

void dc_preview_frame_callback(void *data, DroidMediaData *mem)
{
    qDebug()<<"dc_preview_frame_callback";
}

void dc_preview_metadata_callback(void *data, const DroidMediaCameraFace *faces, size_t num_faces)
{
    qDebug()<<"dc_preview_metadata_callback";
}

void dc_video_frame_callback(void *data, DroidMediaCameraRecordingData *video_data)
{
    qDebug()<<"dc_video_frame_callback";
}

void dc_buffers_released(void *data)
{
    qDebug()<<"dc_buffers_released";
}

DcDevice::DcDevice(int id) {
	m_camId = id;
	init();
}

void DcDevice::init()
{
    m_videoSink = new QVideoSink();
	m_camera = droid_media_camera_connect(m_camId);

	QStringList params = QString::fromLocal8Bit(droid_media_camera_get_parameters(m_camera)).split(';');

	for (const auto &str : std::as_const(params)) {
        if(str.startsWith("focus-mode-values")){
        	m_focus_modes = str.section("=", -1).split(',');
        } else if(str.startsWith("scene-mode-values")){
        	m_scene_modes = str.section("=", -1).split(',');
        } else if(str.startsWith("whitebalance-values")){
        	m_whitebalance_values = str.section("=", -1).split(',');
        } else if(str.startsWith("max-zoom")){
        	m_maxZoom = str.section("=", -1).toFloat();
        } else if(str.startsWith("picture-size-values")){
        	m_pictureResolutions.clear();
        	setAvailableResolutions("picture-size-values", str.section("=", -1).split(','));
        } else if(str.startsWith("preview-size-values")){
        	m_previewResolutions.clear();
        	setAvailableResolutions("preview-size-values", str.section("=", -1).split(','));
        } else if(str.startsWith("video-size-values")){
        	m_videoResolutions.clear();
        	setAvailableResolutions("video-size-values", str.section("=", -1).split(','));
        }
    }

    droid_media_camera_get_info(&m_camInfo, m_camId);
    droid_media_camera_disconnect(m_camera);

    loadCommonSettings();
    
    QSettings settings;

    QString str = "Workaround";
    settings.beginGroup(str);
    m_maxResolutionOnly = settings.value("maxResolutionOnly").toInt();
    settings.endGroup();

    if(!settings.contains("picturesLocation")){
        m_picturesLocation = QStandardPaths::writableLocation(QStandardPaths::PicturesLocation);
        m_picturesLocation.append("/droidian-camera");
        settings.setValue("picturesLocation", m_picturesLocation);
    } else {
        m_picturesLocation = settings.value("picturesLocation").toString();
    }

    if(!settings.contains("videosLocation")){
        m_videosLocation = QStandardPaths::writableLocation(QStandardPaths::MoviesLocation);
        m_videosLocation.append("/droidian-camera");
        settings.setValue("videosLocation", m_videosLocation);
    } else {
        m_videosLocation = settings.value("videosLocation").toString();
    }

    QDir picturesDir(m_picturesLocation);
    QDir videosDir(m_videosLocation);
    if (!picturesDir.exists())
        picturesDir.mkpath(".");
    if (!videosDir.exists())
        videosDir.mkpath(".");

    m_camera = nullptr;
}

void DcDevice::setAvailableResolutions(QString type, QStringList values)
{
	for (const auto &str : std::as_const(values)) {
        if(type == "picture-size-values"){
        	QStringList res = str.split('x');
        	m_pictureResolutions.append(QSize(res.first().toInt(), res.last().toInt()));
        } else if(type == "preview-size-values"){
        	QStringList res = str.split('x');
        	m_previewResolutions.append(QSize(res.first().toInt(), res.last().toInt()));
        } else if(type == "video-size-values"){
        	QStringList res = str.split('x');
        	m_videoResolutions.append(QSize(res.first().toInt(), res.last().toInt()));
        }
    }
}

void DcDevice::setupCb()
{
    m_cb.shutter_cb = dc_shutter_callback;
    m_cb.focus_cb = dc_focus_callback;
    m_cb.focus_move_cb = dc_focus_move_callback;
    m_cb.error_cb = dc_error_callback;
    m_cb.zoom_cb = dc_zoom_callback;
    m_cb.raw_image_cb = dc_raw_image_callback;
    m_cb.compressed_image_cb = dc_compressed_image_callback;
    m_cb.postview_frame_cb = dc_postview_frame_callback;
    m_cb.raw_image_notify_cb = dc_raw_image_notify_callback;
    m_cb.preview_frame_cb = dc_preview_frame_callback;
    m_cb.video_frame_cb = dc_video_frame_callback;
    m_cb.preview_metadata_cb = dc_preview_metadata_callback;

    droid_media_camera_set_callbacks(m_camera, &m_cb, this);

    m_cbBuffer.buffers_released = dc_buffers_released;
    m_cbBuffer.frame_available = dc_frame_available;
    m_cbBuffer.buffer_created = dc_buffer_created;

    m_bufQueue = droid_media_camera_get_buffer_queue(m_camera);
    droid_media_buffer_queue_set_callbacks(m_bufQueue, &m_cbBuffer, this);

    droid_media_init();
}

bool DcDevice::start()
{
    if(m_isBlacklisted)
        return false;

	if(m_camera != nullptr)
		stop();

	m_camera = droid_media_camera_connect(m_camId);
    setupCb();
    setResolution(m_pictureResolutions.first());
    return droid_media_camera_start_preview(m_camera);
}

void DcDevice::stop()
{
	if(m_camera != nullptr){
        droid_media_camera_stop_preview(m_camera);
		droid_media_camera_disconnect(m_camera);
		m_camera = nullptr;
        m_bufQueue = nullptr;
	}
}

float DcDevice::getMaxZoom()
{
    return m_maxZoom;
}

void DcDevice::takePicture()
{
    if(!m_maxResolutionOnly || m_maxResolutionOnly && m_currentRes == m_pictureResolutions.at(0)){
        droid_media_camera_take_picture(m_camera, 0);
    } else {
        m_saveFrame = true;
        emit imageCaptured();
    }
}

QStringList DcDevice::getSceneModes()
{
    return m_scene_modes;
}

void DcDevice::setZoom(float zoom)
{
    QString str = "zoom=";
    str.append(QString::number(zoom));
    droid_media_camera_set_parameters(m_camera, str.toStdString().c_str());
}

void DcDevice::setSceneMode(QString mode)
{
    QString str = "scene-mode=";
    str.append(mode);
    droid_media_camera_set_parameters(m_camera, str.toStdString().c_str());
}

QList<QSize> DcDevice::getResolutions(bool wide)
{
    QList<QSize> ret;

    float aspect;

    if(wide){
        aspect = 16.0/9.0;
    } else {
        aspect = 4.0/3.0;
    }

    for (const auto &res : m_pictureResolutions) {
        if(aspect == (float)res.width()/(float)res.height()){
            ret.append(res);
        }
    }

    return ret;
}

void DcDevice::loadCommonSettings()
{
    int arrSize;
    QString filePath;
    QFileInfo primaryConfig("/usr/lib/droidian/device/droidian-camera.conf");
    QFileInfo secodaryConfig("/etc/droidian-camera.conf");

    if (primaryConfig.exists()) {
        filePath = primaryConfig.absoluteFilePath();
    } else if (secodaryConfig.exists()) {
        filePath = secodaryConfig.absoluteFilePath();
    } else {
        qWarning()<<"No common configuration files found";
        qWarning()<<"Tried"<<primaryConfig.absoluteFilePath()<<"and"<<secodaryConfig.absoluteFilePath();
        return;
    }

    QSettings settings(filePath, QSettings::NativeFormat);
    settings.beginGroup("BlacklistedCameras");
    arrSize = settings.beginReadArray("camera");
    if(arrSize < 1){
        settings.endArray();
        settings.endGroup();
        return;
    }
    
    for (int i = 0; i < arrSize; ++i) {
        settings.setArrayIndex(i);
        if(settings.value("camId").toInt() == m_camId){
            qDebug()<<"Camera"<<m_camId<<"is blacklisted in the config file and will not be accessible";
            m_isBlacklisted = true;
        }
    }

    settings.endArray();
    settings.endGroup();
}

QString DcDevice::getFilename(int type)
{
    QString saveFile;
    if(!type){
        saveFile.append(m_picturesLocation);
        saveFile.append("/image");
    } else {
        saveFile.append(m_videosLocation);
        saveFile.append("/video");
    }

    saveFile.append(QDateTime::currentDateTime().toString("yyyyMMdd_hhmmsszzz"));
    if(!type)
        saveFile.append(".jpg");

    return saveFile;
}

void DcDevice::setVideoSink(QVideoSink* videoSink)
{
    m_videoSink = videoSink;
}

double DcDevice::getMP()
{
    QSize maxSize = m_pictureResolutions.at(0);
    int rnd = qRound((double)maxSize.width() * (double)maxSize.height() / 100000.0);

    return (double)rnd / 10.0;
}

bool DcDevice::isBlacklisted()
{
    return m_isBlacklisted;
}

bool DcDevice::setResolution(QSize res)
{
    QString resStr;
    m_currentRes = res;
    bool ret = false;

    if((float)16/(float)9 == (float)res.width()/(float)res.height())
        m_isWide = true;
    else
        m_isWide = false;

    resStr.append(QString::number(res.width()));
    resStr.append("x");
    resStr.append(QString::number(res.height()));
    resStr.append(";");

    QString params = "video-size=";
    params.append(resStr);
    params.append("picture-size=");
    params.append(resStr);
    params.append("preview-size=");
    params.append(resStr);

    droid_media_camera_stop_preview(m_camera);
    ret = droid_media_camera_set_parameters(m_camera, params.toStdString().c_str());
    droid_media_camera_start_preview(m_camera);
    return ret;
}

/*DroidMedia Callbacks*/

bool DcDevice::dc_buffer_created(void *data, DroidMediaBuffer *buffer)
{
    return true;
}

void DcDevice::dc_compressed_image_callback(void *data, DroidMediaData *mem)
{
    DcDevice *dc = (DcDevice*)data;
    QVideoFrame video_frame(QVideoFrameFormat(dc->m_currentRes,QVideoFrameFormat::Format_Jpeg));
    if(!video_frame.map(QVideoFrame::ReadWrite))
    {
        qWarning() << "QVideoFrame is not writable";
    }

    memcpy(video_frame.bits(0), mem->data, mem->size);
    video_frame.setRotationAngle(QVideoFrame::RotationAngle(dc->m_camInfo.orientation));

    if(!dc->m_camInfo.facing)
        video_frame.setMirrored(true);

    video_frame.unmap();
    video_frame.toImage().save(dc->getFilename(0));
}

bool DcDevice::dc_frame_available(void *data, DroidMediaBuffer *buffer)
{
    DcDevice *dc = (DcDevice*)data;
    DroidMediaBufferYCbCr ycbcr;

    DroidMediaBufferInfo info;

    droid_media_buffer_lock_ycbcr(buffer, DROID_MEDIA_BUFFER_LOCK_READ, &ycbcr);
    droid_media_buffer_get_info(buffer, &info);

    QVideoFrame video_frame(QVideoFrameFormat (QSize(info.width, info.height),QVideoFrameFormat::Format_NV21));

    if(!video_frame.map(QVideoFrame::WriteOnly))
    {
        qWarning() << "QVideoFrame is not writable";
    }

    memcpy(video_frame.bits(0), ycbcr.y, video_frame.mappedBytes(0));
    memcpy(video_frame.bits(1), ycbcr.cr, video_frame.mappedBytes(1));

    if(dc->m_camInfo.facing == 0){
        video_frame.setMirrored(true);
        video_frame.setRotationAngle(QVideoFrame::RotationAngle(dc->m_camInfo.orientation));
    } else {
        video_frame.setRotationAngle(QVideoFrame::RotationAngle(dc->m_camInfo.orientation));
    }

    video_frame.unmap();
    
    dc->m_videoSink->setVideoFrame(video_frame);

    if(dc->m_saveFrame){
        video_frame.toImage().save(dc->getFilename(0));
        dc->m_saveFrame = false;
    }

    droid_media_buffer_unlock(buffer);
    droid_media_buffer_release (buffer, NULL, NULL);
    return true;
}

void DcDevice::dc_shutter_callback(void *data)
{
    DcDevice *dc = (DcDevice*)data;
    emit dc->imageCaptured();
}