/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QObject>
#include <QAudioSource>
#include <QAudioFormat>
#include <QIODevice>
#include <QTimer>
#include <QSettings>

class AudioStream : public QObject {
	Q_OBJECT

    public:
	explicit AudioStream(QObject *parent = nullptr);
	~AudioStream();

    public Q_SLOTS:
	void startStream();
	void stopStream();

	private Q_SLOTS:
	void handleAudioReadyRead();
	void flushAudioBuffer();

    private:
	int m_audioSocketFd = -1;
	QAudioSource *m_audioSource = nullptr;
	QIODevice *m_audioDevice = nullptr;
	QByteArray m_audioBuffer;
	QTimer* m_writeTimer = nullptr;
	int m_chunkSize = 1920;
	bool m_flushing = false;

	void setupAudioSource();
	QSettings m_settings;
};