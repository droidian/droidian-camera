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
#include <sys/select.h>
#include <errno.h>

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
	int sampleRate = m_settings.value("HW-Encoder/audio-sampling-rate", 48000).toInt();

	QAudioFormat format;
	format.setSampleRate(sampleRate);
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
	m_audioSocketFd = open("/dev/socket/micshm", O_WRONLY | O_NONBLOCK);
	if (m_audioSocketFd < 0) {
		qWarning() << "Failed to open /dev/socket/micshm: "
			   << strerror(errno);
		return;
	}

	if (!m_audioSource || !m_audioDevice) {
		qWarning() << "Audio source not initialized";
		return;
	}

	connect(m_audioDevice, &QIODevice::readyRead, this, &AudioStream::handleAudioReadyRead);

	qDebug() << "Started audiostream in " << QThread::currentThread();
}

void AudioStream::handleAudioReadyRead()
{
	QByteArray buffer = m_audioDevice->readAll();
	if (buffer.isEmpty()) {
		return;
	}

	const char* data = buffer.constData();
	qint64 totalBytes = buffer.size();
	qint64 bytesWritten = 0;

	while (bytesWritten < totalBytes) {
		fd_set wfds;
		FD_ZERO(&wfds);
		FD_SET(m_audioSocketFd, &wfds);
		struct timeval timeout = {0, 0};

		int ready = select(m_audioSocketFd + 1, nullptr, &wfds, nullptr, &timeout);
		if (ready <= 0 || !FD_ISSET(m_audioSocketFd, &wfds)) {
			qWarning() << "Socket not writable. Dropping remaining"
			<< (totalBytes - bytesWritten) << "bytes.";
			break;
		}

		ssize_t written = ::write(m_audioSocketFd,
			data + bytesWritten,
			totalBytes - bytesWritten);
		if (written < 0) {
			if (errno == EAGAIN || errno == EWOULDBLOCK) {
				qWarning() << "Socket temporarily unavailable. Dropping.";
			} else {
				qWarning() << "Write error:" << strerror(errno);
			}
			break;
		}

		bytesWritten += written;
	}
}