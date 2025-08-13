/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <QtCore/QRunnable>
#include <QStandardPaths>
#include <QFile>
#include <QDir>

#include <fcntl.h>
#include <unistd.h>

#include <hybris-camera.h>

class CleanupJob : public QRunnable {
    public:
	explicit CleanupJob(CameraRenderer *renderer)
		: m_renderer(renderer)
	{
	}
	void run() override
	{
		delete m_renderer;
	}

    private:
	CameraRenderer *m_renderer;
};

HybrisCamera::HybrisCamera()
	: m_cameraManager(new CameraManager(this))
	, m_cameraRecorder(new CameraRecorder(this))
{
	connect(this, &QQuickItem::windowChanged, this,
		&HybrisCamera::handleWindowChanged);

	QString baseVideoPath = QStandardPaths::writableLocation(
		QStandardPaths::MoviesLocation);
	QString basePicturePath = QStandardPaths::writableLocation(
		QStandardPaths::PicturesLocation);

	m_videoPath = baseVideoPath + "/droidian-camera";
	m_picturePath = basePicturePath + "/droidian-camera";

	QDir().mkpath(m_videoPath);
	QDir().mkpath(m_picturePath);

	connect(m_cameraManager, &CameraManager::cameraChanged, this,
		&HybrisCamera::handleCameraChanged);

	if (!m_cameraManager->availableCameras().isEmpty()) {
		setCamId(m_cameraManager->availableCameras().first().camId);
	}

	connect(m_cameraManager, &CameraManager::previewSizeChanged, this,
		[this](const QSize &size) {
			if (m_renderer)
				m_renderer->setTextureSize(size);
		});

	connect(m_cameraManager, &CameraManager::compressedImageCaptured, this,
		[this](const QImage &img) {
			saveJpeg(img);
			m_cameraManager->restartPreview();
		});

	connect(m_cameraManager, &CameraManager::rawImageCaptured, this,
		[this]() {
			qDebug() << "RAW IMAGE CALLBACK";
			m_cameraManager->restartPreview();
		});

	connect(m_cameraManager, &CameraManager::previewNeedsUpdate, this,
		[this]() {
			if (window())
				window()->requestUpdate();
		});

	connect(m_cameraManager, &CameraManager::camModeChanged, this,
		[this]() { Q_EMIT camModeChanged(); });

	connect(m_cameraManager, &CameraManager::flashChanged, this,
		[this]() { Q_EMIT flashChanged(); });

	connect(m_cameraManager, &CameraManager::zoomChanged, this,
		&HybrisCamera::zoomChanged);
	connect(m_cameraManager, &CameraManager::camIdChanged, this,
		&HybrisCamera::camIdChanged);
	connect(m_cameraManager, &CameraManager::withMicChanged, this,
		&HybrisCamera::withMicChanged);
	connect(m_cameraManager, &CameraManager::maxZoomChanged, this,
		&HybrisCamera::maxZoomChanged);
	connect(m_cameraManager, &CameraManager::videoBitRateChanged, this,
		&HybrisCamera::videoBitRateChanged);
	connect(m_cameraManager, &CameraManager::picAspectWideChanged, this,
		&HybrisCamera::picAspectWideChanged);
	connect(m_cameraRecorder, &CameraRecorder::timeLapsFpsChanged, this,
		&HybrisCamera::timeLapsFpsChanged);

	connect(m_cameraRecorder, &CameraRecorder::recordingStarted, this,
		[this]() { setRecordingState(true); });

	connect(m_cameraRecorder, &CameraRecorder::recordingStopped, this,
		[this]() { setRecordingState(false); });

	connect(m_cameraRecorder, &CameraRecorder::errorOccurred, this,
		[]() { qWarning() << "Camera recording error occurred."; });
}

void HybrisCamera::restartPreview()
{
	m_cameraManager->restartPreview();
}

void HybrisCamera::takePicture()
{
	m_cameraManager->takePicture();
}

void HybrisCamera::saveJpeg(QImage img)
{
	QString filename =
		m_picturePath + "/IMG" +
		QDateTime::currentDateTime().toString("yyyyMMdd_hhmmsszzz") +
		".jpg";
	img = img.transformed(
		QTransform().rotate(m_cameraManager->effectiveRotation()));

	if (!img.save(filename, "JPG")) {
		qWarning() << "Failed to save image to disk";
	} else {
		qDebug() << "Image saved to" << filename;
	}
}

void HybrisCamera::cleanupVideo()
{
}

