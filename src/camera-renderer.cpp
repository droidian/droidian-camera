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

	rotateTextureCoords(vVertices, m_effectiveRotation);

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
}

void CameraRenderer::rotateTextureCoords(GLfloat *vVertices, int orientation)
{
	GLfloat texCoords[4][2] = {
		{ 0.0f, 0.0f }, { 0.0f, 1.0f }, { 1.0f, 1.0f }, { 1.0f, 0.0f }
	};

	GLfloat rotated[4][2];

	switch (orientation) {
	case 0:
		for (int i = 0; i < 4; ++i)
			rotated[i][0] = texCoords[i][0],
			rotated[i][1] = texCoords[i][1];
		break;
	case 90:
		rotated[0][0] = texCoords[3][0];
		rotated[0][1] = texCoords[3][1];
		rotated[1][0] = texCoords[0][0];
		rotated[1][1] = texCoords[0][1];
		rotated[2][0] = texCoords[1][0];
		rotated[2][1] = texCoords[1][1];
		rotated[3][0] = texCoords[2][0];
		rotated[3][1] = texCoords[2][1];
		break;
	case 180:
		rotated[0][0] = texCoords[2][0];
		rotated[0][1] = texCoords[2][1];
		rotated[1][0] = texCoords[3][0];
		rotated[1][1] = texCoords[3][1];
		rotated[2][0] = texCoords[0][0];
		rotated[2][1] = texCoords[0][1];
		rotated[3][0] = texCoords[1][0];
		rotated[3][1] = texCoords[1][1];
		break;
	case 270:
		rotated[0][0] = texCoords[1][0];
		rotated[0][1] = texCoords[1][1];
		rotated[1][0] = texCoords[2][0];
		rotated[1][1] = texCoords[2][1];
		rotated[2][0] = texCoords[3][0];
		rotated[2][1] = texCoords[3][1];
		rotated[3][0] = texCoords[0][0];
		rotated[3][1] = texCoords[0][1];
		break;
	}

	for (int i = 0; i < 4; ++i) {
		vVertices[i * 5 + 3] = rotated[i][0];
		vVertices[i * 5 + 4] = rotated[i][1];
	}
}