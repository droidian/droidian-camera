// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#pragma once

#include <QObject>
#include <gst/gst.h>
#include <utility>
#include <stdexcept>
#include <iostream>

std::pair<int, int> get_camera_device_range();

class CameraDeviceRangeWrapper : public QObject
{
    Q_OBJECT
public:
    explicit CameraDeviceRangeWrapper(QObject *parent = nullptr);

    Q_INVOKABLE void fetchCameraDeviceRange();
    Q_PROPERTY(int min READ min NOTIFY minChanged)
    Q_PROPERTY(int max READ max NOTIFY maxChanged)

signals:
    void minChanged(int min);
    void maxChanged(int max);

public slots:

private:
    int m_min;
    int m_max;

    int min() const { return m_min; }
    int max() const { return m_max; }
};
