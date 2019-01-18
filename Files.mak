##
# OS-independant make file defining the today programs to build 
#
# Changes:
# 2018-12-24 JFL Adapted to build for Windows with the MsvcLibX library make system.
# 2019-01-18 JFL Define variable PROGRAMS instead of ALL, now usable both in Windows and Unix.
#

# List of programs to build
PROGRAMS = sunrise sunset today potm

ZIPFILE = $(OD)today.zip
ZIPSOURCES = *.c *.h *Makefile *.mak *.bat *.md include

# Include files dependencies (Microsoft nmake considers the .c touched if a .h is newer)
nbrtxt.c:	today.h

datetx.c:	today.h

moontx.c:	today.h moontx.h

sun.c:		today.h params.h

potm.c:		today.h  moontx.h

sunrise.c:	today.h

sunset.c:	today.h

timetx.c:	today.h params.h

today.c:	today.h
