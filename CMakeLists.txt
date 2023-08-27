cmake_minimum_required(VERSION 3.16)
project (droidian-camera LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt5 REQUIRED COMPONENTS Core Widgets Quick Qml)

set(APP_SOURCES
		${CMAKE_SOURCE_DIR}/src/main.cpp
		${CMAKE_SOURCE_DIR}/src/filemanager.cpp)

set(APP_HEADERS
		${CMAKE_SOURCE_DIR}/src/filemanager.h)

qt5_add_resources(APP_RESOURCES
	${CMAKE_SOURCE_DIR}/sounds/sounds.qrc
	${CMAKE_SOURCE_DIR}/icons/icons.qrc
	${CMAKE_SOURCE_DIR}/src/qml/qml.qrc)


add_executable(${PROJECT_NAME} ${APP_SOURCES} ${APP_HEADERS} ${APP_RESOURCES})

target_include_directories(${PROJECT_NAME} PUBLIC
	${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(${PROJECT_NAME} PUBLIC Qt5::Core Qt5::Widgets Qt5::Quick Qt5::Qml)

install(TARGETS ${PROJECT_NAME} DESTINATION /usr/bin)
install(FILES droidian-camera.desktop DESTINATION usr/share/applications/droidian-camera.desktop)
install(FILES droidian-camera.svg DESTINATION usr/share/icons/droidian-camera.svg)
install(FILES droidian-camera.conf DESTINATION etc/droidian-camera.conf)
