/*****************************﻿ :encoding=UTF-8: ﻿*****************************
 moon.c

     Phase of the Moon. Calculates the current phase of the moon.
     Based on routines from `Practical Astronomy with Your Calculator',
        by Duffett-Smith.
     Comments give the section from the book that particular piece
        of code was adapted from.

     -- Keith E. Brandt  VIII 1984

     TO DO:
     Unicode has multiple characters that represent moon phases:
     https://www.unicode.org/charts/beta/nameslist/n_1F300.html
     
      25CB  ○	white circle
      25CF  ●	black circle
      25D0  ◐	circle with left half black
      25D1  ◑	circle with right half black
      263D  ☽	first quarter moon
      263E  ☾	last quarter moon
     
     1F311  🌑	NEW MOON SYMBOL
     1F312  🌒	WAXING CRESCENT MOON SYMBOL
     1F313  🌓	FIRST QUARTER MOON SYMBOL
     1F314  🌔	WAXING GIBBOUS MOON SYMBOL
     1F315  🌕	FULL MOON SYMBOL
     1F316  🌖	WANING GIBBOUS MOON SYMBOL
     1F317  🌗	LAST QUARTER MOON SYMBOL
     1F318  🌘	WANING CRESCENT MOON SYMBOL

     1F319  🌙	CRESCENT MOON
     1F31A  🌚	NEW MOON WITH FACE
     1F31B  🌛	FIRST QUARTER MOON WITH FACE
     1F31C  🌜	LAST QUARTER MOON WITH FACE

     Maybe we could use them?
     
     Or use ASCII art to draw the moon?

 ****************************************************************************/

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <time.h>
#include <math.h>

#include "today.h"
#include "moontx.h"

/* Forward references to local routines */
/* void  moontxt(char buf[]);	// In today.h */
double potm(double days);
/* double dtor(double deg);  	// In today.h */
int ly(int yr);
void ptr_adj360(double *deg);

struct tm *gmtime();

void moontxt(buf, pt)
char	buf[];
struct	tm *pt;  /* ptr to time structure */
{
  char *cp=buf;
  double days;   /* days since EPOCH */
  double phase;  /* percent of lunar surface illuminated */
  double phase2; /* percent of lunar surface illuminated one day later */
  int i = EPOCH;

  if (debug) printf("moontxt(%p, %p);\n", buf, pt);

  if (!pt) {	/* If we were given no date, use now */
    time_t lo;		/* used by time calls */
    time(&lo);          /* get system time */
    pt = gmtime(&lo);   /* get ptr to gmt time struct */
  }
  if (debug) printf("pt = {%d, %d, %d, %d, %d, %d, %d);\n", pt->tm_year, pt->tm_mon, pt->tm_mday, pt->tm_hour, pt->tm_min, pt->tm_sec, pt->tm_isdst);

  /* calculate days since EPOCH */
  days = (pt->tm_yday +1.0) + ((pt->tm_hour + (pt->tm_min / 60.0)
				+ (pt->tm_sec / 3600.0)) / 24.0);
  while (i < pt->tm_year + 1900)
    days = days + 365 + ly(i++);

  phase = potm(days);
  sprintf(cp,"The Moon is ");
  cp += strlen(buf);
  if ((int)(phase + .5) == 100) {
    sprintf(cp,"Full");
  }
  else if ((int)(phase + 0.5) == 0) 
    sprintf(cp,"New");
  else if ((int)(phase + 0.5) == 50)  {
    phase2 = potm(++days);
    if (phase2 > phase)
      sprintf(cp,"at the First Quarter");
    else 
      sprintf(cp,"at the Last Quarter");
  }
  else if ((int)(phase + 0.5) > 50) {
    phase2 = potm(++days);
    if (phase2 > phase)
      sprintf(cp,"Waxing ");
    else 
      sprintf(cp,"Waning ");
    cp = buf + strlen(buf);
    sprintf(cp,"Gibbous (%1.0f%% of Full)", phase);
  }
  else if ((int)(phase + 0.5) < 50) {
    phase2 = potm(++days);
    if (phase2 > phase)
      sprintf(cp,"Waxing ");
    else
      sprintf(cp,"Waning ");
    cp = buf + strlen(buf);
    sprintf(cp,"Crescent (%1.0f%% of Full)", phase);
  }
}

