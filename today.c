/*
 *			T O D A Y
 *
 * time of day
 *
 * Define UNIX for "native" Unix
 *
 * Changes:
 * 2002           NC published at http://www.linuxha.com/common/wea_tools.html
 * 2019-01-11 JFL Generalized command-line parsing, and added a help screen.
 *		  Added option -d to dynamically enable the debug mode.
 *                Updated dotexttime() to support standard ISO dates like 2018-12-25T23:59,
 *		  and extended ones like "2018-12-25 23h59m59s".
 *		  Bugfix: process() always called sun() for today, not for the specified day.
 *		  Added option -w to set the output width, and default to the screen width.
 *		  Added options -a, -m, -q to further control what's displayed.
 */

/*)BUILD	$(PROGRAM)	= today
		$(FILES)	= { today datetx timetx nbrtxt moontx }
		$(TKBOPTIONS)	= {
			TASK	= ...TOD
		}
*/

#ifdef	DOCUMENTATION

title	today	Date and Time in English
index		Date and Time in English

synopsis

	today [-] [x] | [date]

description

	Today prints the date, time, and phase of the moon in English.
	The following options are available:
	.lm +8
	.s.i -8;- or x	Read date strings from the standard input file.
	.s.i -8;date	Print information for the indicated date.
	.s.lm -8
	Date and time information is given in ISO numeric notation.  For
	example, November 6, 1980 would be represented as "801106".  If
	a time is needed, it would be appended to the date, using 24-hour
	notation: "801106110402" would be a time which is exact to the
	second.  To specify the century, the two-digit century number
	may be preceeded by '+' as in "+18801106".
	.s
	Non-numeric separators between the various fields are permitted:
	"+1776.07.04-11:15:21".  Note that the full two digit entry must be
	given.
	.s
	If no parameter is given, today outputs the current date and time.

diagnostics

	.lm +8
	.s.i -8;Bad parameters or date out of range in ...
	.s
	An input date or time is incorrect.
	.lm -8

author

	Martin Minow

bugs

	The algorithm is only valid for the Gregorian calender.

#endif

#undef	APRIL_FOOLS

int	__narg	=	1;		/* No prompt if no args		*/
#define LINEWIDTH       72              /* Width of line                */
#define MAXLINEWIDTH    256             /* Width of line                */

#include <stdio.h>
#include <time.h>
#include <ctype.h>
#include <string.h>
#include <stdlib.h>

#include "today.h"

#include "screensize.c" /* Define the OS-specific function GetScreenColumns() */

#define streq(s1, s2) (!strcmp(s1, s2))

#undef NULL

#define	NULL		0
#define	EOS		0
#define	FALSE		0
#define	TRUE		1

int day_month[] = {			/* Needed for dotexttime()      */
	0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};
int     ccpos;                          /* Current line position        */
char    lastbyte;                       /* Memory for output()          */
char    line[100];                      /* Data line for input function */
char    *valptr;                        /* Needed for number converter  */
char    wordbuffer[MAXLINEWIDTH];       /* Buffer for output function   */
char    *wordptr = wordbuffer;          /* Free byte in wordbuffer      */
char	linebuffer[MAXLINEWIDTH+2];	/* Output text buffer		*/
char	*lineptr = linebuffer;		/* Free byte in linebuffer	*/
int     polish;                         /* Funny mode flag              */
int	sunrise;			/* Sunrise print flag		*/
int	moon;				/* Sunrise print flag		*/
int	quiet;				/* Quiet mode flag		*/
int     lineWidth = LINEWIDTH;		/* Output width			*/
static	char    outline[500];		/* Output buffer                */
static  int     debug = 0;

/* Forward references to local routines */
void dotime(void);
int dotexttime(char *text);
void process(int year, int month, int day, int hour, int minute, int second, int daylight);
void output(char *text);
void put(register char c);
int getLine(void);
int getval(int flag, int low, int high);


