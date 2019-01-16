#include <time.h>

extern int debug;

/* Low level functions */
extern char *nbrtxt(char *buffer, int datum, int ordflag);
extern char *copyst(char *buffer, char *string);
extern char *datetxt(char *buffer, int year, int month, int day);                   /* Date getter        */
extern char *timetxt(char *buffer, int hour, int minute, int second, int daylight); /* Time of day getter */
extern double dtor(double deg);
extern int parsetime(char *text, struct tm *ptm);

/* High level functions */
extern void moontxt(char buf[], struct tm *ptm);                                 /* Phase of the moon getter  */
extern char *moonaa(int nLines, int nCols, int inverse, struct tm *pt);		 /* Moon Ascii Art generator  */
extern void sun(int *sunrh, int *sunrm, int *sunsh, int *sunsm, struct tm *ptm); /* Sunrine and sunset getter */

/* Avoid Microsoft C complaints */ 
#ifdef _MSC_VER
/* Most functions use old-style declarators */ 
#pragma warning(disable:4131)	/* Function uses old-style declarator */
#endif

