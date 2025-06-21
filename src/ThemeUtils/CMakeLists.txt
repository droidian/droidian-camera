find_package(PkgConfig REQUIRED)
pkg_check_modules(GLIB2 REQUIRED glib-2.0 gio-2.0)

qt6_add_qml_module(ThemeUtils
    URI ThemeUtils
    VERSION 1.0
    SOURCES
        themeutils.cpp
        themeutils.h
        gnomeutils.cpp
        gnomeutils.h
)

target_include_directories(ThemeUtils PRIVATE ${GLIB2_INCLUDE_DIRS})
target_link_libraries(ThemeUtils PRIVATE Qt6::Gui ${GLIB2_LIBRARIES})

qt_query_qml_module(ThemeUtils
    URI module_uri
    VERSION module_version
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
    QML_FILES module_qml_files
    QML_FILES_DEPLOY_PATHS qml_files_deploy_paths
)

install(TARGETS ThemeUtils
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