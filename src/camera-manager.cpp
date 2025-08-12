/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <QDebug>
#include <QOrientationSensor>
#include <QOrientationReading>

#include <camera-manager.h>

CameraManager::CameraManager(QObject *parent)
	: QObject(parent)
{
	m_listener = static_cast<CameraControlListener *>(
		calloc(1, sizeof(CameraControlListener)));
	loadCameraDevices();

	if (!m_cameras.isEmpty())
		setCurrentCamera(0);

	QOrientationSensor *orientationSensor = new QOrientationSensor(this);
	connect(orientationSensor, &QOrientationSensor::readingChanged, this,
		[=]() {
			QOrientationReading *reading =
				orientationSensor->reading();
			QOrientationReading::Orientation orientation =
				reading->orientation();
			switch (orientation) {
			case QOrientationReading::TopUp:
				m_screenOrientation = 0;
				setEffectiveRotation(m_screenOrientation);
				break;
			case QOrientationReading::TopDown:
				m_screenOrientation = 180;
				setEffectiveRotation(m_screenOrientation);
				break;
			case QOrientationReading::LeftUp:
				m_screenOrientation = 270;
				setEffectiveRotation(m_screenOrientation);
				break;
			case QOrientationReading::RightUp:
				m_screenOrientation = 90;
				setEffectiveRotation(m_screenOrientation);
				break;
			}
		});
	orientationSensor->start();
}

CameraManager::~CameraManager()
{
	if (m_cameraControl) {
		android_camera_disconnect(m_cameraControl);
		android_camera_delete(m_cameraControl);
		m_cameraControl = nullptr;
	}
}

void CameraManager::loadCameraDevices()
{
	int numCams = android_camera_get_number_of_devices();
	for (int i = 0; i < numCams; ++i) {
		CameraDevice dev{ i };
		android_camera_get_device_info(dev.camId, &dev.type,
					       &dev.orientation);
		m_cameras.append(dev);

		qDebug() << "Detected camera:" << (dev.type ? "FRONT" : "BACK")
			 << "ID:" << dev.camId
			 << "Orientation:" << dev.orientation;
	}
}

QList<CameraDevice> CameraManager::availableCameras() const
{
	return m_cameras;
}

CameraDevice &CameraManager::currentCamera()
{
	return m_currentCamera;
}

void CameraManager::setCurrentCamera(int cameraId)
{
	if (m_cameraControl) {
		android_camera_disconnect(m_cameraControl);
		android_camera_delete(m_cameraControl);
		m_cameraControl = nullptr;
	}

	m_cameraControl = android_camera_connect_by_id(cameraId, m_listener);
	m_listener->context = this;

	m_listener->on_data_compressed_image_cb = data_compressed_image_cb;
	m_listener->on_data_raw_image_cb = data_raw_image_cb;
	m_listener->on_preview_texture_needs_update_cb =
		preview_texture_needs_update_cb;

	for (auto &dev : m_cameras) {
		if (dev.camId == cameraId) {
			android_camera_get_device_info(dev.camId, &dev.type,
						       &dev.orientation);
			dev.videoSizes.clear();
			dev.pictureSizes.clear();
			dev.previewSizes.clear();

			android_camera_enumerate_supported_picture_sizes(
				m_cameraControl, setPicSize_cb, &dev);
			android_camera_enumerate_supported_video_sizes(
				m_cameraControl, setVidSize_cb, &dev);
			android_camera_enumerate_supported_preview_sizes(
				m_cameraControl, setPrevSize_cb, &dev);
			android_camera_get_max_zoom(m_cameraControl,
						    &m_maxZoom);

			m_currentCamera = dev;
			m_currentCameraId = cameraId;

			Q_EMIT cameraChanged(m_currentCamera);
			Q_EMIT cameraSizesChanged();
			Q_EMIT maxZoomChanged();

			setVideoSize(m_currentCamera.videoSizes.first());
			double targetAspect = 16.0 / 9.0;
			if (!m_picAspectWide)
				targetAspect = 4.0 / 3.0;

			QSize picSize = getMaxSizeForAspect(
				m_currentCamera.pictureSizes, targetAspect);
			setPictureSize(picSize);

			break;
		}
	}
	if (m_camMode == CamMode::Undefined)
		setCamMode(CamMode::PictureMode);

	setEffectiveRotation(m_screenOrientation);
}