void HybrisCamera::startRecording()
{
	if (!m_cameraRecorder)
		return;

	const QString filename =
		m_videoPath + "/VID" +
		QDateTime::currentDateTime().toString("yyyyMMdd_hhmmsszzz") +
		".mp4";

	m_cameraRecorder->setCamera(m_cameraManager->cameraControl());
	m_cameraRecorder->setMicEnabled(withMic());
	m_cameraRecorder->setVideoSize(m_cameraManager->currentVideoSize());
	m_cameraRecorder->setOrientation(m_cameraManager->effectiveRotation());
	m_cameraRecorder->setOutputPath(filename);
	m_cameraRecorder->setVideoBitRate(videoBitRate());

	if (!m_cameraRecorder->start()) {
		qWarning() << "Failed to start recording";
	}
}

void HybrisCamera::stopRecording()
{
	if (m_cameraRecorder)
		m_cameraRecorder->stop();
}

void HybrisCamera::setVideoSize(int width, int height)
{
	m_cameraManager->setVideoSize(QSize(width, height));
}

void HybrisCamera::sync()
{
	if (!m_renderer) {
		m_renderer = new CameraRenderer();
		connect(window(), &QQuickWindow::beforeRendering, m_renderer,
			&CameraRenderer::init, Qt::DirectConnection);
		connect(window(), &QQuickWindow::beforeRenderPassRecording,
			m_renderer, &CameraRenderer::paint,
			Qt::DirectConnection);
		if (m_cameraManager->cameraControl() != nullptr) {
			m_renderer->setCameraControl(
				m_cameraManager->cameraControl());
			connect(m_renderer, &CameraRenderer::readyForPreview,
				m_cameraManager,
				&CameraManager::onReadyForPreview);
			connect(m_cameraManager,
				&CameraManager::effectiveRotationChanged,
				m_renderer,
				&CameraRenderer::onEffectiveRotationChanged);
		}
	}
	m_renderer->setWindow(window());
}

void HybrisCamera::cleanup()
{
	delete m_renderer;
	m_renderer = nullptr;
}

void HybrisCamera::handleWindowChanged(QQuickWindow *win)
{
	if (!win)
		return;
	connect(win, &QQuickWindow::beforeSynchronizing, this,
		&HybrisCamera::sync, Qt::DirectConnection);
	connect(win, &QQuickWindow::sceneGraphInvalidated, this,
		&HybrisCamera::cleanup, Qt::DirectConnection);
	win->setColor(Qt::black);
}

void HybrisCamera::releaseResources()
{
	window()->scheduleRenderJob(new CleanupJob(m_renderer),
				    QQuickWindow::BeforeSynchronizingStage);
	m_renderer = nullptr;
}

void HybrisCamera::setRecordingState(bool state)
{
	m_isRecording = state;
	Q_EMIT recordingChanged();
}

void HybrisCamera::setWithMic(bool enable)
{
	m_cameraManager->setWithMic(enable);
}

void HybrisCamera::setCamMode(CameraManager::CamMode mode)
{
	if (m_cameraManager->camMode() != mode) {
		m_cameraManager->setCamMode(mode);
		Q_EMIT camModeChanged();
	}
}

void HybrisCamera::setFlash(CameraManager::Flash mode)
{
	if (m_cameraManager->flash() != mode) {
		m_cameraManager->setFlash(mode);
		Q_EMIT flashChanged();
	}
}

void HybrisCamera::setCamId(int id)
{
	m_cameraManager->setCamId(id);
}

void HybrisCamera::handleCameraChanged(const CameraDevice &device)
{
	qDebug() << "Camera changed. ID:" << device.camId;

	m_videoModel.clear();
	for (const QSize &size : device.videoSizes) {
		if (size == QSize(720, 480))
			m_videoModel.addVideo("480p", size.width(),
					      size.height());
		else if (size == QSize(1280, 720))
			m_videoModel.addVideo("720p", size.width(),
					      size.height());
		else if (size == QSize(1920, 1080))
			m_videoModel.addVideo("1080p", size.width(),
					      size.height());
		else if (size == QSize(2560, 1440))
			m_videoModel.addVideo("1440p", size.width(),
					      size.height());
		else if (size == QSize(3840, 2160))
			m_videoModel.addVideo("2160p", size.width(),
					      size.height());
	}

	if (m_renderer) {
		m_renderer->setCameraControl(m_cameraManager->cameraControl());
	}

	Q_EMIT videoSizesChanged();
}

void HybrisCamera::setZoom(int zoom)
{
	m_cameraManager->setZoom(zoom);
}

void HybrisCamera::setVideoBitRate(int bitRate)
{
	m_cameraManager->setVideoBitRate(bitRate);
}