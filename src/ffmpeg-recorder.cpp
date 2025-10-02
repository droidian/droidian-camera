/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <ffmpeg-recorder.h>

FFmpegRecorder::FFmpegRecorder(QObject *parent, CameraRenderer *renderer, RecordingSetting setting)
    : QObject(nullptr)
    , m_renderer(renderer)
    , m_recordSetting(setting)
{}

FFmpegRecorder::~FFmpegRecorder()
{}

void FFmpegRecorder::startRecording() {

    if(!m_renderer)
        return;

    m_videoSize = m_renderer->getTextureSize();
    m_isLandscape = m_renderer->isLandscape();

    if (!initFormatContext(m_recordSetting.filename))
        return;
    if (!initVideoStream())
        return;
    if (!allocateVideoFrame())
        return;

    if(m_recordSetting.withMic){
        if (!initAudioStream())
            return;
        if (!setupAudioCapture())
            return;
        if (!allocateAudioFrame())
            return;
    }

    m_ffmpeg.fmtCtx->flags |= AVFMT_FLAG_AUTO_BSF;

    AVDictionary* opts = nullptr;
    av_dict_set(&opts, "movflags", "faststart", 0);
    av_dict_set(&opts, "avoid_negative_ts", "auto", 0);

    if (avformat_write_header(m_ffmpeg.fmtCtx, &opts) < 0) {
        qWarning() << "Could not write header";
        av_dict_free(&opts);
        return;
    }

    av_dict_free(&opts);

    m_ffmpeg.initialized = true;
    m_isRecording = true;

    m_recordTimer = new QTimer(this);
    m_recordTimer->setInterval(33);
    connect(m_recordTimer, &QTimer::timeout, this, &FFmpegRecorder::onVideoTimerTick);
    m_recordTimer->start();

    connect(m_renderer, &CameraRenderer::newFrameAvailable, this, &FFmpegRecorder::onNewFrameAvailable);
    m_renderer->startSwRecording(true);

    Q_EMIT recordingStarted();
    qDebug() << "Recording started.";
}

bool FFmpegRecorder::initFormatContext(QString filename) {
    avformat_alloc_output_context2(&m_ffmpeg.fmtCtx, nullptr, nullptr, filename.toUtf8().constData());
    if (!m_ffmpeg.fmtCtx) {
        qWarning() << "Could not allocate format context";
        return false;
    }

    if (!(m_ffmpeg.fmtCtx->oformat->flags & AVFMT_NOFILE)) {
        if (avio_open(&m_ffmpeg.fmtCtx->pb, filename.toUtf8().constData(), AVIO_FLAG_WRITE) < 0) {
            qWarning() << "Could not open output file";
            return false;
        }
    }
    return true;
}

