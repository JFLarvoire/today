/*
** localtime.c - Output the local time to stdout
**
** Allows testing parsetime.c.
** Also useful to convert GMT times to local time.
**
** Authors:
**   JFL jf.larvoire@free.fr
**
** History:
**   2019-01-20 JFL Created this program.
**   2019-11-01 JFL Added support for dates in the ISO 8601 YYYY-DDD format.
**   2019-11-03 JFL Added option -f to display the full date/time.
*/

#define VERSION "2019-11-03"

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
  printf("\
localtime - Display the local time\n\
\n\
Usage: localtime [OPTIONS] [DATE_TIME]\n\
\n\
Options:\n\
  -?            Display this help screen\n\
  -f            Display the full date/time in the canonic ISO 8601 format\n\
  -V|--version  Display the program version\n\
\n\
Date_time: [YYYY-MM-DD][T]HH:MM[:SS][Z], default: now, default date: today\n\
           The date can also be formatted as YYYY-DDD\n\
           The optional Z suffix flags a GMT time\n\
\n\
");
}

int main(int argc, char *argv[]) {
  int i;
  struct tm stm;
  struct tm *ptm = NULL;
  int iErr;
  int iFull = FALSE;

  for (i=1; i<argc; i++) {
    char *arg = argv[i];
    if (   streq(arg, "-?")
        || streq(arg, "-h")
        || streq(arg, "--help")
        ) {
      usage();
      return 0;
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
    if (   streq(arg, "-V")     /* -V: Display the version */
	|| streq(arg, "--version")) {
      printf(VERSION " " EXE_OS_NAME "\n");
      return 0;
    }
    /* Else this is an argument */
    /* Try parsing another date/time */
    iErr = parsetime(arg, &stm);
    if (!iErr) {
      ptm = &stm;
      continue;
    }
    fprintf(stderr, "Error: Invalid argument: '%s'\n", arg);
    return 1;
  }

  if (!ptm) {
    time_t now;
    time(&now);			/* get system time */
    ptm = localtime(&now);	/* get ptr to gmt time struct */
  }
  
  if (iFull) printf("%04d-%02d-%02d ", ptm->tm_year+1900, ptm->tm_mon+1, ptm->tm_mday);

  if (ptm->tm_min == -2) ptm->tm_min = 0;
  printf("%02d:%02d", ptm->tm_hour, ptm->tm_min);
  if (ptm->tm_sec == -2) {
    ptm->tm_sec = 0;
  } else {
    printf(":%02d", ptm->tm_sec);
  }
  printf("\n");
  
  if (debug) printf("# %s\n", asctime(ptm));

  return 0;
}