void CameraManager::setVideoSize(const QSize &size)
{
	if (!m_cameraControl)
		return;

	m_currentCamera.curVidSize = size;
	android_camera_set_video_size(m_cameraControl, size.width(),
				      size.height());

	if (size.height() == 480)
		setVideoBitRate(3);
	else if (size.height() == 720)
		setVideoBitRate(6);
	else if (size.height() == 1080)
		setVideoBitRate(12);
	else if (size.height() == 1440)
		setVideoBitRate(24);
	else if (size.height() == 2160)
		setVideoBitRate(50);

	if (m_camMode == CamMode::VideoMode) {
		double targetAspect =
			(double)size.width() / (double)size.height();

		QSize prevSize = getMaxSizeForAspect(
			m_currentCamera.previewSizes, targetAspect);
		android_camera_stop_preview(m_cameraControl);
		android_camera_set_preview_size(
			m_cameraControl, prevSize.width(), prevSize.height());
		android_camera_start_preview(m_cameraControl);

		Q_EMIT previewSizeChanged(size);
	}
}

void CameraManager::setPictureSize(const QSize &size)
{
	if (!m_cameraControl)
		return;

	m_currentCamera.curPicSize = size;
	android_camera_set_picture_size(m_cameraControl,
					m_currentCamera.curPicSize.width(),
					m_currentCamera.curPicSize.height());

	double targetAspect = 16.0 / 9.0;
	if (!m_picAspectWide)
		targetAspect = 4.0 / 3.0;

	if (m_camMode == CamMode::PictureMode) {
		QSize prevSize = getMaxSizeForAspect(
			m_currentCamera.previewSizes, targetAspect);
		android_camera_stop_preview(m_cameraControl);
		android_camera_set_preview_size(
			m_cameraControl, prevSize.width(), prevSize.height());
		android_camera_set_jpeg_quality(m_cameraControl, 85);
		android_camera_start_preview(m_cameraControl);

		Q_EMIT previewSizeChanged(size);
	}
}

void CameraManager::onReadyForPreview()
{
	android_camera_start_preview(m_cameraControl);
	android_camera_set_flash_mode(m_cameraControl,
				      convertFlashMode(m_flashMode));
	setEffectiveRotation(m_screenOrientation);
}

void CameraManager::restartPreview()
{
	if (m_cameraControl)
		android_camera_start_preview(m_cameraControl);
}

void CameraManager::takePicture()
{
	if (m_cameraControl)
		android_camera_take_snapshot(m_cameraControl);
}

CameraManager::CamMode CameraManager::camMode() const
{
	return m_camMode;
}

void CameraManager::setCamMode(CameraManager::CamMode mode)
{
	if (m_camMode != mode) {
		m_camMode = mode;
		Q_EMIT camModeChanged(m_camMode);

		if (m_camMode == CamMode::VideoMode) {
			setVideoSize(m_currentCamera.videoSizes.first());
			android_camera_set_auto_focus_mode(
				m_cameraControl,
				AUTO_FOCUS_MODE_CONTINUOUS_VIDEO);
			setFlash(CameraManager::FLASH_OFF);
		} else {
			double targetAspect = 16.0 / 9.0;
			if (!m_picAspectWide)
				targetAspect = 4.0 / 3.0;

			QSize picSize = getMaxSizeForAspect(
				m_currentCamera.pictureSizes, targetAspect);
			setPictureSize(picSize);
			android_camera_set_auto_focus_mode(
				m_cameraControl,
				AUTO_FOCUS_MODE_CONTINUOUS_PICTURE);
			setFlash(CameraManager::FLASH_AUTO);
		}
	}
}

CameraManager::Flash CameraManager::flash()
{
	return m_flashMode;
}

void CameraManager::setFlash(Flash mode)
{
	android_camera_set_flash_mode(m_cameraControl, convertFlashMode(mode));
	m_flashMode = mode;
	Q_EMIT flashChanged();
}

int CameraManager::camId() const
{
	return m_camId;
}

void CameraManager::setCamId(int id)
{
	if (m_camId != id) {
		m_camId = id;
		setCurrentCamera(id);
		Q_EMIT camIdChanged();
	}
}

int CameraManager::zoom() const
{
	return m_zoom;
}

void CameraManager::setZoom(int zoom)
{
	if (m_zoom != zoom && m_cameraControl) {
		m_zoom = zoom;
		android_camera_set_zoom(m_cameraControl, zoom);
		Q_EMIT zoomChanged();
	}
}

bool CameraManager::withMic() const
{
	return m_withMic;
}

void CameraManager::setWithMic(bool enable)
{
	if (m_withMic != enable) {
		m_withMic = enable;
		Q_EMIT withMicChanged();
	}
}

