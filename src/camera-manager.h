/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QObject>
#include <QList>
#include <QSize>
#include <QImage>
#include <QSettings>

#include <hybris/camera/camera_compatibility_layer.h>
#include <hybris/camera/camera_compatibility_layer_capabilities.h>

struct CameraDevice {
	int camId;
	int type;
	int orientation;
	QList<QSize> videoSizes;
	QList<QSize> pictureSizes;
	QList<QSize> previewSizes;
	QSize curVidSize;
	QSize curPicSize;
	QSize curPrevSize;
};

class CameraManager : public QObject {
	Q_OBJECT

    public:
	explicit CameraManager(QObject *parent = nullptr);
	~CameraManager();
	
	enum CamMode { PictureMode, VideoMode, QrMode, Undefined };
	Q_ENUM(CamMode)

	enum Flash {
		FLASH_OFF,
		FLASH_AUTO,
		FLASH_ON,
		FLASH_TORCH,
		FLASH_RED_EYE
	};
	Q_ENUM(Flash)

	QList<CameraDevice> availableCameras() const;
	CameraDevice &currentCamera();
	void setCurrentCamera(int cameraId);
	void setVideoSize(const QSize &size);
	void setPictureSize(const QSize &size);
	void restartPreview();
	void takePicture();
	CamMode camMode() const;
	void setCamMode(CamMode mode);

	Flash flash();
	void setFlash(Flash mode);

	QSize currentVideoSize() const
	{
		return m_currentCamera.curVidSize;
	}
	int currentOrientation() const
	{
		return m_currentCamera.orientation;
	}

	int camId() const;
	void setCamId(int id);

	int zoom() const;
	void setZoom(int zoom);
	int maxZoom() const
	{
		return m_maxZoom;
	}

	int videoBitRate() const
	{
		return m_videoBitRate;
	}
	void setVideoBitRate(int bitRate);

	bool withMic() const;
	void setWithMic(bool enable);

	bool picAspectWide()
	{
		return m_picAspectWide;
	}
	void setPicAspectWide(bool wide);

	int effectiveRotation()
	{
		return m_effectiveRotation;
	};

	CameraControl *cameraControl() const
	{
		return m_cameraControl;
	}
	CameraControlListener *cameraListener() const
	{
		return m_listener;
	}

	QSize getMaxSizeForAspect(const QList<QSize> &sizes,
				  double targetAspect);

    public Q_SLOTS:
	void onReadyForPreview();

    Q_SIGNALS:
	void cameraChanged(const CameraDevice &device);
	void cameraSizesChanged();
	void previewSizeChanged(const QSize &size);
	void previewNeedsUpdate();
	void compressedImageCaptured(QImage);
	void rawImageCaptured();
	void camModeChanged(CameraManager::CamMode mode);
	void camIdChanged();
	void zoomChanged();
	void withMicChanged();
	void maxZoomChanged();
	void videoBitRateChanged();
	void picAspectWideChanged();
	void flashChanged();
	void effectiveRotationChanged(int angle);
	void needFlipChanged(bool flip);

    private:
	QList<CameraDevice> m_cameras;
	CameraDevice m_currentCamera;
	int m_currentCameraId = -1;
	CamMode m_camMode = Undefined;
	int m_camId = -1;
	int m_zoom = 1;
	int m_maxZoom = 1;
	bool m_withMic = false;
	int m_videoBitRate = 3;
	bool m_picAspectWide = true;
	Flash m_flashMode;
	int m_effectiveRotation = 0;
	int m_screenOrientation = 0;

	CameraControl *m_cameraControl = nullptr;
	CameraControlListener *m_listener = nullptr;

	void loadCameraDevices();
	void enumerateSizes();

	static void setPicSize_cb(void *ctx, int width, int height);
	static void setVidSize_cb(void *ctx, int width, int height);
	static void setPrevSize_cb(void *ctx, int width, int height);

	static void data_compressed_image_cb(void *data, uint32_t size,
					     void *context);
	static void data_raw_image_cb(void *data, uint32_t size, void *context);
	static void preview_texture_needs_update_cb(void *ctx);

	FlashMode convertFlashMode(CameraManager::Flash mode);
	CameraManager::Flash convertFromFlashMode(FlashMode mode);

	void setEffectiveRotation(int screenOrientation);
	QSettings m_settings;
};