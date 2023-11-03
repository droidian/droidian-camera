// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include "flashlightcontroller.h"
#include <QDebug>

FlashlightController::FlashlightController(QObject *parent) : QObject(parent)
{
    QStringList filePaths = {"/sys/class/leds/torch-light/brightness",
                            "/sys/class/leds/led:flash_torch/brightness",
                            "/sys/class/leds/flashlight/brightness",
                            "/sys/class/leds/torch-light0/brightness",
                            "/sys/class/leds/torch-light1/brightness",
                            "/sys/class/leds/led:torch_0/brightness",
                            "/sys/class/leds/led:torch_1/brightness",
                            "/sys/devices/platform/soc/soc:i2c@1/i2c-23/23-0059/s2mpb02-led/leds/torch-sec1/brightness",
                            "/sys/class/leds/led:switch/brightness",
                            "/sys/class/leds/led:switch_0/brightness"};

    for (const auto &path : filePaths) {
        QFile *file = new QFile(path);
        m_flashlightFiles.append(file);
    }
}

FlashlightController::~FlashlightController()
{
    qDeleteAll(m_flashlightFiles);
    m_flashlightFiles.clear();
}

void FlashlightController::turnFlashlightOn()
{
    for (auto *file : m_flashlightFiles) {
        writeFile(file, QStringLiteral("1"));
    }

    m_flashlightOn = true;
    emit flashlightOnChanged(m_flashlightOn);
}

void FlashlightController::turnFlashlightOff()
{
    for (auto *file : m_flashlightFiles) {
        writeFile(file, QStringLiteral("0"));
    }

    m_flashlightOn = false;
    emit flashlightOnChanged(m_flashlightOn);
}

bool FlashlightController::isFlashlightOn() const
{
    return m_flashlightOn;
}

void FlashlightController::writeFile(QFile *file, const QString &value)
{
    if (!file->open(QIODevice::WriteOnly | QIODevice::Text)) {
        return;
    }

    QTextStream out(file);
    out << value;
    file->close();
}
