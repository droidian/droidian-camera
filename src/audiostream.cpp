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
#include <QDateTime>
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
    stopStream();
}

void AudioStream::setupAudioSource()
{
    qDebug() << "Setup audio source...";
    int sampleRate = 48000;

    QAudioFormat format;
    format.setSampleRate(sampleRate);
    format.setChannelCount(1);
    format.setSampleFormat(QAudioFormat::Int16);

    QAudioDevice inputDevice = QMediaDevices::defaultAudioInput();

    if (!inputDevice.isFormatSupported(format)) {
        qWarning() << "Requested format not supported. Got:"
                   << format.sampleFormat()
                   << "Falling back to preferred:" << inputDevice.preferredFormat();
        format = inputDevice.preferredFormat();
    }

    if (format.sampleFormat() != QAudioFormat::Int16 || format.channelCount() != 1) {
        qWarning() << "Audio format not supported: expected 16-bit mono. Got:"
                   << format.sampleFormat() << "channels:" << format.channelCount();
        return;
    }

    m_audioSource = new QAudioSource(inputDevice, format, this);
    m_audioDevice = m_audioSource->start();

    connect(m_audioDevice, &QIODevice::readyRead,
            this, &AudioStream::handleAudioReadyRead);
}

void AudioStream::startStream()
{
    setupAudioSource();

    m_audioSocketFd = open("/dev/socket/micshm", O_WRONLY);
    if (m_audioSocketFd < 0) {
        qWarning() << "Failed to open audio socket";
        return;
    }

    m_writeTimer = new QTimer(this);
    connect(m_writeTimer, &QTimer::timeout,
            this, &AudioStream::flushAudioBuffer);
    m_writeTimer->start(20);
}

void AudioStream::stopStream()
{
    qDebug() << "Stopping audio stream...";

    if (m_audioDevice) {
        m_audioDevice->close();
        m_audioDevice = nullptr;
    }

    if (m_audioSource) {
        m_audioSource->stop();
        delete m_audioSource;
        m_audioSource = nullptr;
    }

    if (m_audioSocketFd >= 0) {
        close(m_audioSocketFd);
        m_audioSocketFd = -1;
    }

    qDebug() << "Audio stream stopped.";
}

void AudioStream::handleAudioReadyRead()
{
    QByteArray buffer = m_audioDevice->readAll();
    if (!buffer.isEmpty()) {
        m_audioBuffer.append(buffer);
    }
}

void AudioStream::flushAudioBuffer()
{
    if (m_audioBuffer.size() != m_chunkSize) {
    	m_audioBuffer.clear();
        return;
    }

    QByteArray chunk = m_audioBuffer.left(m_chunkSize);
    m_audioBuffer.clear();

    const char* data = chunk.constData();
    qint64 totalBytes = chunk.size();
    qint64 bytesWritten = 0;

    while (bytesWritten < totalBytes) {
        fd_set wfds;
        FD_ZERO(&wfds);
        FD_SET(m_audioSocketFd, &wfds);
        struct timeval timeout = {1, 0};

        int ready = select(m_audioSocketFd + 1, nullptr, &wfds, nullptr, &timeout);
        if (ready <= 0 || !FD_ISSET(m_audioSocketFd, &wfds)) {
            qWarning() << "Socket not writable. Dropping" << (totalBytes - bytesWritten) << "bytes.";
            break;
        }

        ssize_t written = ::write(m_audioSocketFd, data + bytesWritten, totalBytes - bytesWritten);
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
