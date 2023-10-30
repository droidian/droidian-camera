// SPDX-License-Identifier: GPL-2.0-only
// Copyright (C) 2023 Droidian Project
//
// Authors:
// Bardia Moshiri <fakeshell@bardia.tech>
// Erik Inkinen <erik.inkinen@gmail.com>
// Alexander Rutz <alex@familyrutz.com>

#include "gstdevicerange.h"

std::pair<int, int> get_camera_device_range() {
  if (!gst_is_initialized()) {
    GError *err = nullptr;
    if (!gst_init_check(nullptr, nullptr, &err)) {
      throw std::runtime_error("Failed to initialize GStreamer: " + std::string(err->message));
    }
  }

  GstElement *element = gst_element_factory_make("droidcamsrc", "droidcamsrc_instance");

  if (!element) {
    throw std::runtime_error("Failed to create element of type 'droidcamsrc'");
  }

  GParamSpec *param_spec = g_object_class_find_property(G_OBJECT_GET_CLASS(element), "camera-device");

  if (!param_spec) {
    throw std::runtime_error("The 'camera-device' property was not found");
  }

  if (G_IS_PARAM_SPEC_INT(param_spec)) {
    GParamSpecInt *param_spec_int = G_PARAM_SPEC_INT(param_spec);
    int minimum = param_spec_int->minimum;
    int maximum = param_spec_int->maximum;
    gst_object_unref(element);
    return std::make_pair(minimum, maximum);
  } else {
    throw std::runtime_error("The 'camera-device' property is not of integer type");
  }
}

CameraDeviceRangeWrapper::CameraDeviceRangeWrapper(QObject *parent) : QObject(parent), m_min(0), m_max(0) {}

void CameraDeviceRangeWrapper::fetchCameraDeviceRange() {
    try {
        auto [min_val, max_val] = get_camera_device_range();
        if (min_val != m_min) {
            m_min = min_val;
            emit minChanged(m_min);
        }
        if (max_val != m_max) {
            m_max = max_val;
            emit maxChanged(m_max);
        }
    } catch (const std::exception& e) {
        std::cerr << "Exception caught: " << e.what() << std::endl;
        m_min = 0;
        m_max = 1;
    }
}
