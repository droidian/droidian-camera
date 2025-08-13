/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <QDebug>
#include <QAudioFormat>
#include <QMediaDevices>
#include <QThread>

#include <fcntl.h>
#include <unistd.h>

#include <audiostream.h>

AudioStream::AudioStream(QObject *parent)
	: QObject(parent)
{
}

AudioStream::~AudioStream()
{
}

void AudioStream::setupAudioSource()
{
	qDebug() << "Setup audio source...";
	QAudioFormat format;
	format.setSampleRate(48000);
	format.setChannelCount(1);
	format.setSampleFormat(QAudioFormat::Int16);

	QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();
	if (!inputDevice.isFormatSupported(format)) {
		qWarning() << "Default format not supported, trying preferred"
			   << inputDevice.preferredFormat();
		format = inputDevice.preferredFormat();
	}

	m_audioSource = new QAudioSource(inputDevice, format, this);
	m_audioDevice = m_audioSource->start();

	if (!m_audioDevice || !m_audioDevice->isOpen()) {
		qWarning() << "Failed to start QAudioSource";
	}
	qDebug() << "Using format:" << inputDevice.preferredFormat();
}

void AudioStream::stopStream()
{
	qDebug() << "Stopping audio stream...";
	if (m_audioDevice) {
		m_audioDevice->close();
		m_audioDevice = nullptr;
	}

	qDebug() << "Stopping audio source...";
	if (m_audioSource) {
		m_audioSource->stop();
	}

	qDebug() << "Closing socket...";
	if (m_audioSocketFd >= 0) {
		close(m_audioSocketFd);
		m_audioSocketFd = -1;
	}
	qDebug() << "Socket closed...";
}

void AudioStream::startStream()
{
	setupAudioSource();

	qDebug() << "Starting audiostream...";
	m_audioSocketFd = open("/dev/socket/micshm", O_WRONLY);
	if (m_audioSocketFd < 0) {
		qWarning() << "Failed to open /dev/socket/micshm: "
			   << strerror(errno);
		return;
	}

	if (!m_audioSource || !m_audioDevice) {
		qWarning() << "Audio source not initialized";
		return;
	}

	connect(m_audioDevice, &QIODevice::readyRead, this, [this]() {
		QByteArray buffer = m_audioDevice->readAll();
		if (!buffer.isEmpty()) {
			ssize_t written = ::write(m_audioSocketFd,
						  buffer.constData(),
						  buffer.size());
			if (written < 0) {
				qWarning()
					<< "Failed to write to /dev/socket/micshm:"
					<< strerror(errno);
			}
		}
	});
	qDebug() << "Started audiostream in " << QThread::currentThread();
}
