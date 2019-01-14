/***** hpfcla:net.sources / nsc-pdc!rgb / 10:24 am  May 16, 1985
*
*        sun <options>
*
*        options:        -t hh:mm:ss	time (default is current system time)
*			 -d mm/dd/yy	date (default is current system date)
*                        -a lat		decimal latitude (default = 45.5333)
*                        -o lon		decimal longitude (default = 122.8333) 
*			 -z tz		timezone (default = 8, pst)
*			 -p		show position of sun (azimuth)
*			 -v		turn on debugging
*        
*        All output is to standard io.  
*
*	 Compile with cc -O -o sun sun.c -lm
*	 Non 4.2 systems may have to change <sys/time.h> to <time.h> below.
*	(yes, done)
*
*	 Note that the latitude, longitude, time zone correction and
*	 time zone string are all defaulted in the global variable section.
*
*	 Most of the code in this program is adapted from algorithms
*	 presented in "Practical Astronomy With Your Calculator" by
*	 Peter Duffet-Smith.
*
*	 The GST and ALT-AZIMUTH algorithms are from Sky and Telescope,
*	 June, 1984 by Roger W. Sinnott
*
*	 Author Robert Bond - Beaverton Oregon.
*		Neil Cherry
*		Jean-Francois Larvoire - Saint Hilaire, France
*
*   History:
*    2009-12-23 NC  Changed constants to Fort Collins, Colorado.  (ajs, 850520)
*		    Made other minor output format improvements also.
*    2019-01-11 JFL Added optional argument pszDate to routine sun().
*		    Include stptime.c when building with Microsoft tools.
*/

#include <stdio.h>
#include <math.h>
#include <sys/types.h>
#include <time.h>
#include <stdlib.h>

#include "params.h"
#include "today.h"

#ifndef PI
#define PI       3.141592654
#endif

#define EPOCH	 1980
#define JDE	 2444238.5	/* Julian date of EPOCH */

/* Forward references to local routines */
/* void sun(int *sunrh, int *sunrm, int *sunsh, int *sunsm); // Defined in today.h */
double rtod(double deg);
double adj360(double deg);
double adj24(double hrs);
double julian_date(int m, int d, int y);
double hms_to_dh(int h, int m, int s);
double solar_lon(double ed);
double acos_deg(double x);
double asin_deg(double x);
double atan_q_deg(double y, double x);
double atan_deg(double x);
double sin_deg(double x);
double cos_deg(double x);
double tan_deg(double x);
void lon_to_eq(double lambda, double *alpha, double *delta);
void rise_set(double alpha, double delta, double *lstr, double *lsts, double *ar, double *as);
void lst_to_hm(double lst, double jd, int *h, int *m);
void dh_to_hm(double dh, int *h, int *m);
void eq_to_altaz(double r, double d, double t, double *alt, double *az);
double gmst(double j, double f);

struct tm *localtime();

int th;
int tm;
int ts;
int mo;
int day;
int yr;

int tz = TZ;			/* Default time zone */
char *tzs  = TZS;		/* Default time zone string */
char *dtzs = DTZS;		/* Default daylight savings time string */

double lat = LAT;		/* Default latitude */
double lon = LON;		/* Default Longitude */ 

int popt = 0;

void sun(sunrh, sunrm, sunsh, sunsm, pt)
int *sunrh, *sunrm, *sunsh, *sunsm;
struct tm *pt;
{
    double ed, jd;
    double alpha1, delta1, alpha2, delta2, st1r, st1s, st2r, st2s;
    double a1r, a1s, a2r, a2s, dt, dh, x, y;
    double trise, tset, ar, as, alpha, delta, tri, da;
    double lambda1, lambda2;
    double alt, az, gst, m1;
    double hsm, ratio;
    int h, m;
    
    if (debug) printf("sun(%p, %p, %p, %p, %p);\n",
      			sunrh, sunrm, sunsh, sunsm, pt);

    if (!pt) {	/* If we were given no date, use now */
	time_t sec_1970;	/* used by time calls */
	time(&sec_1970);	/* get system time */
	pt = gmtime(&sec_1970);	/* get ptr to gmt time struct */
    }
    if (debug) printf("pt = {%d, %d, %d, %d, %d, %d, %d);\n", pt->tm_year, pt->tm_mon, pt->tm_mday, pt->tm_hour, pt->tm_min, pt->tm_sec, pt->tm_isdst);