bool FFmpegRecorder::initVideoStream() {
    const AVCodec* codec = avcodec_find_encoder(AV_CODEC_ID_H264);
    if (!codec) {
        qWarning() << "H.264 encoder not found";
        return false;
    }

    m_ffmpeg.videoStream = avformat_new_stream(m_ffmpeg.fmtCtx, codec);
    if (!m_ffmpeg.videoStream) {
        qWarning() << "Failed to create video stream";
        return false;
    }

    AVCodecContext* ctx = avcodec_alloc_context3(codec);
    m_ffmpeg.videoCodecCtx = ctx;

    ctx->codec_id = codec->id;

    if (!m_isLandscape) {
        ctx->width = m_videoSize.height();
        ctx->height = m_videoSize.width();
    } else {
        ctx->width = m_videoSize.width();
        ctx->height = m_videoSize.height();
    }

    ctx->time_base = {1, 90000};
    ctx->framerate = AVRational{30, 1};
    ctx->gop_size = 250;
    ctx->max_b_frames = 0;
    ctx->delay = 0;
    ctx->pix_fmt = AV_PIX_FMT_YUV420P;

    ctx->color_range = AVCOL_RANGE_MPEG;
    ctx->color_primaries = AVCOL_PRI_BT470BG;
    ctx->color_trc = AVCOL_TRC_SMPTE170M;
    ctx->colorspace = AVCOL_SPC_BT470BG;

    if (m_ffmpeg.fmtCtx->oformat->flags & AVFMT_GLOBALHEADER)
        ctx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;

    AVDictionary* opts = nullptr;
    av_dict_set(&opts, "preset", "ultrafast", 0);
    av_dict_set(&opts, "tune", m_recordSetting.tune.toUtf8().constData(), 0);
    av_dict_set(&opts, "crf", m_recordSetting.crf.toUtf8().constData(), 0);
    av_dict_set(&opts, "profile", m_recordSetting.profile.toUtf8().constData(), 0);
    av_dict_set(&opts, "level", m_recordSetting.level.toUtf8().constData(), 0);

    av_dict_set(&opts, "rc-lookahead", "0", 0);
    av_dict_set(&opts, "refs", "1", 0);
    av_dict_set(&opts, "threads", "1", 0);
    av_dict_set(&opts, "lookahead_threads", "1", 0);
    av_dict_set(&opts, "psy", "0", 0);
    av_dict_set(&opts, "psy_rd", "0:0", 0);

    if (avcodec_open2(ctx, codec, &opts) < 0) {
        qWarning() << "Could not open video codec";
        av_dict_free(&opts);
        return false;
    }

    av_dict_free(&opts);

    avcodec_parameters_from_context(m_ffmpeg.videoStream->codecpar, ctx);
    m_ffmpeg.videoStream->time_base = ctx->time_base;

    if (!m_isLandscape)
        m_ffmpeg.swsCtx = sws_getContext(
            m_videoSize.width(), m_videoSize.height(), AV_PIX_FMT_RGBA,
            m_videoSize.height(), m_videoSize.width(), AV_PIX_FMT_YUV420P,
            SWS_BILINEAR, nullptr, nullptr, nullptr
        );
    else
        m_ffmpeg.swsCtx = sws_getContext(
            m_videoSize.width(), m_videoSize.height(), AV_PIX_FMT_RGBA,
            m_videoSize.width(), m_videoSize.height(), AV_PIX_FMT_YUV420P,
            SWS_BILINEAR, nullptr, nullptr, nullptr
        );

    return true;
}

bool FFmpegRecorder::initAudioStream() {
    const AVCodec* codec = avcodec_find_encoder(AV_CODEC_ID_AAC);
    if (!codec) {
        qWarning() << "AAC encoder not found";
        return false;
    }

    m_ffmpeg.audioStream = avformat_new_stream(m_ffmpeg.fmtCtx, codec);
    m_ffmpeg.audioCodecCtx = avcodec_alloc_context3(codec);
    AVCodecContext* ctx = m_ffmpeg.audioCodecCtx;

    ctx->sample_fmt = AV_SAMPLE_FMT_FLTP;
    ctx->bit_rate = 128000;
    ctx->sample_rate = 44100;
    ctx->ch_layout = AV_CHANNEL_LAYOUT_STEREO;
    ctx->time_base = AVRational{1, ctx->sample_rate};

    if (m_ffmpeg.fmtCtx->oformat->flags & AVFMT_GLOBALHEADER)
        ctx->flags |= AV_CODEC_FLAG_GLOBAL_HEADER;

    if (avcodec_open2(ctx, codec, nullptr) < 0) {
        qWarning() << "Could not open audio codec";
        return false;
    }

    avcodec_parameters_from_context(m_ffmpeg.audioStream->codecpar, ctx);
    m_ffmpeg.audioStream->time_base = ctx->time_base;

    return true;
}

bool FFmpegRecorder::setupAudioCapture() {
    QAudioFormat format;
    format.setSampleRate(44100);
    format.setChannelCount(2);
    format.setSampleFormat(QAudioFormat::Float);

    m_ffmpeg.audioSource = new QAudioSource(format, this);
    m_ffmpeg.audioIO = m_ffmpeg.audioSource->start();
    return m_ffmpeg.audioIO != nullptr;
}

bool FFmpegRecorder::allocateVideoFrame() {
    m_ffmpeg.videoFrame = av_frame_alloc();
    m_ffmpeg.videoFrame->format = m_ffmpeg.videoCodecCtx->pix_fmt;
    m_ffmpeg.videoFrame->width = m_ffmpeg.videoCodecCtx->width;
    m_ffmpeg.videoFrame->height = m_ffmpeg.videoCodecCtx->height;

    return av_frame_get_buffer(m_ffmpeg.videoFrame, 32) >= 0;
}

