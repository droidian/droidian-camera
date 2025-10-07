/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QtQuick/QQuickItem>
#include <QtQuick/QQuickWindow>
#include <QSettings>

#include <camera-renderer.h>
#include <videoquality.h>

#include <camera-manager.h>
#include <camera-recorder.h>
#include <ffmpeg-recorder.h>

class HybrisCamera : public QQuickItem {
	Q_OBJECT
	QML_ELEMENT

	Q_PROPERTY(bool isRecording READ isRecording NOTIFY recordingChanged)
	Q_PROPERTY(int maxZoom READ maxZoom NOTIFY maxZoomChanged)
	Q_PROPERTY(int zoom READ zoom WRITE setZoom NOTIFY zoomChanged)
	Q_PROPERTY(int camId READ camId WRITE setCamId NOTIFY camIdChanged)
	Q_PROPERTY(bool withMic READ withMic WRITE setWithMic NOTIFY
			   withMicChanged)
	Q_PROPERTY(CameraManager::CamMode camMode READ camMode WRITE setCamMode
			   NOTIFY camModeChanged)
	Q_PROPERTY(CameraManager::Flash flash READ flash WRITE setFlash NOTIFY
			   flashChanged)
	Q_PROPERTY(bool blur READ blur WRITE setBlur NOTIFY blurChanged)
	Q_PROPERTY(VideoModel *videoModel READ videoModel CONSTANT)
	Q_PROPERTY(int videoBitRate READ videoBitRate WRITE setVideoBitRate
			   NOTIFY videoBitRateChanged)
	Q_PROPERTY(bool picAspectWide READ picAspectWide WRITE setPicAspectWide
			   NOTIFY picAspectWideChanged)
	Q_PROPERTY(float timeLapseFps READ timeLapseFps WRITE setTimeLapseFps
			   NOTIFY timeLapseFpsChanged)
	Q_PROPERTY(bool swEncode READ swEncode WRITE setSwEncode
			   NOTIFY swEncodeChanged)
	Q_PROPERTY(int encCrf READ encCrf WRITE setEncCrf
			   NOTIFY encCrfChanged)

    public:
	HybrisCamera();

	Q_INVOKABLE void takePicture();
	Q_INVOKABLE void startRecording();
	Q_INVOKABLE void stopRecording();
	Q_INVOKABLE void setVideoSize(int width, int height);
	Q_INVOKABLE void takeSnapshot();

	bool isRecording()
	{
		return m_isRecording;
	}
	int maxZoom()
	{
		return m_cameraManager->maxZoom();
	}
	int zoom()
	{
		return m_cameraManager->zoom();
	}
	CameraManager::CamMode camMode()
	{
		return m_cameraManager->camMode();
	}
	CameraManager::Flash flash()
	{
		return m_cameraManager->flash();
	}
	int camId()
	{
		return m_cameraManager->camId();
	}
	bool withMic()
	{
		return m_cameraManager->withMic();
	}
	bool blur()
	{
		return m_blur;
	}
	int videoBitRate()
	{
		return m_cameraManager->videoBitRate();
	}
	bool picAspectWide()
	{
		return m_cameraManager->picAspectWide();
	}
	float timeLapseFps()
	{
		return m_cameraRecorder->timeLapseFps();
	}
	bool swEncode()
	{
		return m_swEncode;
	}
	int encCrf()
	{
		return m_encCrf;
	}
	void setZoom(int zoom);
	void setRecordingState(bool state);
	void setCamMode(CameraManager::CamMode mode);
	void setFlash(CameraManager::Flash mode);
	void setCamId(int id);
	void setWithMic(bool enable);
	void setVideoBitRate(int bitRate);
	void setPicAspectWide(bool wide)
	{
		m_cameraManager->setPicAspectWide(wide);
	}
	void setTimeLapseFps(float fps)
	{
		m_cameraRecorder->setTimeLapseFps(fps);
	}
	void setSwEncode(bool sw)
	{
		m_swEncode = sw;
		Q_EMIT swEncodeChanged();
	}
	void setEncCrf(int crf)
	{
		m_encCrf = crf;
		Q_EMIT encCrfChanged();
	}
	VideoModel *videoModel()
	{
		return &m_videoModel;
	}

	void setBlur(bool enable)
	{
		m_blur = enable;
		if (m_renderer != nullptr)
			m_renderer->setRenderMode(m_blur);
		Q_EMIT blurChanged();
	}

    Q_SIGNALS:
	void recordingChanged();
	void maxZoomChanged();
	void zoomChanged();
	void camModeChanged();
	void flashChanged();
	void camIdChanged();
	void withMicChanged();
	void videoSizesChanged();
	void blurChanged();
	void videoBitRateChanged();
	void picAspectWideChanged();
	void swEncodeChanged();
	void encCrfChanged();
	void timeLapseFpsChanged();
	void startRecordingSignal();
	void stopRecordingSignal();
	void isLandscapeChanged();
	void newMediaSaved(QString filePath);

    public Q_SLOTS:
	void sync();
	void cleanup();

    private Q_SLOTS:
	void handleWindowChanged(QQuickWindow *win);
	void cleanupVideo();
	void handleCameraChanged(const CameraDevice &device);
    
    private:
	void releaseResources() override;

	void restartPreview();
	void saveJpeg(QImage img);

	void cleanupFFmpegRecorder();

	QString m_videoPath;
	QString m_picturePath;
	QString m_recordingFile;

	bool m_isRecording = false;
	bool m_blur = false;
	bool m_swEncode = false;
	int m_encCrf = 23;
	VideoModel m_videoModel;

	CameraRenderer *m_renderer = nullptr;

	CameraManager *m_cameraManager = nullptr;
	CameraRecorder *m_cameraRecorder = nullptr;

	FFmpegRecorder *m_ffmpegRecorder = nullptr;
	QThread *m_ffmpegThread = nullptr;

	QSettings m_settings;
};