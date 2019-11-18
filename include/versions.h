/*****************************************************************************\
*                                                                             *
*   Filename:	    versions.h						      *
*                                                                             *
*   Description:    Define version names (DEBUG_VERSION, EXE_OS_NAME)	      *
*                                                                             *
*   Notes:	                                                              *
*                                                                             *
*   History:								      *
*    2019-11-18 JFL jf.larvoire@hpe.com Split off of SysToolsLib's debugm.h.  *
*		    							      *
*        (C) Copyright 2016 Hewlett Packard Enterprise Development LP         *
* Licensed under the Apache 2.0 license - www.apache.org/licenses/LICENSE-2.0 *
\*****************************************************************************/

#ifndef	_VERSIONS_H
#define	_VERSIONS_H	1

#if defined(_DEBUG)
#define DEBUG_VERSION " Debug"
#else
#define DEBUG_VERSION ""	/* Non debug version: Simply don't say it */
#endif
                                                                  
/******************** OS identification string definition ********************/

#ifdef _MSDOS		/* Automatically defined when targeting an MS-DOS app. */
#  define EXE_OS_NAME "DOS"
#endif /* _MSDOS */

#ifdef _OS2		/* To be defined on the command line for the OS/2 version */
#  define EXE_OS_NAME "OS/2"
#endif /* _OS2 */

#ifdef _WIN32		/* Automatically defined when targeting a Win32 app. */
#  if defined(__MINGW64__)
#    define EXE_OS_NAME "MinGW64"
#  elif defined(__MINGW32__)
#    define EXE_OS_NAME "MinGW32"
#  elif defined(_WIN64)
#    define EXE_OS_NAME "Win64"
#  else
#    define EXE_OS_NAME "Win32"
#  endif
#endif /* _WIN32 */

#ifdef __unix__		/* Automatically defined when targeting a Unix app. */
#  if defined(__CYGWIN64__)
#    define EXE_OS_NAME "Cygwin64"
#  elif defined(__CYGWIN32__)
#    define EXE_OS_NAME "Cygwin"
#  elif defined(_TRU64)
#    define EXE_OS_NAME "Tru64"	/* 64-bits Alpha Tru64 */
#  elif defined(__linux__)
#    define EXE_OS_NAME "Linux"
#  else
#    define EXE_OS_NAME "Unix"
#  endif
#endif /* __unix__ */

/**************** End of OS identification string definition *****************/

#endif /* !defined(_VERSIONS_H) */

