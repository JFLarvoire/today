##
#	Makefile for building today tools for Unix
#
# Authors:
# NC  ncherry@linuxha.com
# JFL jf.larvoire@free.fr
#
# Changes:
# 2003-06-01 NC  Published at http://www.linuxha.com/common/wea_tools.html
# 2018-12-26 JFL Output files into the bin/$(uname -s).$(uname -p)[/Debug] subdirectory.
# 2019-01-18 JFL Use variable PROGRAMS from Files.mak, instead of ALL.
#

# Standard installation directories.
# NOTE: This directory must exist when you start the install.
prefix = /usr/local
datarootdir = $(prefix)/share
datadir = $(datarootdir)
exec_prefix = $(prefix)
# Where to put the executables.
bindir = $(exec_prefix)/bin
# Where to put the libraries.
libdir = $(exec_prefix)/lib
# Where to put the info files.
infodir = $(datarootdir)/info

# Identify the OS and processor, and generate an output base directory name from that
ifeq "$(OS)" ""    # If $(OS) is undefined or empty
  OS := $(shell uname -s)
  PROC := $(shell uname -p)
  MACHINE := $(shell uname -m)
  ifeq "$(OS)" "OSF1"
    ifeq "$(MACHINE)" "alpha"
      OS := Tru64
    endif
  endif
  ifeq "$(OS)" "WindowsNT"
    OS := WIN32
  endif
  # Define the output base directory
  OSP := $(OS).$(PROC)
  # Now handle the special case of Unix-compatible shells for Windows
  ifneq "$(findstring MINGW32, $(OS))" "" # Ex: "MINGW32_NT-6.1"
    # MigGW shell if NOT case sensitive, so use a well readable camelcase spelling
    OSP := MinGW32
    # 2013-12-16 Actually, the 64-bits tool chain also reports MINGW32_NT-6.1
    # So distinguish the two by whether /mingw is mounted on C:\MinGW or C:\MinGW64
    ifneq "$(shell mount | grep -i /mingw64)" ""
      # MigGW shell if NOT case sensitive, so use a well readable camelcase spelling
      OSP := MinGW64
    endif
  endif
  ifneq "$(findstring MINGW64,$(OS))" "" # Ex: ?
    OSP := MinGW64
  endif
  ifneq "$(findstring CYGWIN,$(OS))" "" # Ex: "CYGWIN_NT-6.1-WOW64"
    # Cygwin shell if case sensitive, so use lower case
    OSP := cygwin
  endif
endif

# Output in the bin subdirectory, unless overridden by OUTDIR
ifdef OUTDIR
  ifneq "$(OUTDIR)" "."
    OD := $(OUTDIR)/
  else
    OD := 
  endif
else
  OD := bin/
endif

# Distinguish the output directory bases for normal and debug output
# Normal output base directory
OSPN := $(OD)$(OSP)
# Debug output base directory
OSPD := $(OD)$(OSP)/debug

# Finally define the output directories for the current debug mode
ifdef _DEBUG
OSP := $(OSPD)
else
OSP := $(OSPN)
endif
# Sources path
SP = .
# Objects path
OP = $(OSP)/OBJ
OPN = $(OSPN)/OBJ
OPD = $(OSPD)/OBJ
# Listings path
LP = $(OSP)/LIST
LPN = $(OSPN)/LIST
LPD = $(OSPD)/LIST
# Executables path
XP = $(OSP)
XPN = $(OSPN)
XPD = $(OSPD)

# Build options
CFLAGS	= -O -Wall
CLIBS	= -lm
LDLIBS	= /usr/lib/crt1.o /usr/lib/crti.o # /lib/ld-linux.so.2 

# Make file messages control
TRACE_MSGS = $(or $(filter-out 0, $(VERBOSE)), $(filter-out 0, $(DEBUG)))
REPORT_FAILURE = (ERR=$$? ; echo " ... FAILED" ; exit $$ERR)