    th = pt->tm_hour;
    tm = pt->tm_min;
    ts = pt->tm_sec;
    yr = pt->tm_year + 1900;
    mo = pt->tm_mon + 1;
    day = pt->tm_mday;
    if (pt->tm_isdst) {		/* convert tz to daylight savings time */
	tz--;
	tzs = dtzs;	
    }

    if (debug)
        printf("Date: %d/%d/%d,  Time: %d:%d:%d, Tz: %d, Lat: %lf, Lon: %lf \n",
	    mo,day,yr,th,tm,ts,tz,lat,lon);

    jd = julian_date(mo,day,yr);
    ed = jd - JDE;

    lambda1 = solar_lon(ed);
    lambda2 = solar_lon(ed + 1.0);

    lon_to_eq(lambda1, &alpha1, &delta1);
    lon_to_eq(lambda2, &alpha2, &delta2);

    rise_set(alpha1, delta1, &st1r, &st1s, &a1r, &a1s);
    rise_set(alpha2, delta2, &st2r, &st2s, &a2r, &a2s);

    m1 = adj24(gmst(jd - 0.5, 0.5 + tz / 24.0) - lon / 15); /* lst midnight */

    if (debug)
	printf ("local sidereal time of midnight is %lf \n", m1);

    hsm = adj24(st1r - m1);

    if (debug)
	printf ("about %lf hours from midnight to dawn \n", hsm);

    ratio = hsm / 24.07;

    if (debug)
	printf("%lf is how far dawn is into the day \n", ratio);

    if (fabs(st2r - st1r) > 1.0) {
	st2r += 24.0;
	if (debug)
	    printf("st2r corrected from %lf to %lf \n", st2r-24.0, st2r);
    }

    trise = adj24((1.0 - ratio) * st1r + ratio * st2r);

    hsm = adj24(st1s - m1);

    if (debug)
	printf ("about %lf hours from midnight to sunset \n", hsm);

    ratio = hsm / 24.07;

    if (debug)
	printf("%lf is how far sunset is into the day \n", ratio);

    if (fabs(st2s - st1s) > 1.0) {
	st2s += 24.0;
	if (debug)
	    printf("st2s corrected from %lf to %lf \n", st2s-24.0, st2s);
    }

    tset = adj24((1.0 - ratio) * st1s + ratio * st2s);

    if (debug)
	printf("Uncorrected rise = %lf, set = %lf \n", trise, tset);

    ar = a1r * 360.0 / (360.0 + a1r - a2r);
    as = a1s * 360.0 / (360.0 + a1s - a2s);

    delta = (delta1 + delta2) / 2.0;
    tri = acos_deg(sin_deg(lat)/cos_deg(delta));

    x = 0.835608;		/* correction for refraction, parallax, ? */
    y = asin_deg(sin_deg(x)/sin_deg(tri));
    da = asin_deg(tan_deg(x)/tan_deg(tri));
    dt = 240.0 * y / cos_deg(delta) / 3600;

    if (debug)
	printf("Corrections: dt = %lf, da = %lf \n", dt, da);

    lst_to_hm(trise - dt, jd, &h, &m);
    *sunrh = h;
    *sunrm = m;

    if (popt) {
        dh_to_hm(ar - da, &h, &m);
        printf("Azimuth: %3d %02d'\n", h, m);
    }

    lst_to_hm(tset + dt, jd, &h, &m);
    *sunsh = h;
    *sunsm = m;

    if (popt) {
        dh_to_hm(as + da, &h, &m);
        printf("Azimuth: %3d %02d'\n", h, m);
    } 
     

    if (popt) {

	if (alpha1 < alpha2)
	    alpha = (alpha1 + alpha2) / 2.0;
	else
	    alpha = (alpha1 + 24.0 + alpha2) / 2.0;
	
	if (alpha > 24.0)
	    alpha -= 24.0;

	dh = (hms_to_dh(th, tm, ts) + tz) / 24.0;
	if (dh > 0.5) {
	    dh -= 0.5;
	    jd += 0.5;
	} else {
	    dh += 0.5;
	    jd -= 0.5;
	}

	gst = gmst(jd, dh);

	eq_to_altaz(alpha, delta, gst, &alt, &az);

	printf	 ("The sun is at:   ");
	dh_to_hm (az, &h, &m);
	printf	 ("Azimuth: %3d %02d'  ", h, m);
	dh_to_hm (alt, &h, &m);
	printf	 ("Altitude: %3d %02d'\n", h, m);
    }
}