bool FFmpegRecorder::allocateAudioFrame() {
    m_ffmpeg.audioFrame = av_frame_alloc();
    m_ffmpeg.audioFrame->nb_samples = m_ffmpeg.audioCodecCtx->frame_size;
    m_ffmpeg.audioFrame->format = m_ffmpeg.audioCodecCtx->sample_fmt;
    av_channel_layout_copy(&m_ffmpeg.audioFrame->ch_layout, &m_ffmpeg.audioCodecCtx->ch_layout);

    if (av_frame_get_buffer(m_ffmpeg.audioFrame, 0) < 0)
        return false;

    m_ffmpeg.audioFifo = av_audio_fifo_alloc(
        m_ffmpeg.audioCodecCtx->sample_fmt,
        m_ffmpeg.audioCodecCtx->ch_layout.nb_channels,
        1
    );

    m_ffmpeg.audioPts = 0;
    return true;
}

void FFmpegRecorder::flushEncoder(AVCodecContext* ctx, AVStream* stream) {
    avcodec_send_frame(ctx, nullptr);
    AVPacket* pkt = av_packet_alloc();

    while (true) {
        int ret = avcodec_receive_packet(ctx, pkt);
        if (ret == AVERROR(EAGAIN) || ret == AVERROR_EOF)
            break;
        else if (ret < 0)
            break;

        pkt->stream_index = stream->index;
        av_packet_rescale_ts(pkt, ctx->time_base, stream->time_base);
        av_interleaved_write_frame(m_ffmpeg.fmtCtx, pkt);
        av_packet_unref(pkt);
    }

    av_packet_free(&pkt);
}

void FFmpegRecorder::stopRecording() {
    if (!m_ffmpeg.initialized)
        return;

    qDebug() << "Recording stopping...";
    m_isRecording = false;

    m_recordTimer->stop();
    disconnect(m_recordTimer, &QTimer::timeout, this, &FFmpegRecorder::onVideoTimerTick);

    m_renderer->startSwRecording(false);
    disconnect(m_renderer, &CameraRenderer::newFrameAvailable,
           this, &FFmpegRecorder::onNewFrameAvailable);

    if (m_ffmpeg.audioSource) {
        m_ffmpeg.audioSource->stop();
        delete m_ffmpeg.audioSource;
    }
    
    flushEncoder(m_ffmpeg.videoCodecCtx, m_ffmpeg.videoStream);
    if(m_recordSetting.withMic)
        flushEncoder(m_ffmpeg.audioCodecCtx, m_ffmpeg.audioStream);

    av_write_trailer(m_ffmpeg.fmtCtx);

    av_frame_free(&m_ffmpeg.videoFrame);

    if(m_recordSetting.withMic)
        av_frame_free(&m_ffmpeg.audioFrame);
    sws_freeContext(m_ffmpeg.swsCtx);

    if(m_recordSetting.withMic)
        av_audio_fifo_free(m_ffmpeg.audioFifo);

    avcodec_free_context(&m_ffmpeg.videoCodecCtx);
    if(m_recordSetting.withMic)
        avcodec_free_context(&m_ffmpeg.audioCodecCtx);

    if (!(m_ffmpeg.fmtCtx->oformat->flags & AVFMT_NOFILE))
        avio_closep(&m_ffmpeg.fmtCtx->pb);

    avformat_free_context(m_ffmpeg.fmtCtx);
    m_ffmpeg = {};
    Q_EMIT recordingStopped();
    qDebug() << "Recording stopped.";
}

void FFmpegRecorder::encodeVideoFrame(const uint8_t* rawData, qint64 timestampUs) {
    if (!m_ffmpeg.initialized || !m_ffmpeg.videoCodecCtx || !m_ffmpeg.videoFrame)
        return;

    uint8_t* inData[1] = { const_cast<uint8_t*>(rawData) };
    int inLinesize[1] = { m_videoSize.width() * 4 };

    sws_scale(
        m_ffmpeg.swsCtx,
        inData,
        inLinesize,
        0,
        m_videoSize.height(),
        m_ffmpeg.videoFrame->data,
        m_ffmpeg.videoFrame->linesize
    );

    m_ffmpeg.lastVideoTimestampUs = timestampUs;

    int64_t pts = av_rescale_q(timestampUs, {1, 1000000}, m_ffmpeg.videoCodecCtx->time_base);
    if (pts <= m_ffmpeg.lastVideoPts)
        pts = m_ffmpeg.lastVideoPts + 1;
    m_ffmpeg.lastVideoPts = pts;

    m_ffmpeg.videoFrame->pts = pts;

    if (avcodec_send_frame(m_ffmpeg.videoCodecCtx, m_ffmpeg.videoFrame) < 0) {
        qWarning() << "Failed to send video frame to encoder";
        return;
    }

    AVPacket* pkt = av_packet_alloc();
    while (avcodec_receive_packet(m_ffmpeg.videoCodecCtx, pkt) == 0) {
        pkt->stream_index = m_ffmpeg.videoStream->index;
        av_packet_rescale_ts(pkt, m_ffmpeg.videoCodecCtx->time_base, m_ffmpeg.videoStream->time_base);
        av_interleaved_write_frame(m_ffmpeg.fmtCtx, pkt);
        av_packet_unref(pkt);
    }
    av_packet_free(&pkt);
}