void usage() {
  printf("\
today - Driver for time routines\n\
\n\
Usage: today [OPTIONS] [DATE [...]]\n\
\n\
Options:\n\
  -?|-h|--help          Display this help screen\n\
  -a	                Print all details. Implies -m and -s\n\
  -m	                Also print the moon phase\n\
  -p|p|P                Polish joke mode\n\
  -q                    Quiet mode. Print just the bare date\n\
  -s|s|S                Also print sunrise and sunset\n\
  -w WIDTH              Set the line width. 0=unlimited. Default=Screen width\n\
  -|-x|x|X              Dates are read from the standard input\n\
\n\
Date:			Prints the day, and optional time, in plain English.\n\
  YYYY-MM-DD[THH:MM:SS] ISO format. Ex: 2018-12-25T23:59 or \"2018-12-25 23h59m\"\n\
  [+CC]YYMMDD[HHMMSS]   Compacted ISO format.\n\
\n\
Default: Print date & time, today's sunrise & sunset, followed by a cookie.\n\
\n\
");
}


int main(argc, argv)
int     argc;
char    *argv[];
/*
 * Driver for time routines.
 */
{
  int i;

  ccpos = 0;                    /* New line now                 */
  wordptr = wordbuffer;         /* Nothing buffered             */
  lineptr = linebuffer;		/* Nothing in output buffer too	*/
  polish = 0;			/* Normal mode			*/

  lineWidth = GetScreenColumns() - 1;
  if (lineWidth > MAXLINEWIDTH) lineWidth = MAXLINEWIDTH;
  sunrise = 0;

  for (i=1; i<argc; i++) {
    char *arg = argv[i];
    char cArg = arg[0];
    if (cArg) cArg |= '\x20';	/* Convert the first arg letter to lower case */
    if (   streq(arg, "-?")
        || streq(arg, "/?")
        || streq(arg, "-h")
        || streq(arg, "--help")
        ) {
      usage();
      return 0;
    }
    if (arg[0] == '-') { /* This is an option */
      char *opt = arg+1;
      char cOpt = opt[0];
      if (cOpt) cOpt |= '\x20';	/* Convert the first opt letter to lower case */
      if (cOpt == 'a') {	/* -a = Display all available information */
	sunrise = 1;
	moon = 1;
	continue;
      }
      if (cOpt == 'd') {	/* -d = Debug mode */
	debug = 1;
	continue;
      }
      if (cOpt == 'm') {	/* -m = Display moon phase */
	moon = 1;
	continue;
      }
      if (cOpt == 'p') {	/* -p = Polish joke mode */
optionP:
	polish = 1;
	continue;
      }
      if (cOpt == 'q') {	/* -q = Quiet mode */
	quiet = 1;
	continue;
      }
      if (cOpt == 's') {	/* -s = Display sunrise & sunset information */
optionS:
	sunrise = 1;
	continue;
      }
      if ((cOpt == 'w') && ((i+1)<argc)) { /* -w = Set output width */
      	lineWidth = atoi(argv[++i]);
	if ((lineWidth <= 0) || (lineWidth > MAXLINEWIDTH)) lineWidth = MAXLINEWIDTH;
	continue;
      }
      if ((cOpt == 'x') || (!opt[0])) { /* - = Process data from stdin */
optionX:
	while (!getLine()) {	/* Read and print times */
	  dotexttime(line);
	}
	return 0;
      }
      fprintf(stderr, "Unexpected option: %s\n", arg);
      return 1;
    }
    /* Else this is an argument */
    /* First, for compatibility, look at legacy options without an initial - */
    if (cArg == 'p') goto optionP;
    if (cArg == 's') goto optionS;
    if (cArg == 'x') goto optionX;  /* "today x" is needed for vms. */
    /* Else this is supposed to be a date. Process it */
    if (dotexttime(arg) == 0) return 0;
  }

  /*
   * Here if no parameters or an error in the parameter field.
   */
  dotime();			/* Print the time.              */

#ifdef	UNIX
  if (!quiet) {
    output("\n");           	/* Space before cookie          */
    execl(COOKIEPROGRAM, "cookie", 0);
  }
#endif
  return 0;
}

