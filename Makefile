-include Makefile.conf

## CONFIGURATION SETTINGS
# user customizable stuf
# you may override this in Makefile.conf or the environment
BUILD              ?= debug
# or: release
OS                 ?= $(shell uname)
# or: Linux, Win32, Darwin
LDFLAGS            ?=
CFLAGS             ?=
CXXFLAGS           ?=
CPPFLAGS           ?=
LIBS               ?=
RADIANT_ABOUTMSG   ?= Custom build

CC                 ?= gcc
CXX                ?= g++
RANLIB             ?= ranlib
AR                 ?= ar
LDD                ?= ldd # nothing on Win32
WINDRES            ?= # only used on Win32

PKGCONFIG          ?= pkg-config
PKG_CONFIG_PATH    ?=

SH                 ?= $(SHELL)
ECHO               ?= echo
ECHO_NOLF          ?= echo -n
CAT                ?= cat
MKDIR              ?= mkdir -p
CP                 ?= cp
CP_R               ?= $(CP) -r
RM                 ?= rm
RM_R               ?= $(RM) -r
TEE_STDERR         ?= | tee /dev/stderr
TR                 ?= tr
FIND               ?= find
DIFF               ?= diff

# optional:
SVNVERSION         ?= svnversion

STDOUT_TO_DEVNULL  ?= >/dev/null
STDERR_TO_DEVNULL  ?= 2>/dev/null
STDERR_TO_STDOUT   ?= 2>&1
TO_DEVNULL         ?= $(STDOUT_TO_DEVNULL) $(STDERR_TO_STDOUT)

CPPFLAGS_GLIB      ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) glib-2.0 --cflags $(STDERR_TO_DEVNULL))
LIBS_GLIB          ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) glib-2.0 --libs-only-L $(STDERR_TO_DEVNULL)) \
                      $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) glib-2.0 --libs-only-l $(STDERR_TO_DEVNULL))
CPPFLAGS_XML       ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) libxml-2.0 --cflags $(STDERR_TO_DEVNULL))
LIBS_XML           ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) libxml-2.0 --libs-only-L $(STDERR_TO_DEVNULL)) \
                      $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) libxml-2.0 --libs-only-l $(STDERR_TO_DEVNULL))
CPPFLAGS_PNG       ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) libpng --cflags $(STDERR_TO_DEVNULL))
LIBS_PNG           ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) libpng --libs-only-L $(STDERR_TO_DEVNULL)) \
                      $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) libpng --libs-only-l $(STDERR_TO_DEVNULL))
CPPFLAGS_GTK       ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtk+-2.0 --cflags $(STDERR_TO_DEVNULL))
LIBS_GTK           ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtk+-2.0 --libs-only-L $(STDERR_TO_DEVNULL)) \
                      $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtk+-2.0 --libs-only-l $(STDERR_TO_DEVNULL))
CPPFLAGS_GTKGLEXT  ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtkglext-1.0 --cflags $(STDERR_TO_DEVNULL))
LIBS_GTKGLEXT      ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtkglext-1.0 --libs-only-L $(STDERR_TO_DEVNULL)) \
                      $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtkglext-1.0 --libs-only-l $(STDERR_TO_DEVNULL))
CPPFLAGS_GL        ?=
LIBS_GL            ?= -lGL # -lopengl32 on Win32
CPPFLAGS_DL        ?=
LIBS_DL            ?= -ldl # nothing on Win32
CPPFLAGS_ZLIB      ?=
LIBS_ZLIB          ?= -lz
DEPEND_ON_MAKEFILE ?= yes
DEPENDENCIES_CHECK ?= quiet
# or: off, verbose

# these are used on Win32 only
GTKDIR             ?= $(shell PKG_CONFIG_PATH=$(PKG_CONFIG_PATH) $(PKGCONFIG) gtk+-2.0 --variable=prefix $(STDERR_TO_DEVNULL))
WHICHDLL           ?= which

# alias mingw32 OSes
ifeq ($(OS),MINGW32_NT-6.0)
	OS = Win32
endif

CFLAGS_COMMON = -MMD -W -Wall -Wcast-align -Wcast-qual -Wno-unused-parameter
CPPFLAGS_COMMON =
LDFLAGS_COMMON =
LIBS_COMMON =
CXXFLAGS_COMMON = -Wno-non-virtual-dtor -Wreorder -fno-exceptions -fno-rtti

ifeq ($(BUILD),debug)
ifeq ($(findstring $(CFLAGS),-g),)
	CFLAGS_COMMON += -g
	# only add -g if no -g flag is in $(CFLAGS)
endif
ifeq ($(findstring $(CFLAGS),-O),)
	CFLAGS_COMMON += -O
	# only add -O if no -O flag is in $(CFLAGS)
endif
	CPPFLAGS_COMMON +=
	LDFLAGS_COMMON +=
else ifeq ($(BUILD),extradebug)
ifeq ($(findstring $(CFLAGS),-g),)
	CFLAGS_COMMON += -g3
	# only add -g3 if no -g flag is in $(CFLAGS)
endif
	CPPFLAGS_COMMON += -D_DEBUG
	LDFLAGS_COMMON +=
else ifeq ($(BUILD),release)
ifeq ($(findstring $(CFLAGS),-O),)
	CFLAGS_COMMON += -O3
	# only add -O3 if no -O flag is in $(CFLAGS)
	# to allow overriding the optimizations
endif
	CPPFLAGS_COMMON +=
	LDFLAGS_COMMON += -s
else
$(error Unsupported build type: $(BUILD))
endif

