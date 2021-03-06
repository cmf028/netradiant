include(FindPkgConfig OPTIONAL)
if (PKG_CONFIG_FOUND)
    include(FindPkgConfig)
    pkg_check_modules(GTK gtk+-2.0)
    if (XWINDOWS)
        pkg_check_modules(GTKGL gtkglext-x11-1.0)
    elseif (WIN32)
        pkg_check_modules(GTKGL gtkglext-win32-1.0)
    else ()
        pkg_check_modules(GTKGL gtkglext-quartz-1.0)
    endif ()
endif ()
