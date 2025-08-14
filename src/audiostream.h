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

    private:
	int m_audioSocketFd = -1;
	QAudioSource *m_audioSource = nullptr;
	QIODevice *m_audioDevice = nullptr;

	void setupAudioSource();
};