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
#include <QTimer>
#include <QElapsedTimer>

#include <camera-renderer.h>

extern "C" {
    #include <libavformat/avformat.h>
    #include <libavcodec/avcodec.h>
    #include <libavutil/opt.h>
    #include <libswscale/swscale.h>
    #include <libavutil/audio_fifo.h>
}

struct FFmpegContext {
    AVFormatContext* fmtCtx = nullptr;

    // Video
    AVCodecContext* videoCodecCtx = nullptr;
    AVStream* videoStream = nullptr;
    AVFrame* videoFrame = nullptr;
    SwsContext* swsCtx = nullptr;
    int64_t lastVideoPts = -1;
    qint64 lastVideoTimestampUs = 0;

    // Audio
    AVCodecContext* audioCodecCtx = nullptr;
    AVStream* audioStream = nullptr;
    AVFrame* audioFrame = nullptr;
    AVAudioFifo* audioFifo = nullptr;
    QAudioSource* audioSource = nullptr;
    QIODevice* audioIO = nullptr;
    int64_t audioPts = 0;
    int64_t lastAudioPts = -1;

    // State
    bool initialized = false;
};

struct RecordingSetting {
    bool withMic = false;
    QString crf = "23";
    QString filename = "";
    QString tune = "zerolatency";
    QString profile = "baseline";

};

class FFmpegRecorder : public QObject {
	Q_OBJECT

    public:
	explicit FFmpegRecorder(QObject *parent, CameraRenderer *renderer, RecordingSetting setting);
	~FFmpegRecorder();

    bool isRecording()
    {
    	return m_isRecording;
    }

    Q_SIGNALS:
    void recordingStarted();
    void recordingStopped();

    public Q_SLOTS:
    void startRecording();
    void stopRecording();
    void onNewFrameAvailable(std::vector<uint8_t> buffer);

    private:
    CameraRenderer *m_renderer = nullptr;
	FFmpegContext m_ffmpeg;
    bool m_isRecording = false;

	void encodeVideoFrame(const uint8_t* rawData, qint64 timestampUs);
    void writeVideoFrame();

    void encodeAudioFrames(qint64 timestampUs);
    void writeAudioFrame(qint64 timestampUs);

    void onVideoTimerTick();

    bool initFormatContext(QString filename);
    bool initVideoStream();
    bool initAudioStream();
    bool setupAudioCapture();
    bool allocateVideoFrame();
    bool allocateAudioFrame();
    void flushEncoder(AVCodecContext* ctx, AVStream* stream);
    QSize m_videoSize;
    RecordingSetting m_recordSetting;
    bool m_isLandscape = false;

    QTimer *m_recordTimer = nullptr;
    QElapsedTimer m_timestamp;
    std::vector<uint8_t> m_lastFrameBuffer;
    qint64 m_lastEncodedTimestamp = -1;
};