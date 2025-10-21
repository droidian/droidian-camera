/* SPDX-License-Identifier: GPL-2.0-only
 *
 * Copyright (C) 2025 Droidian Project
 *
 * Authors:
 * Alexander Rutz <alex@familyrutz.com>
 */

#include <camera-renderer.h>

CameraRenderer::~CameraRenderer()
{
	delete m_prgViewFinder;
}

void CameraRenderer::setCameraControl(CameraControl *cc)
{
	qDebug() << "CHANGE CAMERA";
	m_cc = cc;
	android_camera_set_preview_size(m_cc, m_textureWidth, m_textureHeight);
	android_camera_set_preview_texture(m_cc, m_textureId);
	android_camera_start_preview(m_cc);
}

void CameraRenderer::init()
{
	if (!m_prgViewFinder) {
		QSGRendererInterface *rif = m_window->rendererInterface();
		Q_ASSERT(rif->graphicsApi() == QSGRendererInterface::OpenGL);

		initializeOpenGLFunctions();

		m_prgViewFinder = new QOpenGLShaderProgram();
		m_prgViewFinder->addShaderFromSourceFile(
			QOpenGLShader::Vertex, ":/shaders/viewfinder.vert");
		m_prgViewFinder->addShaderFromSourceFile(
			QOpenGLShader::Fragment, ":/shaders/viewfinder.frag");

		m_prgViewFinder->link();

		m_gaPositionHandle =
			m_prgViewFinder->attributeLocation("a_position");
		m_gaTexHandle =
			m_prgViewFinder->attributeLocation("a_texCoord");
		m_gsTextureHandle =
			m_prgViewFinder->uniformLocation("s_texture");
		m_gmTexMatrix = m_prgViewFinder->uniformLocation("m_texMatrix");

		glGenTextures(1, &m_textureId);
		glBindTexture(GL_TEXTURE_EXTERNAL_OES, m_textureId);
		glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MIN_FILTER,
				GL_LINEAR);
		glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_MAG_FILTER,
				GL_LINEAR);
		glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_S,
				GL_CLAMP_TO_EDGE);
		glTexParameteri(GL_TEXTURE_EXTERNAL_OES, GL_TEXTURE_WRAP_T,
				GL_CLAMP_TO_EDGE);

		m_uBlurSize = m_prgViewFinder->uniformLocation("u_blurSize");

		initRecordingGl();
		qDebug() << "START CAMERA";
		android_camera_set_preview_size(m_cc, m_textureWidth,
						m_textureHeight);
		android_camera_set_preview_texture(m_cc, m_textureId);
		Q_EMIT readyForPreview();
	}
}

void CameraRenderer::paint()
{
	if (m_cc == nullptr)
		return;

	bool rotated =
		(m_effectiveRotation == 90 || m_effectiveRotation == 270);

	float viewportWidth = m_window->width();
	float viewportHeight = m_window->height();

	float texWidth = rotated ? m_textureHeight : m_textureWidth;
	float texHeight = rotated ? m_textureWidth : m_textureHeight;

	float textureAspectRatio = texWidth / texHeight;
	float viewportAspectRatio = viewportWidth / viewportHeight;

	float scaleX = 1.0f;
	float scaleY = 1.0f;
	float offsetX = 0.0f;
	float offsetY = 0.0f;

	if (textureAspectRatio > viewportAspectRatio) {
		scaleY = viewportAspectRatio / textureAspectRatio;
		offsetY = (1.0f - scaleY);
	} else {
		scaleX = textureAspectRatio / viewportAspectRatio;
	}

	GLfloat vVertices[] = { -scaleX, -scaleY, 0.0f, 0.0f, 0.0f,
				-scaleX, scaleY,  0.0f, 0.0f, 1.0f,
				scaleX,	 scaleY,  0.0f, 1.0f, 1.0f,
				scaleX,	 -scaleY, 0.0f, 1.0f, 0.0f };

	rotateTextureCoords(vVertices, m_effectiveRotation, false);

	if (textureAspectRatio > viewportAspectRatio) {
		for (int i = 0; i < 4; ++i) {
			vVertices[i * 5 + 1] += offsetY;
		}
	}

	m_window->beginExternalCommands();
	m_prgViewFinder->bind();

	if (m_renderMode == Blur)
		m_prgViewFinder->setUniformValue(m_uBlurSize, 1.0f / 100.0f);
	else
		m_prgViewFinder->setUniformValue(m_uBlurSize, 0.0f);

	glDisable(GL_DEPTH_TEST);
	glEnable(GL_BLEND);
	glBlendFunc(GL_SRC_ALPHA, GL_ONE);

	glEnableVertexAttribArray(m_gaPositionHandle);
	glEnableVertexAttribArray(m_gaTexHandle);

	glVertexAttribPointer(m_gaPositionHandle, 3, GL_FLOAT, GL_FALSE,
			      5 * sizeof(GLfloat), vVertices);
	glVertexAttribPointer(m_gaTexHandle, 2, GL_FLOAT, GL_FALSE,
			      5 * sizeof(GLfloat), vVertices + 3);

	glActiveTexture(GL_TEXTURE0);
	glUniform1i(m_gsTextureHandle, 0);

	android_camera_update_preview_texture(m_cc);

	glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, m_indices);

	glDisableVertexAttribArray(m_gaPositionHandle);
	glDisableVertexAttribArray(m_gaTexHandle);

	m_prgViewFinder->release();
	m_window->endExternalCommands();

	if(m_needRecFrames){
		renderToFBO(false);
		createFrameBuffer(false);
	}
	if(m_snapShot){
		renderToFBO(true);
		createFrameBuffer(true);
	}
}

