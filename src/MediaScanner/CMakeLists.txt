find_package(Qt6 REQUIRED COMPONENTS Core Gui Qml Quick)

qt_add_qml_module(MediaScanner
    URI MediaScanner
    VERSION 1.0
    SOURCES
        media-scanner.h
        media-scanner.cpp
)

target_link_libraries(
    MediaScanner PRIVATE
    Qt6::Gui
    ${AVCODEC_LIBRARY}
    ${AVFORMAT_LIBRARY}
    ${AVUTIL_LIBRARY}
    ${SWSCALE_LIBRARY})

qt_query_qml_module(MediaScanner
    URI module_uri
    VERSION module_version
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
    QML_FILES module_qml_files
    QML_FILES_DEPLOY_PATHS qml_files_deploy_paths
)

install(TARGETS MediaScanner
    ARCHIVE DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
)

install(TARGETS ${module_plugin_target}
    LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/qt6/qml/${module_target_path}"
    RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}/qt6/qml/${module_target_path}"
)

install(FILES ${module_qmldir} DESTINATION "${CMAKE_INSTALL_LIBDIR}/qt6/qml/${module_target_path}")
install(FILES ${module_typeinfo} DESTINATION "${CMAKE_INSTALL_LIBDIR}/qt6/qml/${module_target_path}")