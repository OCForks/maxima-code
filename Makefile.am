if ENABLE_GETTEXT
   LOCALE_DIR = locale
endif

SUBDIRS = admin src lisp-utils tests doc interfaces share demo plotting $(LOCALE_DIR)

EXTRA_DIST = \
  common.mk maxima.iss.in \
  README.lisps README.rpms README.i18n README.external \
  INSTALL.win32 INSTALL.lisp \
  configure.lisp  maxima-local.in xmaxima-local.in \
  macosx/Makefile macosx/Readme.txt macosx/maxima.sh macosx/script \
  macosx/xmaxima.sh macosx/appIcon.icns \
  ChangeLog-5.9.2 ChangeLog-5.9.3 ChangeLog-5.10.0 ChangeLog-5.11.0 \
  ChangeLog-5.12.0 ChangeLog-5.13.0 ChangeLog-5.14.0 ChangeLog-5.15.0 \
  ChangeLog-5.16 ChangeLog-5.17 ChangeLog-5.17-special-functions \
  ChangeLog-5.18 ChangeLog-5.19 ChangeLog-5.20 ChangeLog-5.21 ChangeLog-5.22 \
  ChangeLog-5.23 ChangeLog-5.24 ChangeLog-5.25 ChangeLog-5.26 ChangeLog-5.27 \
  ChangeLog-5.28 ChangeLog-5.29 ChangeLog-5.30 ChangeLog-5.31 ChangeLog-5.32 \
  ChangeLog-5.33 ChangeLog-5.34 ChangeLog-5.35 ChangeLog-5.36.md

include common.mk

extradocinstall:
	test -d "$(DESTDIR)$(docdir)" || mkdir -p "$(DESTDIR)$(docdir)"
	for file in AUTHORS COPYING INSTALL README README.lisps ; \
            do \
            $(INSTALL_DATA) $$file "$(DESTDIR)$(docdir)" ; \
            done

$(distdir).tar.gz: Makefile.am
	$(MAKE) dist

# Build the Maxima rpms. Optionally, use
#     make rpm SUDO=sudo
# to use sudo to wrap the commands. The user must have sudo permissions
# for rpm and cp.
rpm: $(distdir).tar.gz
	$(SUDO) cp $(distdir).tar.gz /usr/src/redhat/SOURCES && \
	$(SUDO) rpmbuild -ba maxima.spec

# windows installer rules
if WIN32

GNUPLOTDIR = "/c/programs/gnuplot"
WXMAXIMADIR = "/c/programs/wxMaxima"

# Install the gnuplot binary files
gnuplot: 
	mkdir -p $(prefix)/gnuplot
	cp -rf $(GNUPLOTDIR) $(prefix)/

# Install wxMaxima
wxmaxima:
	test -d "$(prefix)/bin" || mkdir -p "$(prefix)/bin"
	cp -rf $(WXMAXIMADIR) $(prefix)/wxMaxima

cclcopy:
	test -d "$(prefix)/bin" || mkdir -p "$(prefix)/bin"
	cp "$(OPENMCL_NAME)" "$(prefix)/bin/"

sbclcopy:
	test -d "$(prefix)/bin" || mkdir -p "$(prefix)/bin"
	cp "$(SBCL_NAME)" "$(prefix)/bin/"

RUNTIMECOPY = 
# Install files for lisp runtime support
if GCL
RUNTIMECOPY += gcccopy
endif

if OPENMCL
RUNTIMECOPY += cclcopy
endif

if SBCL
RUNTIMECOPY += sbclcopy
endif

# Install files for lisp runtime support
win32-lisp-runtime: $(RUNTIMECOPY)

