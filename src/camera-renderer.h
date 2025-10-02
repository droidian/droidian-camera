/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#pragma once

#include <QtQuick/QQuickWindow>
#include <QOpenGLShaderProgram>
#include <QOpenGLFunctions>

#include <hybris/camera/camera_compatibility_layer.h>
#include <hybris/camera/camera_compatibility_layer_capabilities.h>

#ifndef GL_TEXTURE_EXTERNAL_OES
#define GL_TEXTURE_EXTERNAL_OES 0x8D65
#endif

struct CameraControl;

class CameraRenderer : public QObject, protected QOpenGLFunctions {
	Q_OBJECT

    public:
	enum RenderMode { Normal, Blur };

	~CameraRenderer();

	void setTextureSize(const QSize &size)
	{
		m_textureSize = size;
		m_textureWidth = size.width();
		m_textureHeight = size.height();
	}
	void setWindow(QQuickWindow *window)
	{
		m_window = window;
	}
	void setCameraControl(CameraControl *cc);
	void setRenderMode(bool blur)
	{
		if (blur)
			m_renderMode = Blur;
		else
			m_renderMode = Normal;
	}

	QSize getTextureSize()
	{
		return m_textureSize;
	}

	bool isLandscape()
	{
		return m_window->size().width() > m_window->size().height();
	}

    Q_SIGNALS:
	void readyForPreview();
	void newFrameAvailable(std::vector<uint8_t> buffer);

    public Q_SLOTS:
	void init();
	void paint();
	void onEffectiveRotationChanged(int angle)
	{
		m_effectiveRotation = angle;
		qDebug()<<m_effectiveRotation<<"Deg"<<m_window->size();
	}

	void onNeedFlipChanged(bool flip)
	{
		m_needFlip = flip;
	}

	void startSwRecording(bool recording);

    private:
    void initRecordingGl();
    void renderToFBO();
    void createFrameBuffer();
    std::vector<uint8_t> m_frameBuffer;
    int m_aPosition = -1;
    int m_aTexCoord = -1;
    int m_sTexture = -1;
    GLuint m_recordingTexture = 0;
    GLuint m_fbo = 0;
    QOpenGLShaderProgram* m_prgRecording = nullptr;

	QOpenGLShaderProgram *m_prgViewFinder = nullptr;
	QOpenGLShaderProgram *m_prgRadialBlur = nullptr;
	QQuickWindow *m_window = nullptr;

	QSize m_viewportSize;
	QSize m_textureSize;
	int m_textureWidth = 1920;
	int m_textureHeight = 1080;

	CameraControl *m_cc = nullptr;
	GLuint m_gaPositionHandle;
	GLuint m_gaTexHandle;
	GLuint m_gsTextureHandle;
	GLuint m_gmTexMatrix;
	GLuint m_textureId;
	GLushort m_indices[6] = { 0, 1, 2, 0, 2, 3 };

	GLuint m_gsRadialTextureHandle;
	GLuint m_uBlurSize;

	RenderMode m_renderMode = Normal;

	void rotateTextureCoords(GLfloat *vVertices, int orientation, bool fbo);
	int m_effectiveRotation = 0;
	bool m_needFlip = false;

	bool m_needRecFrames = false;
};