/* Moon ASCII-Art generator */
char *moonaa(nLines, nCols, inverse, pt)
int nLines;
int nCols;
int inverse;
struct	tm *pt;  /* ptr to time structure */
{
  char *buf;
  double days;   /* days since EPOCH */
  double phase;  /* percent of lunar surface illuminated */
  double phase2; /* percent of lunar surface illuminated one day later */
  int i = EPOCH;
  char FourChars[] = " ',#";
  double lineWidth;
  double colWidth;
  int iLine;
  int iCol;
  char *pBuf;
  double x, y;
  double xPlus, xMinus;
  int colorLeft, colorRight;
  double innerRadius, innerSquare;
  double epsilon;
  int iYPixel;

  if (debug) printf("moonaa(%d, %d, %p);\n", nLines, nCols, pt);
  
  if ((!nLines) || (!nCols)) {
    fprintf(stderr, "Error: Ascii Art array sizes can't be 0\n");
    return NULL;
  }
  buf = malloc(nLines * (nCols + 1) + 1);
  if (!buf) {
    fprintf(stderr, "Error: Out of memory\n");
    return NULL;
  }

  if (!pt) {	/* If we were given no date, use now */
    time_t lo;		/* used by time calls */
    time(&lo);          /* get system time */
    pt = gmtime(&lo);   /* get ptr to gmt time struct */
  }
  if (debug) printf("pt = {%d, %d, %d, %d, %d, %d, %d);\n", pt->tm_year, pt->tm_mon, pt->tm_mday, pt->tm_hour, pt->tm_min, pt->tm_sec, pt->tm_isdst);

  /* calculate days since EPOCH */
  days = (pt->tm_yday +1.0) + ((pt->tm_hour + (pt->tm_min / 60.0)
				+ (pt->tm_sec / 3600.0)) / 24.0);
  while (i < pt->tm_year + 1900)
    days = days + 365 + ly(i++);

  phase = potm(days);
  if (debug) printf("The Moon is %d full\n", (int)(phase + 0.5));

  phase2 = potm(days + 0.1);

  phase /= 100;		/* Convert percentage to 1x factor */
  phase2 /= 100;	/* Convert percentage to 1x factor */

  if (phase2 > phase) {
    if (debug) printf("at the First Quarter\n");
    colorLeft = 0;
    colorRight = 1;
    if (phase < 0.5) {	/* The terminator is on the right side */
      xMinus = 0.0;
      xPlus = 1.0 - (2*phase);
    } else {		/* The terminator is on the left side */
      xMinus = -1.0 + (2*phase);
      xPlus = 0.0;
    }
  } else { 
    if (debug) printf("at the Last Quarter\n");
    colorLeft = 1;
    colorRight = 0;
    if (phase < 0.5) {	/* The terminator is on the left side */
      xMinus = 1.0 - (2*phase);
      xPlus = 0.0;
    } else {		/* The terminator is on the right side */
      xMinus = 0.0;
      xPlus = -1.0 + (2*phase);
    }
  }

  if (inverse) {
    colorLeft = !colorLeft;
    colorRight = !colorRight;
  }