ifeq ($(OS),Linux)
	CPPFLAGS_COMMON += -DPOSIX -DXWINDOWS -D_LINUX
	CFLAGS_COMMON += -fPIC
	LDFLAGS_DLL = -fPIC -ldl
	LIBS_COMMON = -lpthread
	EXE = x86
	A = a
	DLL = so
	MWINDOWS =
else ifeq ($(OS),Win32)
	CPPFLAGS_COMMON += -DWIN32 -D_WIN32 -D_inline=inline
	CFLAGS_COMMON += -mms-bitfields
	LDFLAGS_DLL = --dll -Wl,--add-stdcall-alias
	LIBS_COMMON = -lws2_32 -luser32 -lgdi32
	EXE = exe
	A = a
	DLL = dll
	MWINDOWS = -mwindows

	# workaround: we have no "ldd" for Win32, so...
	LDD =
	# workaround: OpenGL library for Win32 is called opengl32.dll
	LIBS_GL = -lopengl32
	# workaround: no -ldl on Win32
	LIBS_DL = 
#else ifeq ($(OS),Darwin)
#	EXE = ppc
else
$(error Unsupported build OS: $(OS))
endif

# VERSION!
RADIANT_VERSION = 1.5.0
RADIANT_MAJOR_VERSION = 5
RADIANT_MINOR_VERSION = 0

SVN_VERSION := $(shell $(SVNVERSION) -n $(STDERR_TO_DEVNULL) | $(TR) -cd 0-9:)
ifneq ($(SVN_VERSION),)
	RADIANT_VERSION := $(RADIANT_VERSION)-svn$(SVN_VERSION)
endif

CPPFLAGS += -DRADIANT_VERSION="\"$(RADIANT_VERSION)\"" -DRADIANT_MAJOR_VERSION="\"$(RADIANT_MAJOR_VERSION)\"" -DRADIANT_MINOR_VERSION="\"$(RADIANT_MINOR_VERSION)\"" -DRADIANT_ABOUTMSG="\"$(RADIANT_ABOUTMSG)\""

.PHONY: all
all: \
	dependencies-check \
	binaries \
	install-data \
	install-dll \

.PHONY: dependencies-check
ifeq ($(findstring $(DEPENDENCIES_CHECK),off),off)
dependencies-check:
	@$(ECHO) dependencies checking disabled, good luck...
else
dependencies-check:
	@$(ECHO)
	@if [ x"$(DEPENDENCIES_CHECK)" = x"verbose" ]; then set -x; fi; \
	checkbinary() \
	{ \
		$(ECHO_NOLF) "Checking for $$2 ($$1)... "; \
		$$2 --help $(TO_DEVNULL); \
		if [ $$? != 127 ]; then \
			$(ECHO) "found."; \
		else \
			$(ECHO) "not found, please install it or set PATH right!"; \
			$(ECHO) "To see the failed commands, set DEPENDENCIES_CHECK=verbose"; \
			$(ECHO) "To proceed anyway, set DEPENDENCIES_CHECK=off"; \
			exit 1; \
		fi; \
	}; \
	$(ECHO) checking that the build tools exist; \
	checkbinary "bash (or another shell)" "$(SH)"; \
	checkbinary coreutils "$(ECHO)"; \
	checkbinary coreutils "$(ECHO_NOLF)"; \
	checkbinary coreutils "$(CAT)"; \
	checkbinary coreutils "$(MKDIR)"; \
	checkbinary coreutils "$(CP)"; \
	checkbinary coreutils "$(CP_R)"; \
	checkbinary coreutils "$(RM)"; \
	checkbinary coreutils "$(RM_R)"; \
	checkbinary coreutils "$(ECHO) test $(TEE_STDERR)"; \
	checkbinary coreutils "$(TR)"; \
	checkbinary findutils "$(FIND)"; \
	checkbinary diff "$(DIFF)"; \
	checkbinary gcc "$(CC)"; \
	checkbinary g++ "$(CXX)"; \
	checkbinary binutils "$(RANLIB)"; \
	checkbinary binutils "$(AR)"; \
	[ "$(OS)" = "Win32" ] && checkbinary mingw32 "$(WINDRES)"; \
	[ "$(OS)" != "Win32" ] && checkbinary libc6 "$(LDD)"; \
	$(ECHO) All required tools have been found!
	@$(ECHO)
	@if [ x"$(DEPENDENCIES_CHECK)" = x"verbose" ]; then set -x; fi; \
	checkheader() \
	{ \
		$(ECHO_NOLF) "Checking for $$2 ($$1)... "; \
		if \
			$(CXX) conftest.cpp $(CFLAGS) $(CXXFLAGS) $(CFLAGS_COMMON) $(CXXFLAGS_COMMON) $(CPPFLAGS) $(CPPFLAGS_COMMON) $$4 -DCONFTEST_HEADER="<$$2>" -DCONFTEST_SYMBOL="$$3" $(TARGET_ARCH) $(LDFLAGS) -c -o conftest.o $(TO_DEVNULL) && \
			$(CXX) conftest.o $(LDFLAGS) $(LDFLAGS_COMMON) $$5 $(LIBS_COMMON) $(LIBS) -o conftest $(TO_DEVNULL); \
		then \
			$(RM) conftest conftest.o conftest.d; \
			$(ECHO) "found."; \
		else \
			$(RM) conftest conftest.o conftest.d; \
			$(ECHO) "not found, please install it or set PKG_CONFIG_PATH right!"; \
			$(ECHO) "To see the failed commands, set DEPENDENCIES_CHECK=verbose"; \
			$(ECHO) "To proceed anyway, set DEPENDENCIES_CHECK=off"; \
			exit 1; \
		fi; \
	}; \
	$(ECHO) checking that the dependencies exist; \
	checkheader libglib2.0-dev glib/gutils.h g_path_is_absolute "$(CPPFLAGS_GLIB)" "$(LIBS_GLIB)"; \
	checkheader libxml2-dev libxml/xpath.h xmlXPathInit "$(CPPFLAGS_XML)" "$(LIBS_XML)"; \
	checkheader libpng12-dev png.h png_create_read_struct "$(CPPFLAGS_PNG)" "$(LIBS_PNG)"; \
	checkheader "mesa-common-dev (or another OpenGL library)" GL/gl.h glClear "$(CPPFLAGS_GL)" "$(LIBS_GL)"; \
	checkheader libgtk2.0-dev gtk/gtkdialog.h gtk_dialog_run "$(CPPFLAGS_GTK)" "$(LIBS_GTK)"; \
	checkheader libgtkglext1-dev gtk/gtkglwidget.h gtk_widget_get_gl_context "$(CPPFLAGS_GTKGLEXT)" "$(LIBS_GTKGLEXT)"; \
	[ "$(OS)" != "Win32" ] && checkheader libc6-dev dlfcn.h dlopen "$(CPPFLAGS_DL)" "$(LIBS_DL)"; \
	checkheader zlib1g-dev zlib.h zlibVersion "$(CPPFLAGS_ZLIB)" "$(LIBS_ZLIB)"; \
	$(ECHO) All required libraries have been found!
	@$(ECHO)
