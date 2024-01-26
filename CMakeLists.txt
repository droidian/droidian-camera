cmake_minimum_required(VERSION 3.16)
project (droidian-camera LANGUAGES C CXX)

set(CMAKE_AUTOMOC ON)

set(CMAKE_INCLUDE_CURRENT_DIR ON)

find_package(Qt6 REQUIRED COMPONENTS Core Gui Quick Qml Multimedia)

qt_standard_project_setup()

add_subdirectory(src)

target_include_directories(${PROJECT_NAME} PUBLIC
	${CMAKE_CURRENT_SOURCE_DIR}/src)

target_link_libraries(${PROJECT_NAME} PUBLIC Qt6::Core Qt6::Gui Qt6::Quick Qt6::Qml Qt6::Multimedia droidmedia)

install(TARGETS ${PROJECT_NAME} DESTINATION /usr/bin)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.desktop DESTINATION /usr/share/applications)
install(FILES ${CMAKE_SOURCE_DIR}/camera-app.svg DESTINATION /usr/share/icons)
install(FILES ${CMAKE_SOURCE_DIR}/droidian-camera.conf DESTINATION /etc)