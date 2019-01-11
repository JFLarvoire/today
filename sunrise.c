/*
** Sunrise.c - computes the sunrise and sends the output to stdout
**
** Authors:
** NC  ncherry@linuxha.com
** JFL jf.larvoire@free.fr
**
** History:
** 2002           NC published at http://www.linuxha.com/common/wea_tools.html
** 2018-12-22 JFL Added command-line parsing, and a help screen.
**                Added options for adding or substracting a time offset.
** 2019-01-11 JFL Added optional argument pszDate, passed to routine sun().
*/

#include <stdio.h>
#include <string.h>

#include "today.h"

#define streq(s1, s2) (!strcmp(s1, s2))

void usage() {
  printf("\
sunrise - Display the sunrise time\n\
\n\
Usage: sunrise [OPTIONS] [DATE]\n\
\n\
Options:\n\
  -?        Display this help screen\n\
  -N[:M]    Display time N hours and M minutes before sunrise\n\
  +N[:M]    Display time N hours and M minutes after sunrise\n\
\n\
Date: YYYY-MM-DD, default: today\n\
\n\
");
}

int main(int argc, char *argv[]) {
  int i;
  int sunrh, sunrm, sunsh, sunsm;
  int nHours = 0, nMinutes = 0;
  int iYear, iMonth, iDay;
  char *pszDate = NULL;

  for (i=1; i<argc; i++) {
    char *arg = argv[i];
    if (   streq(arg, "-?")
        || streq(arg, "-h")
        || streq(arg, "--help")
        ) {
      usage();
      return 0;
    }
    if ((arg[0] == '-') && (sscanf(arg+1, "%d:%d", &nHours, &nMinutes))) {
      nHours = -nHours;
      nMinutes = -nMinutes;
      continue;
    }
    if ((arg[0] == '+') && (sscanf(arg+1, "%d:%d", &nHours, &nMinutes))) {
      continue;
    }
    if ((sscanf(arg, "%d-%d-%d", &iYear, &iMonth, &iDay) == 3) && iYear && iMonth && iDay) {
      pszDate = arg;
      continue;
    }
    fprintf(stderr, "Error: Invalid argument: '%s'\n", arg);
    return 1;
  }

  sun(&sunrh, &sunrm, &sunsh, &sunsm, pszDate);

  sunrm += nMinutes;
  if (sunrm < 0) {
    sunrm += 60;
    sunrh -= 1;
  } else if (sunrm >= 60) {
    sunrm -= 60;
    sunrh += 1;
  }
  sunrh += nHours;
  
  printf("%02d:%02d\n", sunrh, sunrm);

  return 0;
}