endif

.PHONY: binaries
binaries: \
	install/heretic2/h2data.$(EXE) \
	install/modules/archivepak.$(DLL) \
	install/modules/archivewad.$(DLL) \
	install/modules/archivezip.$(DLL) \
	install/modules/entity.$(DLL) \
	install/modules/image.$(DLL) \
	install/modules/imagehl.$(DLL) \
	install/modules/imagepng.$(DLL) \
	install/modules/imageq2.$(DLL) \
	install/modules/mapq3.$(DLL) \
	install/modules/mapxml.$(DLL) \
	install/modules/md3model.$(DLL) \
	install/modules/model.$(DLL) \
	install/modules/shaders.$(DLL) \
	install/modules/vfspk3.$(DLL) \
	install/plugins/bobtoolz.$(DLL) \
	install/plugins/brushexport.$(DLL) \
	install/plugins/prtview.$(DLL) \
	install/plugins/shaderplug.$(DLL) \
	install/plugins/sunplug.$(DLL) \
	install/plugins/ufoaiplug.$(DLL) \
	install/q2map.$(EXE) \
	install/q3data.$(EXE) \
	install/q3map2.$(EXE) \
	install/qdata3.$(EXE) \
	install/radiant.$(EXE) \

.PHONY: clean
clean:
	$(RM_R) install/
	$(FIND) . \( -name \*.o -o -name \*.d -o -name \*.$(DLL) -o -name \*.$(A) -o -name \*.$(EXE) \) -exec $(RM) {} \;

