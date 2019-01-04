/*
** Sunset.c - computes the sunset and sends the output to stdout
**
** Authors:
** NC  ncherry@linuxha.com
** JFL jf.larvoire@free.fr
**
** History:
** 2002           NC published at http://www.linuxha.com/common/wea_tools.html
** 2018-12-22 JFL Added command-line parsing, and a help screen.
**                Added options for adding or substracting a time offset.
*/

#include <stdio.h>
#include <string.h>

#include "today.h"

#define streq(s1, s2) (!strcmp(s1, s2))

void usage() {
  printf("\
sunset - Display the sunset time\n\
\n\
Usage: sunset [OPTIONS]\n\
\n\
Options:\n\
  -?        Display this help screen\n\
  -N[:M]    Display time N hours and M minutes before sunset\n\
  +N[:M]    Display time N hours and M minutes after sunset\n\
\n\
");
}

int main(int argc, char *argv[]) {
  int i;
  int sunrh, sunrm, sunsh, sunsm;
  int nHours = 0, nMinutes = 0;

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
  }

  sun(&sunrh, &sunrm, &sunsh, &sunsm);

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
