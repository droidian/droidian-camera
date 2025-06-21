cmake_minimum_required(VERSION 3.16)
project (droidian-camera LANGUAGES C CXX)

set(CMAKE_AUTOMOC ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

set(CMAKE_BUILD_WITH_INSTALL_RPATH FALSE)
set(CMAKE_INSTALL_RPATH "")
set(CMAKE_SKIP_RPATH TRUE)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick Multimedia Sensors Concurrent)

pkg_check_modules(android_headers REQUIRED android-headers)
pkg_check_modules(hybris_camera REQUIRED libcamera)
pkg_check_modules(hybris_media REQUIRED libmedia)

qt6_standard_project_setup()

add_subdirectory(src)

target_include_directories(${PROJECT_NAME} PUBLIC
	${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(droidian-camera PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Qml
    Qt6::Quick
    Qt6::Multimedia
    Qt6::Sensors
    ${android_headers_LIBRARIES}
    ${hybris_media_LIBRARIES}
    ${hybris_camera_LIBRARIES}
    ThemeUtils
)

install(TARGETS ${PROJECT_NAME} DESTINATION /usr/bin)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.desktop DESTINATION /usr/share/applications)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.svg DESTINATION /usr/share/icons)
