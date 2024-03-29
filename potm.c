/*
** potm.c -- Print out the phase of the moon ...
**
** Authors:
**   JAD John Dilley
**   JFL jf.larvoire@free.fr
**
**
**	creation date:	Sat Feb  9 14:27
**
**
** History:
**   ????-02-09 JAD Created this program
**   2019-01-14 JFL Added an optional date argument.
**		    Added option -d to dynamically enable the debug mode.
**		    Added option -V to display the program version.
**   2019-01-15 JFL Added the moon output as Ascii Art.
**   2019-01-16 JFL Added option -i to output the moon on inverse video screens.
**   2019-11-01 JFL Added support for dates in the ISO 8601 YYYY-DDD format.
**   2019-11-17 JFL Added option /? for Windows.
**   2019-11-18 JFL Use the new versions.h instead of include/debugm.h.
*/

#define VERSION "2019-11-18"

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

#include "today.h"
#include "moontx.h"
#include "versions.h"

static	char	potm[64];

int debug = 0;

#define streq(s1, s2) (!strcmp(s1, s2))

void usage() {
  printf("\
potm - Print out the phase of the moon as text, and as Ascii Art\n\
\n\
Usage: potm [OPTIONS] [DATE]\n\
\n\
Options:\n\
  -?|-h|--help  Display this help screen\n\
  -i|--inverse  It's an inverse video terminal (black text on white background)\n\
  -V|--version  Display the program version\n\
\n\
Date: YYYY-MM-DD or YYYY-DDD, with - optional, default: today\n\
\n\
");
}

int main(int argc, char *argv[]) {
  int i;
  struct tm stm;
  int iErr;
  struct tm *ptm = NULL;
  char *pBuf;
  int inverse = 0;

  for (i=1; i<argc; i++) {
    char *arg = argv[i];
#if defined(_MSDOS) || defined(_WIN32)
    if (streq(arg, "/?")) arg[0] = '-';
#endif
    if (arg[0] == '-') { /* This is an option */
      char *opt = arg+1;
      if (   streq(opt, "?")
	  || streq(opt, "h")
	  || streq(opt, "-help")
	  ) {
	usage();
	return 0;
      }
      if (   streq(opt, "d")	/* -d = Debug mode */
	  || streq(opt, "-debug")) {
	debug = 1;
	continue;
      }
      if (   streq(opt, "i")	/* -i = Inverse video mode */
	  || streq(opt, "-inverse")) {
	inverse = 1;
	continue;
      }
      if (   streq(opt, "V")     /* -V: Display the version */
	  || streq(opt, "-version")) {
	printf(VERSION " " EXE_OS_NAME "\n");
	return 0;
      }
      fprintf(stderr, "Unexpected option: %s\n", arg);
      return 1;
    }
    /* Else this is an argument */
    if (!ptm) {
      iErr = parsetime(arg, &stm);
      if (iErr) {
	fprintf(stderr, "Error at offset %d parsing date/time \"%s\".\n", iErr-1, arg);
	return 1;
      };
      ptm = &stm;
      continue;
    }
    fprintf(stderr, "Unexpected argument: %s\n", arg);
    return 1;
  }

  /* Display the phase of the moon as text */
  moontxt(potm, ptm);
  printf("Phase-of-the-Moon:%s\n", potm+11);

  /* Display the phase of the moon as Ascii Art */
  pBuf = moonaa(20, 38, inverse, ptm);
  if (!pBuf) return 1;
  fputs(pBuf, stdout);
  free(pBuf);

  return 0;
}