#if defined(_MSC_VER) && (_MSC_VER < 1400)
/* The MSVC 1.5 register optimizer chokes on the routine below!
   Microsoft docs report a similar bug for VS 2003 = _MSC_VER 1310 */
#pragma optimize("e", off)
#endif

double
rtod(deg)
double deg;
{
    return (deg * 180.0 / PI);
}


double 
adj360(deg)
double deg;
{
    while (deg < 0.0) 
	deg += 360.0;
    while (deg > 360.0)
	deg -= 360.0;
    return(deg);
}

double 
adj24(hrs)
double hrs;
{
    while (hrs < 0.0) 
	hrs += 24.0;
    while (hrs > 24.0)
	hrs -= 24.0;
    return(hrs);
}

double 
julian_date(m, d, y) int m, d, y;
{
    long a, b;
    double jd;

    if (m == 1 || m == 2) {
	--y;
	m += 12;
    }
    if (y < 1583) {
	fprintf(stderr, "Can't handle dates before 1583\n");
	exit(1);
    }
    a = (long)y/100;
    b = 2 - a + a/4;
    b += (long)((double)y * 365.25);
    b += (long)(30.6001 * ((double)m + 1.0));
    jd = (double)d + (double)b + 1720994.5;

    if (debug) 
	printf("Julian date for %d/%d/%d is %lf \n", m, d, y, jd);

    return(jd);
}

double 
hms_to_dh(h, m, s) int h, m, s;
{
    double rv;
    rv = h + m / 60.0 + s / 3600.0;

    if (debug)
	printf("For time %d:%d:%d frac hours are: %lf \n", h, m, s, rv);

    return rv;
}

double 
solar_lon(ed)
double ed;
{
    double n, m, e, ect, errt, v;

    n = 360.0 * ed / 365.2422;
    n = adj360(n);
    m = n + 278.83354 - 282.596403;
    m = adj360(m);
    m = dtor(m);
    e = m; ect = 0.016718;
    while ((errt = e - ect * sin(e) - m) > 0.0000001) 
        e = e - errt / (1 - ect * cos(e));
    v = 2 * atan(1.0168601 * tan(e/2));
    v = adj360(v * 180.0 / PI + 282.596403);

    if (debug)
	printf("Solar Longitude for %lf days is %lf \n", ed, v); 

    return(v);
}

double 
acos_deg(x)
double x;
{
    return rtod(acos(x));
}

double 
asin_deg(x)
double x;
{
    return rtod(asin(x));
}

double 
atan_q_deg(y,x)
double y,x;
{
    double rv;

    if (y == 0)
        rv = 0;
    else if (x == 0)
        rv = y>0 ? 90.0 : -90.0;
    else rv = atan_deg(y/x);

    if (x<0) return rv+180.0;
    if (y<0) return rv+360.0;
    return(rv);
}

double
atan_deg(x)
double x;
{
    return rtod(atan(x));
}

double 
sin_deg(x)
double x;
{
    return sin(dtor(x));
}

double 
cos_deg(x)
double x;
{
    return cos(dtor(x));
}

double 
tan_deg(x)
double x;
{
    return tan(dtor(x));
}

void lon_to_eq(lambda, alpha, delta)
double lambda;
double *alpha;
double *delta;
{
    double tlam,epsilon;

    tlam = dtor(lambda);
    epsilon = dtor((double)23.441884);
    *alpha = atan_q_deg((sin(tlam))*cos(epsilon),cos(tlam)) / 15.0;
    *delta = asin_deg(sin(epsilon)*sin(tlam));

    if (debug)
	printf("Right ascension, declination for lon %lf is %lf, %lf \n",
	    lambda, *alpha, *delta);
}