void CameraManager::setPicAspectWide(bool wide)
{
	if (m_picAspectWide != wide) {
		m_picAspectWide = wide;
		double targetAspect = 16.0 / 9.0;

		if (!m_picAspectWide)
			targetAspect = 4.0 / 3.0;

		QSize picSize = getMaxSizeForAspect(
			m_currentCamera.pictureSizes, targetAspect);
		setPictureSize(picSize);
		Q_EMIT picAspectWideChanged();
	}
}

QSize CameraManager::getMaxSizeForAspect(const QList<QSize> &sizes,
					 double targetAspect)
{
	QSize maxSize;
	int maxArea = 0;
	double tolerance = 0.01;

	for (const QSize &size : sizes) {
		if (size.height() == 0)
			continue;

		double aspect =
			static_cast<double>(size.width()) / size.height();
		if (qAbs(aspect - targetAspect) <= tolerance) {
			int area = size.width() * size.height();
			if (area > maxArea) {
				maxArea = area;
				maxSize = size;
			}
		}
	}
	return maxSize;
}

void CameraManager::setVideoBitRate(int bitRate)
{
	if (m_videoBitRate != bitRate) {
		m_videoBitRate = bitRate;
		Q_EMIT videoBitRateChanged();
	}
}

void CameraManager::setPicSize_cb(void *ctx, int width, int height)
{
	auto *dev = static_cast<CameraDevice *>(ctx);
	if (dev)
		dev->pictureSizes.append(QSize(width, height));
}

void CameraManager::setVidSize_cb(void *ctx, int width, int height)
{
	auto *dev = static_cast<CameraDevice *>(ctx);
	if (dev)
		dev->videoSizes.append(QSize(width, height));
}

void CameraManager::setPrevSize_cb(void *ctx, int width, int height)
{
	auto *dev = static_cast<CameraDevice *>(ctx);
	if (dev)
		dev->previewSizes.append(QSize(width, height));
}

void CameraManager::data_compressed_image_cb(void *data, uint32_t size,
					     void *context)
{
	if (!context || !data || size == 0)
		return;

	auto *self = static_cast<CameraManager *>(context);
	QByteArray imageData(reinterpret_cast<const char *>(data),
			     static_cast<int>(size));
	QImage image;

	if (!image.loadFromData(imageData, "JPG")) {
		qWarning() << "Failed to load image from data";
		return;
	}

	Q_EMIT self->compressedImageCaptured(image);
}

void CameraManager::data_raw_image_cb(void *data, uint32_t size, void *context)
{
	auto *self = static_cast<CameraManager *>(context);
	Q_EMIT self->rawImageCaptured();
}

void CameraManager::preview_texture_needs_update_cb(void *ctx)
{
	auto *self = static_cast<CameraManager *>(ctx);
	Q_EMIT self->previewNeedsUpdate();
}

FlashMode CameraManager::convertFlashMode(CameraManager::Flash mode)
{
	switch (mode) {
	case CameraManager::FLASH_OFF:
		return FLASH_MODE_OFF;
	case CameraManager::FLASH_AUTO:
		return FLASH_MODE_AUTO;
	case CameraManager::FLASH_ON:
		return FLASH_MODE_ON;
	case CameraManager::FLASH_TORCH:
		return FLASH_MODE_TORCH;
	case CameraManager::FLASH_RED_EYE:
		return FLASH_MODE_RED_EYE;
	default:
		return FLASH_MODE_OFF;
	}
}

CameraManager::Flash CameraManager::convertFromFlashMode(FlashMode mode)
{
	switch (mode) {
	case FLASH_MODE_OFF:
		return CameraManager::FLASH_OFF;
	case FLASH_MODE_AUTO:
		return CameraManager::FLASH_AUTO;
	case FLASH_MODE_ON:
		return CameraManager::FLASH_ON;
	case FLASH_MODE_TORCH:
		return CameraManager::FLASH_TORCH;
	case FLASH_MODE_RED_EYE:
		return CameraManager::FLASH_RED_EYE;
	default:
		return CameraManager::FLASH_OFF;
	}
}

void CameraManager::setEffectiveRotation(int screenOrientation)
{
	if (currentCamera().type && screenOrientation == 90 ||
	    screenOrientation == 270) {
		m_effectiveRotation =
			(currentCamera().orientation + screenOrientation) % 360;
		m_effectiveRotation = (360 - m_effectiveRotation) % 360;
	} else {
		m_effectiveRotation = (currentCamera().orientation -
				       screenOrientation + 360) %
				      360;
	}
	Q_EMIT effectiveRotationChanged(m_effectiveRotation);
}