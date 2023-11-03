cmake_minimum_required(VERSION 3.16)
project (droidian-camera LANGUAGES CXX)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_AUTOUIC ON)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)

find_package(Qt5 REQUIRED COMPONENTS Core Widgets Quick Qml Multimedia)

execute_process(COMMAND pkg-config --cflags gstreamer-1.0 OUTPUT_VARIABLE GST_CFLAGS OUTPUT_STRIP_TRAILING_WHITESPACE)
execute_process(COMMAND pkg-config --libs gstreamer-1.0 OUTPUT_VARIABLE GST_LIBS OUTPUT_STRIP_TRAILING_WHITESPACE)

execute_process(COMMAND pkg-config --variable=libdir glib-2.0 OUTPUT_VARIABLE GLIB_LIBDIR OUTPUT_STRIP_TRAILING_WHITESPACE)

set(APP_SOURCES
		${CMAKE_SOURCE_DIR}/src/main.cpp
		${CMAKE_SOURCE_DIR}/src/thumbnailgenerator.cpp
		${CMAKE_SOURCE_DIR}/src/capturefilter.cpp
		${CMAKE_SOURCE_DIR}/src/gstdevicerange.cpp
		${CMAKE_SOURCE_DIR}/src/flashlightcontroller.cpp
		${CMAKE_SOURCE_DIR}/src/filemanager.cpp)

set(APP_HEADERS
		${CMAKE_SOURCE_DIR}/src/filemanager.h
		${CMAKE_SOURCE_DIR}/src/capturefilter.h
		${CMAKE_SOURCE_DIR}/src/gstdevicerange.h
		${CMAKE_SOURCE_DIR}/src/flashlightcontroller.h
		${CMAKE_SOURCE_DIR}/src/thumbnailgenerator.h)

qt5_add_resources(APP_RESOURCES
	${CMAKE_SOURCE_DIR}/sounds/sounds.qrc
	${CMAKE_SOURCE_DIR}/icons/icons.qrc
	${CMAKE_SOURCE_DIR}/src/qml/qml.qrc)


add_executable(${PROJECT_NAME} ${APP_SOURCES} ${APP_HEADERS} ${APP_RESOURCES})

target_include_directories(${PROJECT_NAME} PUBLIC
    /usr/include/gstreamer-1.0
    /usr/include/glib-2.0
    ${GLIB_LIBDIR}/glib-2.0/include
)

target_compile_options(${PROJECT_NAME} PUBLIC ${GST_CFLAGS})
target_link_libraries(${PROJECT_NAME} PUBLIC Qt5::Core Qt5::Widgets Qt5::Quick Qt5::Qml Qt5::Multimedia ${GST_LIBS})

install(TARGETS ${PROJECT_NAME} DESTINATION /usr/bin)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.desktop DESTINATION /usr/share/applications)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.svg DESTINATION /usr/share/icons)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.conf DESTINATION /etc)
