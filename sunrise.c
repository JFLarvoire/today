/*
** Sunrise.c - computes the sunrise and sends the output to stdout
**
** Authors:
**   NC  ncherry@linuxha.com
**   JFL jf.larvoire@free.fr
**
** History:
**   2002       NC  published at http://www.linuxha.com/common/wea_tools.html
**   2018-12-22 JFL Added command-line parsing, and a help screen.
**                  Added options for adding or substracting a time offset.
**   2019-01-11 JFL Added optional argument pszDate, passed to routine sun().
**   2019-01-14 JFL Changed sun() last argument to a struct tm.
**		    Added option -d to dynamically enable the debug mode.
**		    Added option -V to display the program version.
**   2019-11-01 JFL Added support for dates in the ISO 8601 YYYY-DDD format.
**   2019-11-03 JFL Added option -f to display the full date/time.
**   2019-11-16 JFL Added option -v display the place name and full date/time.
**                  Added option -c to set the config file name.
**   2019-11-17 JFL Added system & user config files, and environment variables.
*/

#define VERSION "2019-11-17"

#include <stdio.h>
#include <string.h>
#include <time.h>

#include "today.h"
#include "include/debugm.h"

#define streq(s1, s2) (!strcmp(s1, s2))

#define FALSE 0
#define TRUE 1

int debug = 0;

void usage() {
  char namebuf[256];
  char *pName = defaultSysConfFile(namebuf, sizeof(namebuf));
#if !defined(_MSDOS)
  char namebufU[256];
  char *pNameU = defaultUserConfFile(namebufU, sizeof(namebufU));
  if (pNameU) {
    strcat(pName, " or ");
    strcat(pName, pNameU);
  }
#endif
  printf("\
sunrise - Display the sunrise time\n\
\n\
Usage: sunrise [OPTIONS] [DATE]\n\
\n\
Options:\n\
  -?|-h|--help      Display this help screen\n\
  -N[:M]            Display time N hours and M minutes before sunrise\n\
  +N[:M]            Display time N hours and M minutes after sunrise\n\
  -c PATHNAME       Configuration file name. Default: See below\n\
  -f|--full         Display the full date/time in the canonic ISO 8601 format\n\
  -v|--verbose      Display the full date/time and location information\n\
  -V|--version      Display the program version\n\
\n\
Date: YYYY-MM-DD or YYYY-DDD, with - optional, default: today\n\
\n\
Configuration file: This program has built-in settings for %s.\n\
This can be overridden by creating a configuration file w. these definitions:\n\
LATITUDE = 37.787954                # Latitude. +=North. Required.\n\
LONGITUDE = -122.407498             # Longitude. +=East. Required.\n\
CITY = San Francisco                # City name. Required.\n\
TZABBR = PST                        # Time Zone Abbreviation. Required.\n\
DSTZABBR = PDT                      # TZ DST Abbreviation. Required if exists.\n\
COUNTRYCODE = US                    # Two-letter country code. Optional.\n\
COUNTRYNAME = United States         # Country name. Optional.\n\
REGIONCODE = CA                     # Region or state code. Optional.\n\
Default file names: %s\n\
Recommended: Use whereami.bat (Windows) or whereami.tcl (Unix) to generate them\n\
automatically. In both cases, run 'whereami -?' to get help.\n\
All the above can be overridden with environment variables with the same names.\n\
"
#ifdef __unix__
"\n"
#endif
, city, pName);
}

int main(int argc, char *argv[]) {
  int i;
  int sunrh, sunrm, sunsh, sunsm;
  int nHours = 0, nMinutes = 0;
  struct tm stm;
  struct tm *ptm = NULL;
  int iErr;
  int iFull = FALSE;
  int iVerbose = FALSE;
  char *pszCfgFile = NULL;

  for (i=1; i<argc; i++) {
    char *arg = argv[i];
    if (   streq(arg, "-?")
#if defined(_MSDOS) || defined(_WIN32)
        || streq(arg, "/?")
#endif
        || streq(arg, "-h")
        || streq(arg, "--help")
        ) {
      usage();
      return 0;
    }
    if ((   streq(arg, "-c")	/* -c = Config file name */
         || streq(arg, "--config")) && ((i+1)<argc)) {
      pszCfgFile = argv[++i];
      continue;
    }
    if (   streq(arg, "-d")	/* -d = Debug mode */
        || streq(arg, "--debug")) {
      debug = 1;
      continue;
    }
    if (   streq(arg, "-f")	/* -f = Full date/time mode */
        || streq(arg, "--full")) {
      iFull = 1;
      continue;
    }
    if (   streq(arg, "-v")	/* -v = Verbose mode */
        || streq(arg, "--verbose")) {
      iFull = 1;
      iVerbose = 1;
      continue;
    }
    if (   streq(arg, "-V")     /* -V: Display the version */
	|| streq(arg, "--version")) {
      printf(VERSION " " EXE_OS_NAME "\n");
      return 0;
    }
    /* Else this is an argument */
    /* Try parsing an offset */
    if ((arg[0] == '-') && (sscanf(arg+1, "%d:%d", &nHours, &nMinutes))) {
      nHours = -nHours;
      nMinutes = -nMinutes;
      continue;
    }
    if ((arg[0] == '+') && (sscanf(arg+1, "%d:%d", &nHours, &nMinutes))) {
      continue;
    }
    /* Try parsing another date/time */
    iErr = parsetime(arg, &stm);
    if (!iErr) {
      ptm = &stm;
      continue;
    }
    fprintf(stderr, "Error: Invalid argument: '%s'\n", arg);
    return 1;
  }

  iErr = sun(&sunrh, &sunrm, &sunsh, &sunsm, ptm, pszCfgFile);
  if (iErr) return 1;

  sunrm += nMinutes;
  if (sunrm < 0) {
    sunrm += 60;
    sunrh -= 1;
  } else if (sunrm >= 60) {
    sunrm -= 60;
    sunrh += 1;
  }
  sunrh += nHours;
  
  if (iFull || iVerbose) {
    if (iVerbose) printf("Sunrise in %s, on ", city);
    if (!ptm) {
      time_t now;
      time(&now);			/* get system time */
      ptm = localtime(&now);		/* get ptr to gmt time struct */
    }
    printf("%04d-%02d-%02d", ptm->tm_year+1900, ptm->tm_mon+1, ptm->tm_mday);
    if (iVerbose) printf(", is at");
    printf(" ");
  }

  printf("%02d:%02d", sunrh, sunrm);

  if (iVerbose) {
    /* In Linux, strftime() displays the timezone abbreviation as I wanted.
       But in Windows, it displays the full time zone name from
       HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\TimeZoneInformation\TimeZoneKeyName
       If needed, see:
       HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Time Zones
       https://github.com/unicode-org/cldr/blob/master/common/supplemental/windowsZones.xml
    char tzName[32] = "";
    strftime(tzName, sizeof(tzName), "%Z", ptm);
    printf(" %s", tzName);
    */
    /* So instead, use the configured values */
    printf(" %s", ptm->tm_isdst ? dtzs : tzs); /* See today.h */
    /* TODO: The above time zone is wrong when using a configuration file
       for another location, as the above time is in local time always.
       So either fix the time to be in the configured time zone,
       or fix the TZ string to show the local TZ */
  }
  
  printf("\n");
  
  return 0;
}
