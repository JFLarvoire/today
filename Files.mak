##
#	Makefile for very verbose date command (today).
#
# Changes:
# 2018-12-24 JFL Adapted to build for Windows with the MsvcLibX library make system
#

# List of programs to build
ALL = sunrise$(_EXE) sunset$(_EXE) today$(_EXE) potm$(_EXE)

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