void rise_set(alpha, delta, lstr, lsts, ar, as)
double alpha, delta, *lstr, *lsts, *ar, *as;
{
    double tar;
    double h;

    tar = sin_deg(delta)/cos_deg(lat);
    if (tar < -1.0 || tar > 1.0) {
	fprintf(stderr, "The object is circumpolar\n");
	exit (1);
    }
    *ar = acos_deg(tar);
    *as = 360.0 - *ar;

    h = acos_deg(-tan_deg(lat) * tan_deg(delta)) / 15.0;
    *lstr = 24.0 + alpha - h;
    if (*lstr > 24.0)
	*lstr -= 24.0;
    *lsts = alpha + h;
    if (*lsts > 24.0)
	*lsts -= 24.0;

    if (debug) {
	printf("For ra, decl. of %lf, %lf: \n", alpha, delta);
	printf("lstr = %lf, lsts = %lf, \n", *lstr, *lsts);
	printf("ar =   %lf, as =   %lf \n", *ar, *as);
    }
}

void lst_to_hm(lst, jd, h, m)
double lst, jd;
int *h, *m;
{
    double ed, gst, jzjd, t, r, b, t0, gmt;

    gst = lst + lon / 15.0;
    if (gst > 24.0)
	gst -= 24.0;
    jzjd = julian_date(1,0,yr);
    ed = jd-jzjd;
    t = (jzjd -2415020.0)/36525.0;
    r = 6.6460656+2400.05126*t+2.58E-05*t*t;
    b = 24.0-(r-24.0*(yr-1900));
    t0 = ed * 0.0657098 - b;
    if (t0 < 0.0)
	t0 += 24;
    gmt = gst-t0;
    if (gmt<0) 
	gmt += 24.0;
    gmt = gmt * 0.99727 - tz;;
    if (gmt < 0)
	gmt +=24.0;
    dh_to_hm(gmt, h, m);
}

void dh_to_hm(dh, h, m)
double dh;
int *h, *m;
{
    double tempsec;

    *h = (int)dh;
 /* *m = (dh - *h) * 60; 
    tempsec = (dh - *h) * 60 - *m; */
    *m = (int)(fmod(dh, 1.0) * 60.0); 
    tempsec = fmod(dh, 1.0) * 60.0 - *m;
    tempsec = tempsec * 60 + 0.5;
    if (tempsec > 30.0)
	(*m)++;
    if (*m == 60) {
	*m = 0;
	(*h)++;
    }
}

void eq_to_altaz(r, d, t, alt, az)
double r, d, t;
double *alt, *az;
{
    double p = 3.14159265;
    double r1 = p / 180.0;
    double b = lat * r1;
    double l = (360 - lon) * r1;
    double t5, s1, c1, c2, s2, a, h;

    if (debug)
	printf("Given R. A. = %lf, DECL. = %lf, gmt = %lf \n", r, d, t);

    r = r * 15.0 * r1;
    d = d * r1;
    t = t * 15.0 * r1;
    t5 = t - r + l;
    s1 = sin(b) * sin(d) + cos(b) * cos(d) * cos(t5);
    c1 = 1 - s1 * s1;
    if (c1 > 0) {
	c1 = sqrt(c1);
	h = atan(s1 / c1);
    } else {
	h = (s1 / fabs(s1)) * (p / 2.0);
    }
    c2 = cos(b) * sin(d) - sin(b) * cos(d) * cos(t5);
    s2 = -cos(d) * sin(t5);
    if (c2 == 0) 
	a = (s2/fabs(s2)) * (p/2);
    else {
	a = atan(s2/c2);
	if (c2 < 0)
	    a=a+p;
    }
    if (a<0)
        a=a+2*p;
    *alt = h / r1;
    *az = a / r1;

    if (debug)
	printf("alt = %lf, az = %lf \n",*alt,*az);
}

double
gmst(j, f)
double j,f;
{
    double d, j0, t, t1, t2, s;

    d = j - 2451545.0;
    t = d / 36525.0;
    t1 = floor(t);
    j0 = t1 * 36525.0 + 2451545.0;
    t2 = (j - j0 + 0.5)/36525.0;
    s = 24110.54841 + 184.812866 * t1; 
    s += 8640184.812866 * t2;
    s += 0.093104 * t * t;
    s -= 0.0000062 * t * t * t;
    s /= 86400.0;
    s -= floor(s);
    s = 24 * (s + (f - 0.5) * 1.002737909);
    if (s < 0)
	s += 24.0;
    if (s > 24.0)
	s -= 24.0;

    if (debug)
	printf("For jd = %lf, f = %lf, gst = %lf \n", j, f, s);

    return(s);
}

