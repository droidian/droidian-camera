/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QObject>
#include <QString>
#include <QSize>
#include <QThread>

struct CameraControl;
struct MediaRecorderWrapper;
struct MediaRecorderObserver;
class AudioStream;

class CameraRecorder : public QObject {
	Q_OBJECT

    public:
	explicit CameraRecorder(QObject *parent = nullptr);
	~CameraRecorder();

	void setCamera(CameraControl *control);
	void setVideoSize(const QSize &size);
	void setMicEnabled(bool enable);
	void setOrientation(int angle);
	void setOutputPath(const QString &path);
	void setVideoBitRate(int bitRate);
	void setTimeLapseFps(float fps);

	float timeLapseFps(){return m_timeLapseFps;};

	bool start();
	void stop();

    Q_SIGNALS:
	void recordingStarted();
	void recordingStopped();
	void errorOccurred();
	void requestAudioStreamStart();
	void timeLapseFpsChanged();

    private:
	void initAudioStream();

	static void onRecordingStarted(bool started, void *context);
	static void onError(void *context);
	static void onReadAudio(void *context);

	MediaRecorderWrapper *m_recorder = nullptr;
	MediaRecorderObserver *m_observer = nullptr;
	CameraControl *m_cameraControl = nullptr;

	AudioStream *m_audioStream = nullptr;
	QThread m_audioThread;

	QSize m_videoSize;
	QString m_outputPath;
	bool m_withMic = false;
	int m_orientation = 0;
	int m_videoBitRate = 3;
	float m_timeLapseFps = 0.0;
};