  /* Each character is composed of 2 AA pixels, one at the top, one at the bottom.
     The top pixel is bit 0; The bottom pixel is bit 1, in FourChars[] = " ',#"; */
  /* Compute line and column widths, in raw trigonometric units (Circle of radius 1) */
  lineWidth = 2.0 / nLines;
  colWidth = 2.0 / nCols;
  /* We want to leave a 1-pixel circle around, and draw the moon inside */
  i = 2*nLines;
  if (nCols < i) i = nCols;
  innerRadius = ((2.0 / i) * (i-2)) / 2;
  innerSquare = innerRadius * innerRadius;
  /* Prepare loop variables */
  pBuf = buf;
  y = 1.0 - (lineWidth / 4);
  epsilon = 0.000001; /* Avoid overflows with divisions with too tiny divisors */
  for (iLine = 0; iLine < nLines; iLine++) { /* For each output line */
    for (iCol = 0; iCol < nCols; iCol++) pBuf[iCol] = '\0';
    for (iYPixel = 0; iYPixel < 2; iYPixel++) { /* For each pixel within each output line */
      x = -1.0 + (colWidth / 2);
      for (iCol = 0; iCol < nCols; iCol++) { /* Foreach column within each pixel line */
	i = ((x*x + y*y) <= 1.0) ? 1 : 0;	/* Outer circle color */
	if ((x*x + y*y) <= innerSquare) {	/* If we're in the inner circle */
	  double xFactor;
	  int colorIn, colorOut;
	  if (x<0) {		/* Negative x = left half of the moon */
	    xFactor = xMinus;
	    colorIn = colorRight;	/* Inside terminator at right of terminator */
	    colorOut = colorLeft;	/* Outside terminator at left of terminator */
	  } else {		/* Positive x = right half of the moon */
	    xFactor = xPlus;
	    colorIn = colorLeft;	/* Inside terminator at left of terminator */
	    colorOut = colorRight;	/* Outside terminator at right of terminator */
	  }
	  if (xFactor>epsilon) {
	    double X = x/xFactor;
	    if ((X*X + y*y) <= innerSquare) {
	      i = colorIn;		/* We're inside the terminator line */ 
	    } else {
	      i = colorOut;		/* We're outside the terminator line */
	    }
	  } else {			/* The terminator line is on the other side */
	    i = colorOut;
	  }
	}
	pBuf[iCol] |= (char)(i << iYPixel);
	x += colWidth;
      }
      y -= lineWidth / 2;
    }
    for (iCol = 0; iCol < nCols; iCol++) pBuf[iCol] = FourChars[(int)pBuf[iCol]];
    pBuf += nCols;
    *pBuf++ = '\n';
  }
  *pBuf++ = '\0';
  return buf;
}

double potm(days)
double days;
{
  double N;
  double Msol;
  double Ec;
  double LambdaSol;
  double l;
  double Mm;
  double Ev;
  double Ac;
  double A3;
  double Mmprime;
  double A4;
  double lprime;
  double V;
  double ldprime;
  double D;
  double Nm;
  
  N = 360.0 * days / 365.2422;  /* sec 42 #3 */
  ptr_adj360(&N);
  
  Msol = N + EPSILONg - RHOg; /* sec 42 #4 */
  ptr_adj360(&Msol);
  
  Ec = 360.0 / PI * e * sin(dtor(Msol)); /* sec 42 #5 */
  
  LambdaSol = N + Ec + EPSILONg;       /* sec 42 #6 */
  ptr_adj360(&LambdaSol);
  
  l = 13.1763966 * days + lzero;       /* sec 61 #4 */
  ptr_adj360(&l);
  
  Mm = l - (0.1114041 * days) - Pzero; /* sec 61 #5 */
  ptr_adj360(&Mm);
  
  Nm = Nzero - (0.0529539 * days);     /* sec 61 #6 */
  ptr_adj360(&Nm);
  
  Ev = 1.2739 * sin(dtor(2*(l - LambdaSol) - Mm)); /* sec 61 #7 */
  
  Ac = 0.1858 * sin(dtor(Msol));       /* sec 61 #8 */
  A3 = 0.37 * sin(dtor(Msol));
  
  Mmprime = Mm + Ev - Ac - A3;         /* sec 61 #9 */
  
  Ec = 6.2886 * sin(dtor(Mmprime));    /* sec 61 #10 */
  
  A4 = 0.214 * sin(dtor(2.0 * Mmprime)); /* sec 61 #11 */
  
  lprime = l + Ev + Ec - Ac + A4;      /* sec 61 #12 */
  
  V = 0.6583 * sin(dtor(2.0 * (lprime - LambdaSol))); /* sec 61 #13 */
  
  ldprime = lprime + V;                /* sec 61 #14 */
  
  D = ldprime - LambdaSol;             /* sec 63 #2 */
  
  return (50.0 * (1 - cos(dtor(D))));    /* sec 63 #3 */
}

int ly(yr)
int yr;
{
  /* returns 1 if leapyear, 0 otherwise */
  return ((yr % 4 == 0 && yr % 100 != 0) || yr % 400 == 0);
}

double dtor(deg)
double deg;
{
  /* convert degrees to radians */
  return (deg * PI / 180.0);
}

void ptr_adj360(deg)
double *deg;
{
  /* adjust value so 0 <= deg <= 360 */
  do if (*deg < 0.0)
    *deg += 360.0;
  else if (*deg > 360.0)
    *deg -= 360.0;
  while (*deg < 0.0 || *deg > 360.0);
}

