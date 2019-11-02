/*
 * parsetime.c
 *
 * Parse a date/time string
 *
 * Changes:
 * 2019-01-11 JFL Updated dotexttime() to support standard ISO dates like 2018-12-25T23:59,
 * 2019-01-13 JFL Moved here the parsing code from routine dotexttime() in today.c.
 *                In case of parsing error, return 1 + the offset of the error.
 *                Added code to fill up a struct tm with the result, including the DST flag for the day.
 * 2019-01-20 JFL Allow entering just the time, in which case use today's date.
 *		  Added support for GMT times, when there's a Z suffix.
 * 2019-11-11 JFL Added support for dates in the ISO 8601 YYYY-DDD format.
 */

#include <stdio.h>
#include <time.h>
#include <string.h>
#include <ctype.h>

#include "today.h"
 
char    *valptr;                        /* Needed for number converter  */
int day_month[] = {			/* Needed for parsetime()      */
	0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31
};

static int getval(int flag, int low, int high);
static int getvalN(int flag, int low, int high, int nDigits);

int parsetime(text, ptm)
char    *text;                          /* Time text                    */
struct tm *ptm;
/*
 * Create the time values and print them, return 1 on error.
 */
{
  int	epoch;                  /* Which century                */
  int	year;
  int	month;
  int	day;
  int	hour;
  int	minute;
  int	second;
  int	leapyear;
  int	hasCentury = 0;
  int	isGMT = 0;
  int	iLen;
  time_t  t;

  if (debug) printf("parsetime(\"%s\");\n", text);

  valptr = text;                          /* Setup for getval()   */
  while (*valptr == ' ') valptr++;        /* Leading blanks skip  */

  iLen = (int)strlen(valptr);
  if (iLen && ((valptr[iLen-1] | 0x20) == 'z')) {
    isGMT = 1;
    valptr[--iLen] = '\0';
  }

  if (*valptr == '+') {
    valptr++;
    hasCentury = 1;
  } else if ((iLen > 4) && (valptr[4] == '-')) {
    hasCentury = 1;
  } else if ((iLen > 2) && ((valptr[2] == ':') || ((valptr[2] | 0x20) == 'h'))) {
    time_t now;
    struct tm *ptmNow;
    time(&now);			/* get system time */
    ptmNow = localtime(&now);	/* get ptr to gmt time struct */
    year = ptmNow->tm_year + 1900;
    month = ptmNow->tm_mon + 1;
    day = ptmNow->tm_mday;
    goto get_time;
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
  if (   valptr[0] && isdigit(valptr[0])
      && valptr[1] && isdigit(valptr[1])
      && valptr[2] && isdigit(valptr[2])
      && (!valptr[3] || !isdigit(valptr[3]))) { /* There are exactly 3 digits, so it's a DDD */
    int m, day_month2[13];
    if ((day = getvalN(-1, 1, leapyear ? 366 : 365, 3)) < 0) goto bad;
    for (m=0; m<=12; m++) day_month2[m] = day_month[m];
    if (leapyear) day_month2[2] = 29;
    for (month=1; month<=12; month++) {
      day_month2[month] += day_month2[month-1];
      if (day_month2[month] >= day) break;
    }
    day -= day_month2[month-1];
  } else { /* It's a MMDD or MM-DD */
    if ((month = getval(-1, 1, 12)) < 0) goto bad;
    if (*valptr == '-') valptr++;
    if ((day = getval(-1, 1,
		      (month == 2 && leapyear) ? 29 : day_month[month])) < 0)
      goto bad;
  }
get_time:
  if ((hour = getval(-2, 0, 23)) == -1) goto bad;
  if ((minute = getval(-2, 0, 59)) == -1) goto bad;
  if ((second = getval(-2, 0, 59)) == -1) goto bad;

  memset(ptm, '\0', sizeof(struct tm));
  ptm->tm_year = year - 1900;
  ptm->tm_mon  = month - 1;
  ptm->tm_mday = day;
  ptm->tm_hour = hour;
  ptm->tm_min = minute;
  ptm->tm_sec = second;
  ptm->tm_isdst = -1; /* Let mktime find out if DST applies or not */
  if (debug) printf("input tm = {%d, %d, %d, %d, %d, %d, %d};\n", ptm->tm_year, ptm->tm_mon, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec, ptm->tm_isdst);

  /* To fill the rest of the structure tm, convert it to a Unix time, and back */
  if (hour < 0) ptm->tm_hour = 12; /* If some of the entries are missing, enter a reasonable default */
  if (minute < 0) ptm->tm_min = 0;
  if (second < 0) ptm->tm_sec = 0;
  t = mktime(ptm);
  if (isGMT) {
    time_t t2 = mktime(gmtime(&t));
    time_t dt = t-t2;
    if (debug) printf("Correcting for GMT offset: %s%lds\n", (((long)dt > 0) ? "+" : ""), (long)dt);
    t += dt; /* Convert t to a local GMT time */
  }
  *ptm = *localtime(&t);
  if (ptm->tm_isdst && isGMT) { /* GMT has no DST, so we must correct for the local time DST */
    if (debug) printf("Correcting for DST offset: +3600s\n");
    t += 3600;
    *ptm = *localtime(&t);
  }
  if (hour < 0) ptm->tm_hour = hour; /* Flag again the missing entries */
  if (minute < 0) ptm->tm_min = minute;
  if (second < 0) ptm->tm_sec = second;
  if (debug) printf("return tm = {%d, %d, %d, %d, %d, %d, %d};\n", ptm->tm_year, ptm->tm_mon, ptm->tm_mday, ptm->tm_hour, ptm->tm_min, ptm->tm_sec, ptm->tm_isdst);

  return(0);				/* Normal exit		*/

 bad:
  return ((int)(valptr - text) + 1);
}

static int getvalN(flag, low, high, n)
int     flag;
int     low;
int     high;
int     n;
/*
 * Global valptr points to a N-digit positive decimal integer.
 * Skip over leading non-numbers and return the value.
 * Return flag if text[0] == '\0'. Return -1 if the text is bad,
 * or if the value is out of the low:high range.
 */
{
  register int value;
  register int i;
  register int temp;

  while (*valptr && (*valptr < '0' || *valptr > '9')) valptr++;
  if (*valptr == '\0') return(flag);        /* Default?             */
  /* The above allows for 78.04.22 format */
  for (value = i = 0; i < n; i++) {
    temp = *valptr++ - '0';
    if (temp < 0 || temp > 9) return(-1);
    value = (value*10) + temp;
  }
  return((value >= low && value <= high) ? value : -1);
}

static int getval(flag, low, high)
int     flag;
int     low;
int     high;
{
  return getvalN(flag, low, high, 2);
}