void CameraRenderer::rotateTextureCoords(GLfloat *vVertices, int orientation, bool fbo)
{
    GLfloat texCoords[4][2] = {
        {0.0f, 0.0f}, {0.0f, 1.0f}, {1.0f, 1.0f}, {1.0f, 0.0f}
    };

    int mappedOrientation = orientation;
    if (fbo) {
        if (orientation == 90) mappedOrientation = 270;
        else if (orientation == 270) mappedOrientation = 90;
    }

    int rotations = (mappedOrientation / 90) % 4;

    for (int i = 0; i < 4; ++i) {
        float u = texCoords[i][0];
        float v = texCoords[i][1];

        if((m_needFlip && !fbo)
        		|| (!m_needFlip && fbo && !isLandscape())
        		|| (m_needFlip && fbo && isLandscape()))
        	u = 1.0f - u;

        if(fbo && isLandscape())
        	v = 1.0f - v;

        for (int r = 0; r < rotations; ++r) {
            float temp = u;
            u = 1.0f - v;
            v = temp;
        }

        vVertices[i * 5 + 3] = u;
        vVertices[i * 5 + 4] = v;
    }
}

void CameraRenderer::renderToFBO(bool snapshot)
{
	if (m_resizeRecTexture)
		resizeRecordingTexture();
	else
		glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);

    glViewport(0, 0, m_textureWidth, m_textureHeight);
    glClearColor(0.0, 0.0, 0.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);

    m_prgRecording->bind();
    glEnableVertexAttribArray(m_aPosition);
    glEnableVertexAttribArray(m_aTexCoord);

    GLfloat vertices[] = {
        -1.0f, -1.0f, 0.0f,  0.0f, 0.0f,
        -1.0f, 1.0f, 0.0f,  0.0f, 1.0f,
        1.0f, 1.0f, 0.0f, 1.0f, 1.0f,
        1.0f, -1.0f, 0.0f, 1.0f, 0.0f
    };

    if(!snapshot)
    	rotateTextureCoords(vertices, m_effectiveRotation, true);

    glVertexAttribPointer(m_aPosition, 3, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), vertices);
    glVertexAttribPointer(m_aTexCoord, 2, GL_FLOAT, GL_FALSE, 5 * sizeof(GLfloat), vertices + 3);

    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_recordingTexture);
    glUniform1i(m_sTexture, 0);

    glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_SHORT, m_indices);

    glDisableVertexAttribArray(m_aPosition);
    glDisableVertexAttribArray(m_aTexCoord);
    m_prgRecording->release();

    glBindFramebuffer(GL_FRAMEBUFFER, 0);
}

void CameraRenderer::createFrameBuffer(bool snapshot)
{
    std::vector<uint8_t> buffer(m_textureWidth * m_textureHeight * 4);
    glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    glPixelStorei(GL_PACK_ALIGNMENT, 1);
    glReadPixels(0, 0, m_textureWidth, m_textureHeight, GL_RGBA, GL_UNSIGNED_BYTE, buffer.data());
    glBindFramebuffer(GL_FRAMEBUFFER, 0);
    m_frameBuffer = buffer;
    if(m_needRecFrames && !snapshot && !m_snapShot)
		Q_EMIT newFrameAvailable(m_frameBuffer);
	if(snapshot && m_snapShot){
		m_snapShot = false;
		QImage image(m_frameBuffer.data(), m_textureWidth, m_textureHeight, QImage::Format_RGBA8888);
		if(isLandscape())
			if(m_needFlip)
				Q_EMIT snapshotTaken(image.mirrored(true, true).copy());
			else
				Q_EMIT snapshotTaken(image.mirrored(false, true).copy());
		else
			if(m_needFlip)
				Q_EMIT snapshotTaken(image.copy());
			else
				Q_EMIT snapshotTaken(image.mirrored(false, true).copy());
	}
}

void CameraRenderer::initRecordingGl()
{
    glGenTextures(1, &m_recordingTexture);
    glBindTexture(GL_TEXTURE_2D, m_recordingTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, m_textureWidth, m_textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    glGenFramebuffers(1, &m_fbo);
    glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_recordingTexture, 0);

    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
        qWarning() << "Recording FBO not complete";

    m_prgRecording = new QOpenGLShaderProgram(this);
    m_prgRecording->addShaderFromSourceFile(QOpenGLShader::Vertex, ":/shaders/recording.vert");
    m_prgRecording->addShaderFromSourceFile(QOpenGLShader::Fragment, ":/shaders/recording.frag");
    m_prgRecording->link();

    m_aPosition = m_prgRecording->attributeLocation("aPosition");
    m_aTexCoord = m_prgRecording->attributeLocation("aTexCoord");
    m_sTexture = m_prgRecording->uniformLocation("sTexture");
}

void CameraRenderer::startSwRecording(bool recording)
{
	m_needRecFrames = recording;
}

void CameraRenderer::resizeRecordingTexture()
{
	glBindFramebuffer(GL_FRAMEBUFFER, 0);
	glBindTexture(GL_TEXTURE_2D, m_recordingTexture);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, m_textureWidth, m_textureHeight, 0, GL_RGBA, GL_UNSIGNED_BYTE, nullptr);
	glBindFramebuffer(GL_FRAMEBUFFER, m_fbo);
	glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, m_recordingTexture, 0);

	m_resizeRecTexture = false;
}