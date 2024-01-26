cmake_minimum_required(VERSION 3.16)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

file(GLOB_RECURSE resources_SRC CONFIGURE_DEPENDS
     "qml/*.qml"
     "icons/*.svg"
     "sounds/*.wav"
)

foreach(path IN LISTS resources_SRC)
	list(REMOVE_ITEM resources_SRC ${path})
	string(REPLACE ${CMAKE_CURRENT_SOURCE_DIR}/ "" path ${path})
	list(APPEND resources_SRC ${path})
endforeach()

set(APP_SOURCES 
		main.cpp
		droidian-camera.cpp
		dc-device.cpp)

set(APP_HEADERS
		droidian-camera.h
		dc-device.h)

qt_add_executable(${PROJECT_NAME} ${APP_SOURCES} ${APP_HEADERS})

qt_add_qml_module(${PROJECT_NAME}
    URI DroidianCamera
    VERSION 1.0
    DEPENDENCIES QtQuick
)

qt_add_resources(${PROJECT_NAME} "resource"
	PREFIX /
	FILES
		${resources_SRC})
