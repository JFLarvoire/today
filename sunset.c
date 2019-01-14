/*
** Sunset.c - computes the sunset and sends the output to stdout
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
*/

#define VERSION "2019-01-14"

#include <stdio.h>
#include <string.h>
#include <time.h>

#include "today.h"
#include "include/debugm.h"

#define streq(s1, s2) (!strcmp(s1, s2))

int debug = 0;

void usage() {
  printf("\
sunset - Display the sunset time\n\
\n\
Usage: sunset [OPTIONS] [DATE]\n\
\n\
Options:\n\
  -?            Display this help screen\n\
  -N[:M]        Display time N hours and M minutes before sunset\n\
  +N[:M]        Display time N hours and M minutes after sunset\n\
  -V|--version  Display the program version\n\
\n\
Date: YYYY-MM-DD, default: today\n\
\n\
");
}

int main(int argc, char *argv[]) {
  int i;
  int sunrh, sunrm, sunsh, sunsm;
  int nHours = 0, nMinutes = 0;
  struct tm stm;
  struct tm *ptm = NULL;
  int iErr;

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

  sun(&sunrh, &sunrm, &sunsh, &sunsm, ptm);

  sunsm += nMinutes;
  if (sunsm < 0) {
    sunsm += 60;
    sunsh -= 1;
  } else if (sunsm >= 60) {
    sunsm -= 60;
    sunsh += 1;
  }
  sunsh += nHours;
  
  printf("%02d:%02d\n", sunsh, sunsm);

  return(0);
}