void dotime()
/*
 * Print the time of day for Unix or VMS native mode.
 */
{
  time_t  tvec;                   /* Buffer for time function     */
  struct  tm *localtime();	/* Unix time decompile function */
  struct  tm *p;			/* Local pointer to time of day */
  int     year;
  int     month;

  if (debug) printf("dotime();\n");

  time(&tvec);                     /* Get the time of day          */
  p = localtime(&tvec);           /* Make it more understandable  */
  year = p->tm_year + 1900;
  month = p->tm_mon + 1;

#ifdef	APRIL_FOOLS
  if (month == 4 && p->tm_mday == 1)
    polish = !polish;
#endif

  process(year, month, p->tm_mday, p->tm_hour,
	  p->tm_min, p->tm_sec, p->tm_isdst);
}

int dotexttime(text)
char    *text;                          /* Time text                    */
/*
 * Create the time values and print them, return 1 on error.
 */

{
  int     epoch;                  /* Which century                */
  int     year;
  int     month;
  int     day;
  int     hour;
  int     minute;
  int     second;
  int     leapyear;
  int     hasCentury = 0;

  if (debug) printf("dotexttime(\"%s\");\n", text);

  valptr = text;                          /* Setup for getval()   */
  while (*valptr == ' ') valptr++;        /* Leading blanks skip  */
  if (*valptr == '+') {
    valptr++;
    hasCentury = 1;
  } else if ((strlen(valptr) > 4) && (valptr[4] == '-')) {
    hasCentury = 1;
  }
  if (!hasCentury) {
    epoch = 1900;                   /* Default for now      */
  } else {
    if ((epoch = getval(-1, 00, 99)) < 0) goto bad;
    epoch *= 100;		/* Make it a real epoch */
  }

  if ((year = getval(-1, 00, 99)) < 0) goto bad;
  if ((!hasCentury) && (year < 70)) epoch = 2000;
  year += epoch;
  leapyear = ((year%4) == 0) && (((year%400) == 0) || (year%100 != 0));
  if (*valptr == '-') valptr++;
  if ((month = getval(-1, 1, 12)) < 0) goto bad;
  if (*valptr == '-') valptr++;
  if ((day = getval(-1, 1,
		    (month == 2 && leapyear) ? 29 : day_month[month])) < 0)
    goto bad;
  while ((*valptr == 'T') || (*valptr == ' ') || (*valptr == '\t')) valptr++;
  if ((hour = getval(-2, 0, 23)) == -1) goto bad;
  while ((*valptr == 'H') || (*valptr == 'h') || (*valptr == ':')) valptr++;
  if ((minute = getval(-2, 0, 59)) == -1) goto bad;
  while ((*valptr == 'M') || (*valptr == 'm') || (*valptr == ':')) valptr++;
  if ((second = getval(-2, 0, 59)) == -1) goto bad;
  process(year, month, day, hour, minute, second, 0);
  return(0);				/* Normal exit		*/

 bad:    output("Bad parameters or date out of range in \"");
  output(text);
  output("\" after scanning \"");
  *valptr = '\0';
  output(text);
  output("\".\n");
  return(1);				/* Error exit		*/
}

void process(year, month, day, hour, minute, second, daylight)
int     year;                           /* Year		1900 = 1900	*/
int     month;                          /* Month	January = 1	*/
int     day;                            /* Day		1 = 1		*/
int	hour;				/* Hour		0 .. 23		*/
int	minute;				/* Minute	0 .. 59		*/
int	second;				/* Second	0 .. 59		*/
int	daylight;			/* Daylight savings time if 1	*/
/*
 * Output the information.  Note that the parameters are within range.
 */
{
  char szDateTime[32];
  char *pszIntroduction;
  time_t sec_1970;
  struct tm *pt;

  if (debug) printf("process(%d, %d, %d, %d, %d, %d, %d);\n", year, month, day, hour, minute, second, daylight);

  time(&sec_1970);
  pt = localtime(&sec_1970);
  if (debug) printf("pt = {%d, %d, %d, %d, %d, %d, %d);\n", pt->tm_year, pt->tm_mon, pt->tm_mday, pt->tm_hour, pt->tm_min, pt->tm_sec, pt->tm_isdst);
  if ((pt->tm_year + 1900) == year && (pt->tm_mon + 1) == month && pt->tm_mday == day) {
    pszIntroduction = "Today is ";
  } else {
    sprintf(szDateTime, "%04d-%02d-%02d is ", year, month, day);
    pszIntroduction = szDateTime;
  }
  if (!quiet) output(pszIntroduction);
  datetxt(outline, year, month, day);
  output(outline);
  output(".\n");
  if (quiet) return;
  timetxt(outline, hour, minute, second,
	  (polish) ? 0101010 : daylight);
  output(outline);
  if (hour >= 0 || minute >= 0 || second >= 0) output(".\n");
  if (sunrise) {
    int sunrh, sunrm, sunsh, sunsm;
    sprintf(szDateTime, "%04d-%02d-%02dT%02d:%02d:%02d", year, month, day, hour, minute, second);
    sun(&sunrh, &sunrm, &sunsh, &sunsm, szDateTime);
    output("Sunrise is at ");
    timetxt(outline, sunrh, sunrm, -2, -1);
    output(outline);
    output(".\nSunset is at ");
    timetxt(outline, sunsh, sunsm, -2, -1);
    output(outline);
    output(".\n");
  }
  if (moon) {
    moontxt(outline);	/* replaced by smarter version */
    output(outline);
    output(".\n");
  }
}

