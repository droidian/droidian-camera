/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <hybris/media/media_recorder_layer.h>
#include <hybris/camera/camera_compatibility_layer.h>

#include <QFile>
#include <QDebug>

#include <fcntl.h>
#include <unistd.h>

#include <audiostream.h>
#include <camera-recorder.h>

CameraRecorder::CameraRecorder(QObject *parent)
	: QObject(parent)
{
	m_observer = android_media_recorder_observer_new();
	android_media_recorder_observer_set_cb(m_observer, onRecordingStarted,
					       this);
}

CameraRecorder::~CameraRecorder()
{
	stop();
	if (m_observer) {
		m_observer = nullptr;
	}
}

void CameraRecorder::setCamera(CameraControl *control)
{
	m_cameraControl = control;
}

void CameraRecorder::setVideoSize(const QSize &size)
{
	m_videoSize = size;
}

void CameraRecorder::setMicEnabled(bool enable)
{
	m_withMic = enable;
}

void CameraRecorder::setOrientation(int angle)
{
	m_orientation = angle;
}

void CameraRecorder::setOutputPath(const QString &path)
{
	m_outputPath = path;
}

void CameraRecorder::setVideoBitRate(int bitRate)
{
	m_videoBitRate = bitRate;
}

bool CameraRecorder::start()
{
	if (!m_cameraControl || m_videoSize.isEmpty() || m_outputPath.isEmpty())
		return false;

	int fd = open(m_outputPath.toUtf8().constData(), O_WRONLY | O_CREAT,
		      S_IRUSR | S_IWUSR);
	if (fd < 0) {
		qWarning() << "Failed to open output file:" << m_outputPath;
		return false;
	}

	if (!m_recorder) {
		m_recorder = android_media_new_recorder();
		android_recorder_set_error_cb(m_recorder, onError, this);
		android_recorder_set_audio_read_cb(m_recorder, onReadAudio,
						   this);
	}

	android_camera_unlock(m_cameraControl);

	auto trySet = [](int ret, const char *msg) {
		if (ret < 0) {
			qWarning() << msg;
			return false;
		}
		return true;
	};

	if (!(trySet(android_recorder_setCamera(m_recorder, m_cameraControl),
		     "setCamera failed") &&
	      (!m_withMic ||
	       trySet(android_recorder_setAudioSource(
			      m_recorder, ANDROID_AUDIO_SOURCE_CAMCORDER),
		      "setAudioSource failed")) &&
	      trySet(android_recorder_setVideoSource(
			     m_recorder, ANDROID_VIDEO_SOURCE_CAMERA),
		     "setVideoSource failed") &&
	      trySet(android_recorder_setOutputFormat(
			     m_recorder, ANDROID_OUTPUT_FORMAT_MPEG_4),
		     "setOutputFormat failed") &&
	      (!m_withMic ||
	       trySet(android_recorder_setAudioEncoder(
			      m_recorder, ANDROID_AUDIO_ENCODER_AAC),
		      "setAudioEncoder failed")) &&
	      trySet(android_recorder_setVideoEncoder(
			     m_recorder, ANDROID_VIDEO_ENCODER_H264),
		     "setVideoEncoder failed") &&
	      trySet(android_recorder_setOutputFile(m_recorder, fd),
		     "setOutputFile failed") &&
	      trySet(android_recorder_setVideoSize(m_recorder,
						   m_videoSize.width(),
						   m_videoSize.height()),
		     "setVideoSize failed") &&
	      trySet(android_recorder_setVideoFrameRate(m_recorder, 30),
		     "setVideoFrameRate failed")))
		return false;

	if (m_withMic) {
		android_recorder_setParameters(
			m_recorder, "audio-param-encoding-bitrate=128000");
		android_recorder_setParameters(
			m_recorder, "audio-param-number-of-channels=1");
		android_recorder_setParameters(
			m_recorder, "audio-param-sampling-rate=44100");
	}

	QString bitrate = QString("video-param-encoding-bitrate=%1")
				  .arg(m_videoBitRate * 1000000);
	QString rotation = QString("video-param-rotation-angle-degrees=%1")
				   .arg(m_orientation);

	android_recorder_setParameters(m_recorder,
				       bitrate.toUtf8().constData());
	android_recorder_setParameters(m_recorder,
				       rotation.toUtf8().constData());
	android_recorder_setParameters(m_recorder,
				       "video-param-encoder-profile=8");

	if (!trySet(android_recorder_prepare(m_recorder),
		    "recorder_prepare failed"))
		return false;

	qDebug() << "Starting recording to" << m_outputPath
		 << (m_withMic ? "with mic" : "no mic");

	return trySet(android_recorder_start(m_recorder),
		      "recorder_start failed");
}

void CameraRecorder::stop()
{
	if (m_recorder) {
		android_recorder_stop(m_recorder);
		android_recorder_reset(m_recorder);
		android_recorder_release(m_recorder);
		android_recorder_close(m_recorder);
		m_recorder = nullptr;
	}

	if (m_audioStream) {
		QMetaObject::invokeMethod(m_audioStream, "stopStream",
					  Qt::QueuedConnection);
		m_audioStream->deleteLater();
		m_audioStream = nullptr;
	}

	if (m_audioThread.isRunning()) {
		m_audioThread.quit();
		m_audioThread.wait();
	}

	emit recordingStopped();
}

void CameraRecorder::onRecordingStarted(bool started, void *context)
{
	auto *self = static_cast<CameraRecorder *>(context);
	if (self) {
		if (started)
			emit self->recordingStarted();
	}
}

void CameraRecorder::onError(void *context)
{
	auto *self = static_cast<CameraRecorder *>(context);
	if (self)
		emit self->errorOccurred();
}

void CameraRecorder::onReadAudio(void *context)
{
	auto *self = static_cast<CameraRecorder *>(context);
	if (self) {
		qDebug() << "MediaRecorder ready for audiostream";
		self->initAudioStream();
	}
}

void CameraRecorder::initAudioStream()
{
	if (m_audioStream)
		return;

	m_audioStream = new AudioStream();
	m_audioStream->moveToThread(&m_audioThread);
	connect(&m_audioThread, &QThread::started, m_audioStream,
		&AudioStream::startStream, Qt::QueuedConnection);
	m_audioThread.start();
}