MINGW=/mingw
if GCC331
GCCPREFIX=/usr/local
# Old gcc/mingw/msys install
gcccopy:
	test -d "$(prefix)/bin" || mkdir -p "$(prefix)/bin"
	test -d "$(prefix)/include" || mkdir -p "$(prefix)/include"
	test -d "$(prefix)/include/sys" || mkdir -p "$(prefix)/include/sys"
	test -d "$(prefix)/lib/gcc-lib/mingw32/$(GCCVER)/include" \
		|| mkdir -p "$(prefix)/lib/gcc-lib/mingw32/$(GCCVER)/include"
	cp $(GCCPREFIX)/bin/gcc.exe $(prefix)/bin
	cp $(MINGW)/bin/mingwm10.dll $(prefix)/bin
	cp $(MINGW)/bin/tclpip84.dll $(prefix)/bin
	cp $(MINGW)/include/stdio.h $(prefix)/include
	cp $(MINGW)/include/stdlib.h $(prefix)/include
	cp $(MINGW)/include/setjmp.h $(prefix)/include
	cp $(MINGW)/include/_mingw.h $(prefix)/include
	cp $(MINGW)/include/math.h $(prefix)/include
	cp $(MINGW)/include/unistd.h $(prefix)/include
	cp $(MINGW)/include/io.h $(prefix)/include
	cp $(MINGW)/include/process.h $(prefix)/include
	cp $(MINGW)/include/getopt.h $(prefix)/include
	cp $(MINGW)/include/stdint.h $(prefix)/include
	cp $(MINGW)/include/sys/*.h $(prefix)/include/sys
	cp $(MINGW)/include/varargs.h $(prefix)/include
	cp $(MINGW)/include/stddef.h $(prefix)/include
	cp $(GCCPREFIX)/lib/gcc-lib/mingw32/$(GCCVER)/cc1.exe \
		$(prefix)/lib/gcc-lib/mingw32/$(GCCVER)
	cp $(MINGW)/bin/as.exe \
		$(prefix)/lib/gcc-lib/mingw32/$(GCCVER)
	cp $(GCCPREFIX)/lib/gcc-lib/mingw32/$(GCCVER)/specs  \
		$(prefix)/lib/gcc-lib/mingw32/$(GCCVER)
	cp $(GCCPREFIX)/lib/gcc-lib/mingw32/$(GCCVER)/include/*.h  \
		$(prefix)/lib/gcc-lib/mingw32/$(GCCVER)/include

else # GCC331

GCCPREFIX=$(MINGW)
# New (November 2013) gcc/mingw/msys install using gcc-4.8.1
gcccopy:
	test -d "$(prefix)/bin" || mkdir -p "$(prefix)/bin"
	test -d "$(prefix)/include" || mkdir -p "$(prefix)/include"
	test -d "$(prefix)/include/sys" || mkdir -p "$(prefix)/include/sys"
	test -d "$(prefix)/lib/gcc/mingw32/$(GCCVER)/include" \
		|| mkdir -p "$(prefix)/lib/gcc/mingw32/$(GCCVER)/include"
	test -d "$(prefix)/libexec/gcc/mingw32/$(GCCVER)" \
		|| mkdir -p "$(prefix)/libexec/gcc/mingw32/$(GCCVER)"
	cp $(GCCPREFIX)/bin/gcc.exe $(prefix)/bin
	cp $(MINGW)/bin/mingwm10.dll $(prefix)/bin
	cp $(GCCPREFIX)/bin/libgmp-10.dll $(prefix)/bin
	cp $(GCCPREFIX)/bin/libmpc-3.dll $(prefix)/bin
	cp $(GCCPREFIX)/bin/libmpfr-4.dll $(prefix)/bin
	cp /c/tcl/bin/tclpip85.dll $(prefix)/bin
	cp $(MINGW)/include/stdio.h $(prefix)/include
	cp $(MINGW)/include/stdlib.h $(prefix)/include
	cp $(MINGW)/include/setjmp.h $(prefix)/include
	cp $(MINGW)/include/_mingw.h $(prefix)/include
	cp $(MINGW)/include/math.h $(prefix)/include
	cp $(MINGW)/include/unistd.h $(prefix)/include
	cp $(MINGW)/include/io.h $(prefix)/include
	cp $(MINGW)/include/process.h $(prefix)/include
	cp $(MINGW)/include/getopt.h $(prefix)/include
	cp $(MINGW)/include/stdint.h $(prefix)/include
	cp $(MINGW)/include/sys/*.h $(prefix)/include/sys
	cp $(GCCPREFIX)/libexec/gcc/mingw32/$(GCCVER)/cc1.exe \
		$(prefix)/libexec/gcc/mingw32/$(GCCVER)
	cp $(GCCPREFIX)/libexec/gcc/mingw32/$(GCCVER)/liblto_plugin-0.dll \
		$(prefix)/libexec/gcc/mingw32/$(GCCVER)
	cp $(MINGW)/bin/as.exe \
		$(prefix)/libexec/gcc
	cp $(GCCPREFIX)/lib/gcc/mingw32/$(GCCVER)/include/*.h  \
		$(prefix)/lib/gcc/mingw32/$(GCCVER)/include

endif # GCC331

iss: win32-lisp-runtime wxmaxima gnuplot extradocinstall

endif # WIN32