void output(text)
char    *text;                                  /* What to print        */
/*
 * Output routine.  Text is output using put() so that lines are
 * not more than LINEWIDTH bytes long.  Current position is in global ccpos.
 * (put is equivalent to putchar() except that it is locally buffered.)
 */
{
  register char	*in;		/* Current pos. in scan */
  register char	c;		/* Current character    */
  register char	*wp;		/* Word pointer		*/

  in = text;
  while ((c = *in++) != '\0') {
    switch (c) {
    case '\n':			/* Force new line       */
    case ' ':			/* or a space seen      */
      if ((wordptr-wordbuffer) + ccpos >= lineWidth) {
	put('\n');		/* Current word         */
	ccpos = 0;		/* won't fit, dump it.  */
      }
      if (wordptr > wordbuffer) {
	if (ccpos) {		/* Leading space needed */
	  put(' ');
	  ccpos++;
	}
	for (wp = wordbuffer; wp < wordptr;) {
	  put(*wp++);
	}
	ccpos += (int)(wordptr - wordbuffer);
	wordptr = wordbuffer;	/* Empty buffer	*/
      }
      if (c == '\n') {
	put('\n');		/* Print a newline	*/
	ccpos = 0;		/* and reset the cursor	*/
      }
      break;

    default:
      *wordptr++ = c;		/* Save piece of word   */
    }
  }
}

void put(c)
register char	c;
/*
 * Actual output routine
 */
{
  if (c == '\n' || (lineptr - linebuffer) >= lineWidth) {
    *lineptr = EOS;
    puts(linebuffer);
    lineptr = linebuffer;
    if (c == '\n')
      return;
  }
  *lineptr++ = c;
}

int getLine()
/*
 * Read text to global line[].  Return 1 on end of file, zero on ok.
 */
{
  char *p;

  /* slightly safer handling of gets */
  /* '\n' line is not an empty line  */
  /* EOF should be an empty line     */
  if (fgets(line, sizeof(line), stdin) == NULL) {
    return(1);
  }

  if ((p = strchr(line, '\n')) != NULL) {
    *p = '\0';
  }

  return(0);

}

int getval(flag, low, high)
int     flag;
int     low;
int     high;
/*
 * Global valptr points to a 2-digit positive decimal integer.
 * Skip over leading non-numbers and return the value.
 * Return flag if text[0] == '\0'. Return -1 if the text is bad,
 * or if the value is out of the low:high range.
 */
{
  register int value;
  register int i;
  register int temp;

  while (*valptr == ' ' || *valptr == '\t') valptr++; /* Skip leading spaces */
  if (*valptr == '\0') return(flag);        /* Default?             */
  while (*valptr && (*valptr < '0' || *valptr > '9')) valptr++;
  /* The above allows for 78.04.22 format */
  for (value = i = 0; i < 2; i++) {
    temp = *valptr++ - '0';
    if (temp < 0 || temp > 9) return(-1);
    value = (value*10) + temp;
  }
  return((value >= low && value <= high) ? value : -1);
}

