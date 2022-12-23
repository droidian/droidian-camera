#include "capturefilter.h"
#include <QDir>
#include <QStandardPaths>
#include <QDateTime>

QVideoFrame MyFilterRunnable::run(QVideoFrame *input, const QVideoSurfaceFormat &surfaceFormat, RunFlags flags) { 
    Q_UNUSED(surfaceFormat);
    Q_UNUSED(flags);
    if (*m_capture) {
        QDir photoDir(QStandardPaths::writableLocation(QStandardPaths::PicturesLocation));
        input->image().save(photoDir.filePath("photo-" + QDateTime::currentDateTime().toString("ddMMyyyy-hhmmss") + ".jpg"));
        *m_capture = false;
    }
    return *input;
}

CaptureFilter::CaptureFilter() : m_capture(false) {}

QVideoFilterRunnable *CaptureFilter::createFilterRunnable() { 
    return new MyFilterRunnable(&m_capture); 
}

void CaptureFilter::capture() {
    m_capture = true;
}