# Pattern rules for compiling any standalone C or C++ source.
$(OPN)/%.o: %.c
	$(MAKE) -$(MAKEFLAGS) dirs
	$(info Compiling $<)
	$(CC) $(CFLAGS) $(CPPFLAGS) -U_DEBUG -o $@ -c $< || $(REPORT_FAILURE)
	#(info  ... done)

$(OPD)/%.o: %.c
	$(MAKE) -$(MAKEFLAGS) ddirs
	$(info Compiling $<)
	$(CC) $(CFLAGS) $(CPPFLAGS) -D_DEBUG -o $@ -c $< || $(REPORT_FAILURE)
	#(info  ... done)

$(XPN)/%: $(OPN)/%.o
	$(MAKE) -$(MAKEFLAGS) dirs
	$(info Linking $@)
	$(CC) -o $@ $^ $(CLIBS) || $(REPORT_FAILURE)
	#(info  ... done)                                                               

$(XPD)/%: $(OPD)/%.o
	$(MAKE) -$(MAKEFLAGS) dirs
	$(info Linking $@)
	$(CC) -o $@ $^ $(CLIBS) || $(REPORT_FAILURE)
	#(info  ... done)

.SILENT:

# Default rule.
.PHONY: default all
default: all

include Files.mak

all:	dirs $(PROGRAMS)

.PHONY: dirs ddirs
dirs: $(XPN) $(OPN) $(LPN)

ddirs: $(XPD) $(OPD) $(LPD)

$(XPN) $(OPN) $(LPN) $(XPD) $(OPD) $(LPD):
	$(info Creating directory $@)
	mkdir -p $@

# The local target programs are actually to be built in the $(XP) subdirectory
%: dirs $(XP)/%
	true

# List of object files for each program
$(XP)/localtime: $(OP)/localtime.o $(OP)/parsetime.o

$(XP)/potm: $(OP)/potm.o $(OP)/moontx.o $(OP)/parsetime.o

$(XP)/today: $(OP)/today.o $(OP)/datetx.o $(OP)/moontx.o $(OP)/nbrtxt.o $(OP)/timetx.o $(OP)/sun.o $(OP)/parsetime.o

$(XP)/sunrise: $(OP)/sunrise.o $(OP)/moontx.o $(OP)/sun.o $(OP)/parsetime.o

$(XP)/sunset: $(OP)/sunset.o $(OP)/moontx.o $(OP)/sun.o $(OP)/parsetime.o

.PHONY: install
install: all
	cd $(XP) && cp -p -f $(ALL) $(bindir)

.PHONY: clean
clean:
	-$(RM) $(OPD)/* >/dev/null 2>&1
	-rmdir $(OPD)   >/dev/null 2>&1
	-$(RM) $(LPD)/* >/dev/null 2>&1
	-rmdir $(LPD)   >/dev/null 2>&1
	-$(RM) $(XPD)/* >/dev/null 2>&1
	-rmdir $(XPD)   >/dev/null 2>&1
	-$(RM) $(OPN)/* >/dev/null 2>&1
	-rmdir $(OPN)   >/dev/null 2>&1
	-$(RM) $(LPN)/* >/dev/null 2>&1
	-rmdir $(LPN)   >/dev/null 2>&1
	-$(RM) $(XPN)/* >/dev/null 2>&1
	-rmdir $(XPN)   >/dev/null 2>&1
	-$(RM) *.log    >/dev/null 2>&1

define HELP
Usage: make [MAKEOPTS] [MAKEDEFS] [TARGETS]

Targets:
  all       Build all programs defined in Files.mak. Default.
  clean     Delete all files generated by this Makefile
  help      Display this help message
  install   Copy the executable files to $(bindir)
  localtime Build $(XP)/localtime
  potm      Build $(XP)/potm
  today     Build $(XP)/today
  sunrise   Build $(XP)/sunrise
  sunset    Build $(XP)/sunset

endef

# Makedefs:
#   _DEBUG=1  Build the debug version of the programs

export HELP
help:
	echo "$$HELP"