%.$(EXE):
	file=$@; $(MKDIR) $${file%/*}
	$(CXX) $^ $(LDFLAGS) $(LDFLAGS_COMMON) $(LDFLAGS_EXTRA) $(LIBS_EXTRA) $(LIBS_COMMON) $(LIBS) -o $@
	[ -z "$(LDD)" ] || [ -z "`$(LDD) -r $@ $(STDERR_TO_STDOUT) $(STDOUT_TO_DEVNULL) $(TEE_STDERR)`" ] || { $(RM) $@; exit 1; }

%.$(A):
	$(AR) rc $@ $^
	$(RANLIB) $@

%.$(DLL):
	file=$@; $(MKDIR) $${file%/*}
	$(CXX) $^ $(LDFLAGS) $(LDFLAGS_COMMON) $(LDFLAGS_EXTRA) $(LDFLAGS_DLL) $(LIBS_EXTRA) $(LIBS_COMMON) $(LIBS) -shared -o $@
	[ -z "$(LDD)" ] || [ -z "`$(LDD) -r $@ $(STDERR_TO_STDOUT) $(STDOUT_TO_DEVNULL) $(TEE_STDERR)`" ] || { $(RM) $@; exit 1; }

%.rc: %.ico
	$(ECHO) '1 ICON "$<"' > $@

ifeq ($(OS),Win32)
%.o: %.rc
	$(WINDRES) $< $@
endif

%.o: %.cpp $(if $(findstring $(DEPEND_ON_MAKEFILE),yes),$(wildcard Makefile*),)
	$(CXX) $< $(CFLAGS) $(CXXFLAGS) $(CFLAGS_COMMON) $(CXXFLAGS_COMMON) $(CPPFLAGS) $(CPPFLAGS_COMMON) $(CPPFLAGS_EXTRA) $(TARGET_ARCH) -c -o $@

%.o: %.c $(if $(findstring $(DEPEND_ON_MAKEFILE),yes),$(wildcard Makefile*),)
	$(CC) $< $(CFLAGS) $(CFLAGS_COMMON) $(CPPFLAGS) $(CPPFLAGS_COMMON) $(CPPFLAGS_EXTRA) $(TARGET_ARCH) -c -o $@

install/q3map2.$(EXE): LIBS_EXTRA := $(LIBS_XML) $(LIBS_GLIB) $(LIBS_PNG)
install/q3map2.$(EXE): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) $(CPPFLAGS_GLIB) $(CPPFLAGS_PNG) -Itools/quake3/common -Ilibs -Iinclude
install/q3map2.$(EXE): \
	tools/quake3/common/cmdlib.o \
	tools/quake3/common/imagelib.o \
	tools/quake3/common/inout.o \
	tools/quake3/common/md4.o \
	tools/quake3/common/mutex.o \
	tools/quake3/common/polylib.o \
	tools/quake3/common/scriplib.o \
	tools/quake3/common/threads.o \
	tools/quake3/common/unzip.o \
	tools/quake3/common/vfs.o \
	tools/quake3/q3map2/brush.o \
	tools/quake3/q3map2/brush_primit.o \
	tools/quake3/q3map2/bspfile_abstract.o \
	tools/quake3/q3map2/bspfile_ibsp.o \
	tools/quake3/q3map2/bspfile_rbsp.o \
	tools/quake3/q3map2/bsp.o \
	tools/quake3/q3map2/convert_ase.o \
	tools/quake3/q3map2/convert_map.o \
	tools/quake3/q3map2/decals.o \
	tools/quake3/q3map2/facebsp.o \
	tools/quake3/q3map2/fog.o \
	tools/quake3/q3map2/image.o \
	tools/quake3/q3map2/leakfile.o \
	tools/quake3/q3map2/light_bounce.o \
	tools/quake3/q3map2/lightmaps_ydnar.o \
	tools/quake3/q3map2/light.o \
	tools/quake3/q3map2/light_trace.o \
	tools/quake3/q3map2/light_ydnar.o \
	tools/quake3/q3map2/main.o \
	tools/quake3/q3map2/map.o \
	tools/quake3/q3map2/mesh.o \
	tools/quake3/q3map2/model.o \
	tools/quake3/q3map2/patch.o \
	tools/quake3/q3map2/path_init.o \
	tools/quake3/q3map2/portals.o \
	tools/quake3/q3map2/prtfile.o \
	tools/quake3/q3map2/shaders.o \
	tools/quake3/q3map2/surface_extra.o \
	tools/quake3/q3map2/surface_foliage.o \
	tools/quake3/q3map2/surface_fur.o \
	tools/quake3/q3map2/surface_meta.o \
	tools/quake3/q3map2/surface.o \
	tools/quake3/q3map2/tjunction.o \
	tools/quake3/q3map2/tree.o \
	tools/quake3/q3map2/visflow.o \
	tools/quake3/q3map2/vis.o \
	tools/quake3/q3map2/writebsp.o \
	libddslib.$(A) \
	libjpeg6.$(A) \
	libl_net.$(A) \
	libmathlib.$(A) \
	libpicomodel.$(A) \
	$(if $(findstring $(OS),Win32),icons/q3map2.o,) \

libmathlib.$(A): CPPFLAGS_EXTRA := -Ilibs
libmathlib.$(A): \
	libs/mathlib/bbox.o \
	libs/mathlib/line.o \
	libs/mathlib/m4x4.o \
	libs/mathlib/mathlib.o \
	libs/mathlib/ray.o \

libl_net.$(A): CPPFLAGS_EXTRA := -Ilibs
libl_net.$(A): \
	libs/l_net/l_net.o \
	$(if $(findstring $(OS),Win32),libs/l_net/l_net_wins.o,libs/l_net/l_net_berkley.o) \

libjpeg6.$(A): CPPFLAGS_EXTRA := -Ilibs/jpeg6 -Ilibs
libjpeg6.$(A): \
	libs/jpeg6/jcomapi.o \
	libs/jpeg6/jdapimin.o \
	libs/jpeg6/jdapistd.o \
	libs/jpeg6/jdatasrc.o \
	libs/jpeg6/jdcoefct.o \
	libs/jpeg6/jdcolor.o \
	libs/jpeg6/jddctmgr.o \
	libs/jpeg6/jdhuff.o \
	libs/jpeg6/jdinput.o \
	libs/jpeg6/jdmainct.o \
	libs/jpeg6/jdmarker.o \
	libs/jpeg6/jdmaster.o \
	libs/jpeg6/jdpostct.o \
	libs/jpeg6/jdsample.o \
	libs/jpeg6/jdtrans.o \
	libs/jpeg6/jerror.o \
	libs/jpeg6/jfdctflt.o \
	libs/jpeg6/jidctflt.o \
	libs/jpeg6/jmemmgr.o \
	libs/jpeg6/jmemnobs.o \
	libs/jpeg6/jpgload.o \
	libs/jpeg6/jutils.o \

libpicomodel.$(A): CPPFLAGS_EXTRA := -Ilibs
libpicomodel.$(A): \
	libs/picomodel/lwo/clip.o \
	libs/picomodel/lwo/envelope.o \
	libs/picomodel/lwo/list.o \
	libs/picomodel/lwo/lwio.o \
	libs/picomodel/lwo/lwo2.o \
	libs/picomodel/lwo/lwob.o \
	libs/picomodel/lwo/pntspols.o \
	libs/picomodel/lwo/surface.o \
	libs/picomodel/lwo/vecmath.o \
	libs/picomodel/lwo/vmap.o \
	libs/picomodel/picointernal.o \
	libs/picomodel/picomodel.o \
	libs/picomodel/picomodules.o \
	libs/picomodel/pm_3ds.o \
	libs/picomodel/pm_ase.o \
	libs/picomodel/pm_fm.o \
	libs/picomodel/pm_lwo.o \
	libs/picomodel/pm_md2.o \
	libs/picomodel/pm_md3.o \
	libs/picomodel/pm_mdc.o \
	libs/picomodel/pm_ms3d.o \
	libs/picomodel/pm_obj.o \
	libs/picomodel/pm_terrain.o \

libddslib.$(A): CPPFLAGS_EXTRA := -Ilibs
libddslib.$(A): \
	libs/ddslib/ddslib.o \

install/q3data.$(EXE): LIBS_EXTRA := $(LIBS_XML) $(LIBS_GLIB)
install/q3data.$(EXE): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) $(CPPFLAGS_GLIB) -Itools/quake3/common -Ilibs -Iinclude
install/q3data.$(EXE): \
	tools/quake3/common/aselib.o \
	tools/quake3/common/bspfile.o \
	tools/quake3/common/cmdlib.o \
	tools/quake3/common/imagelib.o \
	tools/quake3/common/inout.o \
	tools/quake3/common/md4.o \
	tools/quake3/common/scriplib.o \
	tools/quake3/common/trilib.o \
	tools/quake3/common/unzip.o \
	tools/quake3/common/vfs.o \
	tools/quake3/q3data/3dslib.o \
	tools/quake3/q3data/compress.o \
	tools/quake3/q3data/images.o \
	tools/quake3/q3data/md3lib.o \
	tools/quake3/q3data/models.o \
	tools/quake3/q3data/p3dlib.o \
	tools/quake3/q3data/polyset.o \
	tools/quake3/q3data/q3data.o \
	tools/quake3/q3data/stripper.o \
	tools/quake3/q3data/video.o \
	libl_net.$(A) \
	libmathlib.$(A) \
	$(if $(findstring $(OS),Win32),icons/q3data.o,) \

install/radiant.$(EXE): LDFLAGS_EXTRA := $(MWINDOWS)
install/radiant.$(EXE): LIBS_EXTRA := $(LIBS_GL) $(LIBS_DL) $(LIBS_XML) $(LIBS_GLIB) $(LIBS_GTK) $(LIBS_GTKGLEXT)
install/radiant.$(EXE): CPPFLAGS_EXTRA := $(CPPFLAGS_GL) $(CPPFLAGS_DL) $(CPPFLAGS_XML) $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) $(CPPFLAGS_GTKGLEXT) -Ilibs -Iinclude
install/radiant.$(EXE): \
	radiant/autosave.o \
	radiant/brushmanip.o \
	radiant/brushmodule.o \
	radiant/brushnode.o \
	radiant/brush.o \
	radiant/brush_primit.o \
	radiant/brushtokens.o \
	radiant/brushxml.o \
	radiant/build.o \
	radiant/camwindow.o \
	radiant/clippertool.o \
	radiant/commands.o \
	radiant/console.o \
	radiant/csg.o \
	radiant/dialog.o \
	radiant/eclass_def.o \
	radiant/eclass_doom3.o \
	radiant/eclass_fgd.o \
	radiant/eclass.o \
	radiant/eclass_xml.o \
	radiant/entityinspector.o \
	radiant/entitylist.o \
	radiant/entity.o \
	radiant/environment.o \
	radiant/error.o \
	radiant/feedback.o \
	radiant/filetypes.o \
	radiant/filters.o \
	radiant/findtexturedialog.o \
	radiant/glwidget.o \
	radiant/grid.o \
	radiant/groupdialog.o \
	radiant/gtkdlgs.o \
	radiant/gtkmisc.o \
	radiant/help.o \
	radiant/image.o \
	radiant/mainframe.o \
	radiant/main.o \
	radiant/map.o \
	$(if $(findstring $(OS),Win32),radiant/multimon.o,) \
	radiant/mru.o \
	radiant/nullmodel.o \
	radiant/parse.o \
	radiant/patchdialog.o \
	radiant/patchmanip.o \
	radiant/patchmodule.o \
	radiant/patch.o \
	radiant/pluginapi.o \
	radiant/pluginmanager.o \
	radiant/pluginmenu.o \
	radiant/plugin.o \
	radiant/plugintoolbar.o \
	radiant/points.o \
	radiant/preferencedictionary.o \
	radiant/preferences.o \
	radiant/qe3.o \
	radiant/qgl.o \
	radiant/referencecache.o \
	radiant/renderer.o \
	radiant/renderstate.o \
	radiant/scenegraph.o \
	radiant/selection.o \
	radiant/select.o \
	radiant/server.o \
	radiant/shaders.o \
	radiant/sockets.o \
	radiant/stacktrace.o \
	radiant/surfacedialog.o \
	radiant/texmanip.o \
	radiant/textures.o \
	radiant/texwindow.o \
	radiant/timer.o \
	radiant/treemodel.o \
	radiant/undo.o \
	radiant/url.o \
	radiant/view.o \
	radiant/watchbsp.o \
	radiant/winding.o \
	radiant/windowobservers.o \
	radiant/xmlstuff.o \
	radiant/xywindow.o \
	libcmdlib.$(A) \
	libgtkutil.$(A) \
	libl_net.$(A) \
	libmathlib.$(A) \
	libprofile.$(A) \
	libxmllib.$(A) \
	$(if $(findstring $(OS),Win32),icons/radiant.o,) \

libcmdlib.$(A): CPPFLAGS_EXTRA := -Ilibs
libcmdlib.$(A): \
	libs/cmdlib/cmdlib.o \

libprofile.$(A): CPPFLAGS_EXTRA := -Ilibs -Iinclude
libprofile.$(A): \
	libs/profile/file.o \
	libs/profile/profile.o \

libgtkutil.$(A): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) $(CPPFLAGS_GTKGLEXT) -Ilibs -Iinclude
libgtkutil.$(A): \
	libs/gtkutil/accelerator.o \
	libs/gtkutil/button.o \
	libs/gtkutil/clipboard.o \
	libs/gtkutil/closure.o \
	libs/gtkutil/container.o \
	libs/gtkutil/cursor.o \
	libs/gtkutil/dialog.o \
	libs/gtkutil/entry.o \
	libs/gtkutil/filechooser.o \
	libs/gtkutil/frame.o \
	libs/gtkutil/glfont.o \
	libs/gtkutil/glwidget.o \
	libs/gtkutil/idledraw.o \
	libs/gtkutil/image.o \
	libs/gtkutil/menu.o \
	libs/gtkutil/messagebox.o \
	libs/gtkutil/nonmodal.o \
	libs/gtkutil/paned.o \
	libs/gtkutil/pointer.o \
	libs/gtkutil/toolbar.o \
	libs/gtkutil/widget.o \
	libs/gtkutil/window.o \
	libs/gtkutil/xorrectangle.o \

libxmllib.$(A): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) $(CPPFLAGS_GLIB) -Ilibs -Iinclude
libxmllib.$(A): \
	libs/xml/ixml.o \
	libs/xml/xmlelement.o \
	libs/xml/xmlparser.o \
	libs/xml/xmltextags.o \
	libs/xml/xmlwriter.o \

install/modules/archivezip.$(DLL): LIBS_EXTRA := $(LIBS_ZLIB)
install/modules/archivezip.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_ZLIB) -Ilibs -Iinclude
install/modules/archivezip.$(DLL): \
	plugins/archivezip/archive.o \
	plugins/archivezip/pkzip.o \
	plugins/archivezip/plugin.o \
	plugins/archivezip/zlibstream.o \

install/modules/archivewad.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/archivewad.$(DLL): \
	plugins/archivewad/archive.o \
	plugins/archivewad/plugin.o \
	plugins/archivewad/wad.o \

install/modules/archivepak.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/archivepak.$(DLL): \
	plugins/archivepak/archive.o \
	plugins/archivepak/pak.o \
	plugins/archivepak/plugin.o \

install/modules/entity.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/entity.$(DLL): \
	plugins/entity/angle.o \
	plugins/entity/angles.o \
	plugins/entity/colour.o \
	plugins/entity/doom3group.o \
	plugins/entity/eclassmodel.o \
	plugins/entity/entity.o \
	plugins/entity/filters.o \
	plugins/entity/generic.o \
	plugins/entity/group.o \
	plugins/entity/light.o \
	plugins/entity/miscmodel.o \
	plugins/entity/model.o \
	plugins/entity/modelskinkey.o \
	plugins/entity/namedentity.o \
	plugins/entity/origin.o \
	plugins/entity/plugin.o \
	plugins/entity/rotation.o \
	plugins/entity/scale.o \
	plugins/entity/skincache.o \
	plugins/entity/targetable.o \

install/modules/image.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/image.$(DLL): \
	plugins/image/bmp.o \
	plugins/image/dds.o \
	plugins/image/image.o \
	plugins/image/jpeg.o \
	plugins/image/pcx.o \
	plugins/image/tga.o \
	libddslib.$(A) \
	libjpeg6.$(A) \

install/modules/imageq2.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/imageq2.$(DLL): \
	plugins/imageq2/imageq2.o \
	plugins/imageq2/wal32.o \
	plugins/imageq2/wal.o \

install/modules/imagehl.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/imagehl.$(DLL): \
	plugins/imagehl/hlw.o \
	plugins/imagehl/imagehl.o \
	plugins/imagehl/mip.o \
	plugins/imagehl/sprite.o \

install/modules/imagepng.$(DLL): LIBS_EXTRA := $(LIBS_PNG)
install/modules/imagepng.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_PNG) -Ilibs -Iinclude
install/modules/imagepng.$(DLL): \
	plugins/imagepng/plugin.o \

install/modules/mapq3.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/mapq3.$(DLL): \
	plugins/mapq3/parse.o \
	plugins/mapq3/plugin.o \
	plugins/mapq3/write.o \

install/modules/mapxml.$(DLL): LIBS_EXTRA := $(LIBS_XML) $(LIBS_GLIB)
install/modules/mapxml.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) $(CPPFLAGS_GLIB) -Ilibs -Iinclude
install/modules/mapxml.$(DLL): \
	plugins/mapxml/plugin.o \
	plugins/mapxml/xmlparse.o \
	plugins/mapxml/xmlwrite.o \

install/modules/md3model.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/md3model.$(DLL): \
	plugins/md3model/md2.o \
	plugins/md3model/md3.o \
	plugins/md3model/md5.o \
	plugins/md3model/mdc.o \
	plugins/md3model/mdlimage.o \
	plugins/md3model/mdl.o \
	plugins/md3model/plugin.o \

install/modules/model.$(DLL): CPPFLAGS_EXTRA := -Ilibs -Iinclude
install/modules/model.$(DLL): \
	plugins/model/model.o \
	plugins/model/plugin.o \
	libpicomodel.$(A) \

install/modules/shaders.$(DLL): LIBS_EXTRA := $(LIBS_GLIB)
install/modules/shaders.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) -Ilibs -Iinclude
install/modules/shaders.$(DLL): \
	plugins/shaders/plugin.o \
	plugins/shaders/shaders.o \

install/modules/vfspk3.$(DLL): LIBS_EXTRA := $(LIBS_GLIB)
install/modules/vfspk3.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) -Ilibs -Iinclude
install/modules/vfspk3.$(DLL): \
	plugins/vfspk3/archive.o \
	plugins/vfspk3/vfs.o \
	plugins/vfspk3/vfspk3.o \

install/plugins/bobtoolz.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK)
install/plugins/bobtoolz.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) -Ilibs -Iinclude
install/plugins/bobtoolz.$(DLL): \
	contrib/bobtoolz/bobToolz-GTK.o \
	contrib/bobtoolz/bsploader.o \
	contrib/bobtoolz/cportals.o \
	contrib/bobtoolz/DBobView.o \
	contrib/bobtoolz/DBrush.o \
	contrib/bobtoolz/DEntity.o \
	contrib/bobtoolz/DEPair.o \
	contrib/bobtoolz/dialogs/dialogs-gtk.o \
	contrib/bobtoolz/DMap.o \
	contrib/bobtoolz/DPatch.o \
	contrib/bobtoolz/DPlane.o \
	contrib/bobtoolz/DPoint.o \
	contrib/bobtoolz/DShape.o \
	contrib/bobtoolz/DTrainDrawer.o \
	contrib/bobtoolz/DTreePlanter.o \
	contrib/bobtoolz/DVisDrawer.o \
	contrib/bobtoolz/DWinding.o \
	contrib/bobtoolz/funchandlers-GTK.o \
	contrib/bobtoolz/lists.o \
	contrib/bobtoolz/misc.o \
	contrib/bobtoolz/ScriptParser.o \
	contrib/bobtoolz/shapes.o \
	contrib/bobtoolz/visfind.o \
	libcmdlib.$(A) \
	libmathlib.$(A) \
	libprofile.$(A) \

install/plugins/brushexport.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK)
install/plugins/brushexport.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) -Ilibs -Iinclude
install/plugins/brushexport.$(DLL): \
	contrib/brushexport/callbacks.o \
	contrib/brushexport/export.o \
	contrib/brushexport/interface.o \
	contrib/brushexport/plugin.o \
	contrib/brushexport/support.o \

install/plugins/prtview.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK)
install/plugins/prtview.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) -Ilibs -Iinclude
install/plugins/prtview.$(DLL): \
	contrib/prtview/AboutDialog.o \
	contrib/prtview/ConfigDialog.o \
	contrib/prtview/LoadPortalFileDialog.o \
	contrib/prtview/portals.o \
	contrib/prtview/prtview.o \
	libprofile.$(A) \

install/plugins/shaderplug.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK) $(LIBS_XML)
install/plugins/shaderplug.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) $(CPPFLAGS_XML) -Ilibs -Iinclude
install/plugins/shaderplug.$(DLL): \
	contrib/shaderplug/shaderplug.o \
	libxmllib.$(A) \

install/plugins/sunplug.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK)
install/plugins/sunplug.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) -Ilibs -Iinclude
install/plugins/sunplug.$(DLL): \
	contrib/sunplug/sunplug.o \

install/qdata3.$(EXE): LIBS_EXTRA := $(LIBS_XML)
install/qdata3.$(EXE): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) -Itools/quake2/common -Ilibs -Iinclude
install/qdata3.$(EXE): \
	tools/quake2/common/bspfile.o \
	tools/quake2/common/cmdlib.o \
	tools/quake2/common/inout.o \
	tools/quake2/common/l3dslib.o \
	tools/quake2/common/lbmlib.o \
	tools/quake2/common/mathlib.o \
	tools/quake2/common/md4.o \
	tools/quake2/common/path_init.o \
	tools/quake2/common/polylib.o \
	tools/quake2/common/scriplib.o \
	tools/quake2/common/threads.o \
	tools/quake2/common/trilib.o \
	tools/quake2/qdata/images.o \
	tools/quake2/qdata/models.o \
	tools/quake2/qdata/qdata.o \
	tools/quake2/qdata/sprites.o \
	tools/quake2/qdata/tables.o \
	tools/quake2/qdata/video.o \
	libl_net.$(A) \
	$(if $(findstring $(OS),Win32),icons/qdata3.o,) \

install/q2map.$(EXE): LIBS_EXTRA := $(LIBS_XML)
install/q2map.$(EXE): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) -Itools/quake2/common -Ilibs -Iinclude
install/q2map.$(EXE): \
	tools/quake2/common/bspfile.o \
	tools/quake2/common/cmdlib.o \
	tools/quake2/common/inout.o \
	tools/quake2/common/l3dslib.o \
	tools/quake2/common/lbmlib.o \
	tools/quake2/common/mathlib.o \
	tools/quake2/common/md4.o \
	tools/quake2/common/path_init.o \
	tools/quake2/common/polylib.o \
	tools/quake2/common/scriplib.o \
	tools/quake2/common/threads.o \
	tools/quake2/common/trilib.o \
	tools/quake2/q2map/brushbsp.o \
	tools/quake2/q2map/csg.o \
	tools/quake2/q2map/faces.o \
	tools/quake2/q2map/flow.o \
	tools/quake2/q2map/glfile.o \
	tools/quake2/q2map/leakfile.o \
	tools/quake2/q2map/lightmap.o \
	tools/quake2/q2map/main.o \
	tools/quake2/q2map/map.o \
	tools/quake2/q2map/nodraw.o \
	tools/quake2/q2map/patches.o \
	tools/quake2/q2map/portals.o \
	tools/quake2/q2map/prtfile.o \
	tools/quake2/q2map/qbsp.o \
	tools/quake2/q2map/qrad.o \
	tools/quake2/q2map/qvis.o \
	tools/quake2/q2map/textures.o \
	tools/quake2/q2map/trace.o \
	tools/quake2/q2map/tree.o \
	tools/quake2/q2map/writebsp.o \
	libl_net.$(A) \
	$(if $(findstring $(OS),Win32),icons/q2map.o,) \

install/plugins/ufoaiplug.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK)
install/plugins/ufoaiplug.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) -Ilibs -Iinclude
install/plugins/ufoaiplug.$(DLL): \
	contrib/ufoaiplug/ufoai_filters.o \
	contrib/ufoaiplug/ufoai_gtk.o \
	contrib/ufoaiplug/ufoai_level.o \
	contrib/ufoaiplug/ufoai.o \

#install/plugins/bkgrnd2d.$(DLL): LIBS_EXTRA := $(LIBS_GLIB) $(LIBS_GTK)
#install/plugins/bkgrnd2d.$(DLL): CPPFLAGS_EXTRA := $(CPPFLAGS_GLIB) $(CPPFLAGS_GTK) -Ilibs -Iinclude
#install/plugins/bkgrnd2d.$(DLL): \
#	contrib/bkgrnd2d/bkgrnd2d.o \
#	contrib/bkgrnd2d/dialog.o \
#	contrib/bkgrnd2d/plugin.o \

install/heretic2/h2data.$(EXE): LIBS_EXTRA := $(LIBS_XML)
install/heretic2/h2data.$(EXE): CPPFLAGS_EXTRA := $(CPPFLAGS_XML) -Itools/quake2/qdata_heretic2/common -Itools/quake2/qdata_heretic2/qcommon -Itools/quake2/qdata_heretic2 -Itools/quake2/common -Ilibs -Iinclude
install/heretic2/h2data.$(EXE): \
	tools/quake2/qdata_heretic2/common/bspfile.o \
	tools/quake2/qdata_heretic2/common/cmdlib.o \
	tools/quake2/qdata_heretic2/common/inout.o \
	tools/quake2/qdata_heretic2/common/l3dslib.o \
	tools/quake2/qdata_heretic2/common/lbmlib.o \
	tools/quake2/qdata_heretic2/common/mathlib.o \
	tools/quake2/qdata_heretic2/common/md4.o \
	tools/quake2/qdata_heretic2/common/path_init.o \
	tools/quake2/qdata_heretic2/common/qfiles.o \
	tools/quake2/qdata_heretic2/common/scriplib.o \
	tools/quake2/qdata_heretic2/common/threads.o \
	tools/quake2/qdata_heretic2/common/token.o \
	tools/quake2/qdata_heretic2/common/trilib.o \
	tools/quake2/qdata_heretic2/qcommon/reference.o \
	tools/quake2/qdata_heretic2/qcommon/resourcemanager.o \
	tools/quake2/qdata_heretic2/qcommon/skeletons.o \
	tools/quake2/qdata_heretic2/animcomp.o \
	tools/quake2/qdata_heretic2/book.o \
	tools/quake2/qdata_heretic2/fmodels.o \
	tools/quake2/qdata_heretic2/images.o \
	tools/quake2/qdata_heretic2/jointed.o \
	tools/quake2/qdata_heretic2/models.o \
	tools/quake2/qdata_heretic2/pics.o \
	tools/quake2/qdata_heretic2/qdata.o \
	tools/quake2/qdata_heretic2/qd_skeletons.o \
	tools/quake2/qdata_heretic2/sprites.o \
	tools/quake2/qdata_heretic2/svdcmp.o \
	tools/quake2/qdata_heretic2/tables.o \
	tools/quake2/qdata_heretic2/tmix.o \
	tools/quake2/qdata_heretic2/video.o \
	libl_net.$(A) \
	$(if $(findstring $(OS),Win32),icons/h2data.o,) \

.PHONY: install-data
install-data: binaries
	$(MKDIR) install/games
	$(FIND) install/ -name .svn -exec $(RM_R) {} \; -prune
	set -ex; \
	for GAME in games/*; do \
		if [ -d "$$GAME/tools" ]; then \
			GAME=$$GAME/tools; \
		fi; \
		for GAMEFILE in $$GAME/games/*.game; do \
			$(CP) "$$GAMEFILE" install/games/; \
		done; \
		for GAMEDIR in $$GAME/*.game; do \
			$(CP_R) "$$GAMEDIR" install/; \
		done; \
	done
	$(ECHO) $(RADIANT_MINOR_VERSION) > install/RADIANT_MINOR
	$(ECHO) $(RADIANT_MAJOR_VERSION) > install/RADIANT_MAJOR
	$(CP_R) setup/data/tools/* install/
	$(FIND) install/ -name .svn -exec $(RM_R) {} \; -prune

.PHONY: install-dll
ifeq ($(OS),Win32)
install-dll: binaries
	MKDIR="$(MKDIR)" CP="$(CP)" CAT="$(CAT)" GTKDIR="$(GTKDIR)" WHICHDLL="$(WHICHDLL)" $(SH) install-dlls.sh
else
install-dll: binaries
	@$(ECHO) No DLL inclusion implemented for this target.
endif

-include $(shell find . -name \*.d)
