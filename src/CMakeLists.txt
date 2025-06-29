cmake_minimum_required(VERSION 3.16)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

file(GLOB_RECURSE resources_SRC CONFIGURE_DEPENDS
     "qml/*.qml"
     "shaders/*.frag"
     "shaders/*.vert"
)

foreach(path IN LISTS resources_SRC)
	list(REMOVE_ITEM resources_SRC ${path})
	string(REPLACE ${CMAKE_CURRENT_SOURCE_DIR}/ "" path ${path})
	list(APPEND resources_SRC ${path})
endforeach()

add_subdirectory(ThemeUtils)
add_subdirectory(MediaScanner)

set(APP_SOURCES 
		main.cpp
		hybris-camera.cpp
		camera-renderer.cpp
		audiostream.cpp
		videoquality.cpp
		camera-manager.cpp
		camera-recorder.cpp)

set(APP_HEADERS
		hybris-camera.h
		camera-renderer.h
		audiostream.h
		videoquality.h
		camera-manager.h
		camera-recorder.h)

qt_add_executable(${PROJECT_NAME} ${APP_SOURCES} ${APP_HEADERS})

qt_add_qml_module(${PROJECT_NAME}
    URI HybrisCamera
    VERSION 1.0
    DEPENDENCIES QtQuick
)

qt_add_resources(${PROJECT_NAME} "resource"
	PREFIX /
	FILES
		${resources_SRC})