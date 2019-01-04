@echo off
:#*****************************************************************************
:#                                                                            *
:#  Filename:	    configure.today.bat					      *
:#                                                                            *
:#  Description:    Today-specific tasks for configure.bat		      *
:#                                                                            *
:#  Notes:	                                                              *
:#		    							      *
:#  History:                                                                  *
:#   2019-01-04 JFL Created this script					      *
:#                                                                            *
:#*****************************************************************************

:# Where to find the SysToolsLib include files and make system
set "STINCLUDE=include"

:# Make a local copy of configure.bat and make.bat, to avoid typing their relative path
xcopy /c /d include\make.bat		>NUL
xcopy /c /d include\configure.bat	>NUL