void FFmpegRecorder::writeAudioFrame(qint64 timestampUs) {
    if (!m_ffmpeg.initialized || !m_ffmpeg.audioIO || !m_ffmpeg.audioFifo || !m_isRecording)
        return;

    QByteArray inputData = m_ffmpeg.audioIO->readAll();
    if (inputData.isEmpty()) return;

    int sampleSize = sizeof(float);
    int numChannels = 2;
    int samples = inputData.size() / (sampleSize * numChannels);
    if (samples <= 0) return;

    const float* interleaved = reinterpret_cast<const float*>(inputData.constData());

    float* planar[2] = {
        new float[samples],
        new float[samples]
    };

    for (int i = 0; i < samples; ++i) {
        planar[0][i] = interleaved[i * 2];
        planar[1][i] = interleaved[i * 2 + 1];
    }

    if (av_audio_fifo_realloc(m_ffmpeg.audioFifo, av_audio_fifo_size(m_ffmpeg.audioFifo) + samples) < 0) {
        qWarning() << "Failed to realloc audio FIFO";
        delete[] planar[0];
        delete[] planar[1];
        return;
    }

    uint8_t* planarData[2] = {
        reinterpret_cast<uint8_t*>(planar[0]),
        reinterpret_cast<uint8_t*>(planar[1])
    };

    av_audio_fifo_write(m_ffmpeg.audioFifo, (void**)planarData, samples);

    delete[] planar[0];
    delete[] planar[1];

    encodeAudioFrames(timestampUs);
}

void FFmpegRecorder::encodeAudioFrames(qint64 timestampUs) {
    AVCodecContext* ctx = m_ffmpeg.audioCodecCtx;

    while (av_audio_fifo_size(m_ffmpeg.audioFifo) >= ctx->frame_size) {
        av_audio_fifo_read(m_ffmpeg.audioFifo,
                           (void**)m_ffmpeg.audioFrame->data,
                           ctx->frame_size);

        m_ffmpeg.audioFrame->nb_samples = ctx->frame_size;

        int64_t audioPts = av_rescale_q(timestampUs, {1, 1000000}, ctx->time_base);
        if (audioPts <= m_ffmpeg.lastAudioPts)
            audioPts = m_ffmpeg.lastAudioPts + ctx->frame_size;

        m_ffmpeg.audioFrame->pts = audioPts;
        m_ffmpeg.lastAudioPts = audioPts;

        if (avcodec_send_frame(ctx, m_ffmpeg.audioFrame) < 0) {
            qWarning() << "Failed to send audio frame to encoder";
            return;
        }

        AVPacket* pkt = av_packet_alloc();
        while (avcodec_receive_packet(ctx, pkt) == 0) {
            pkt->stream_index = m_ffmpeg.audioStream->index;
            av_packet_rescale_ts(pkt, ctx->time_base, m_ffmpeg.audioStream->time_base);
            av_interleaved_write_frame(m_ffmpeg.fmtCtx, pkt);
            av_packet_unref(pkt);
        }
        av_packet_free(&pkt);
    }
}

void FFmpegRecorder::onNewFrameAvailable(std::vector<uint8_t> buffer)
{
    if (!m_ffmpeg.initialized)
        return;
    m_lastFrameBuffer = std::move(buffer);
}

void FFmpegRecorder::onVideoTimerTick()
{
    if (!m_ffmpeg.initialized || m_lastFrameBuffer.empty())
        return;

    if(m_lastEncodedTimestamp == -1){
        m_lastEncodedTimestamp = 0;
        m_timestamp.start();
    } else {
        m_lastEncodedTimestamp = m_timestamp.nsecsElapsed() / 1000;
    }

    encodeVideoFrame(m_lastFrameBuffer.data(), m_lastEncodedTimestamp);
    if (m_recordSetting.withMic)
        writeAudioFrame(m_lastEncodedTimestamp);
}
