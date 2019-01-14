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
*/

#define VERSION "2019-01-14"

#include <stdio.h>
#include <string.h>

#include "today.h"
#include "moontx.h"
#include "include/debugm.h"

static	char	potm[64];

int debug = 0;

#define streq(s1, s2) (!strcmp(s1, s2))

void usage() {
  printf("\
potm - Print out the phase of the moon\n\
\n\
Usage: potm [OPTIONS] [DATE]\n\
\n\
Options:\n\
  -?|-h|--help  Display this help screen\n\
  -V|--version  Display the program version\n\
\n\
Date: YYYY-MM-DD, default: today\n\
\n\
");
}

int main(int argc, char *argv[]) {
  int i;
  struct tm stm;
  int iErr;
  int done = 0;
  
  for (i=1; i<argc; i++) {
    char *arg = argv[i];
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
      if (   streq(opt, "V")     /* -V: Display the version */
	  || streq(opt, "-version")) {
	printf(VERSION " " EXE_OS_NAME "\n");
	return 0;
      }
      fprintf(stderr, "Unexpected option: %s\n", arg);
      return 1;
    }
    /* Else this is an argument */
    iErr = parsetime(arg, &stm);
    if (iErr) {
      fprintf(stderr, "Error at offset %d parsing date/time \"%s\".\n", iErr-1, arg);
      return 1;
    };
    moontxt(potm, &stm);
    printf("Phase-of-the-Moon:%s\n", potm+11);
    done = 1;
  }

  if (!done) {
    moontxt(potm, NULL);
    printf("Phase-of-the-Moon:%s\n", potm+11);
  }
  return 0;
}
