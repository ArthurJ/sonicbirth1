/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
static inline float interpolate_float_no(float idx, float *buf, int size) __attribute__ ((always_inline));
static inline float interpolate_float_no(float idx, float *buf, int size)
{
	int i = idx;
	while (i >= size) i -= size; while (i < 0) i += size;
	return buf[i];
}

static inline float interpolate_float_lin(float idx, float *buf, int size) __attribute__ ((always_inline));
static inline float interpolate_float_lin(float idx, float *buf, int size)
{
	float flo = floorf(idx);
	int bef = flo, aft = ceilf(idx);
	if (bef == aft)
	{
		while (bef >= size) bef -= size; while (bef < 0) bef += size;
		return buf[bef];
	}
	while (bef >= size) bef -= size; while (bef < 0) bef += size;
	while (aft >= size) aft -= size; while (aft < 0) aft += size;
	float ratioAft = idx - flo, ratioBef = 1.f - ratioAft;
	return ratioBef * buf[bef] + ratioAft * buf[aft];
}

static inline double interpolate_double_no(double idx, double *buf, int size) __attribute__ ((always_inline));
static inline double interpolate_double_no(double idx, double *buf, int size)
{
	int i = idx;
	while (i >= size) i -= size; while (i < 0) i += size;
	return buf[i];
}

static inline double interpolate_double_lin(double idx, double *buf, int size) __attribute__ ((always_inline));
static inline double interpolate_double_lin(double idx, double *buf, int size)
{
	double flo = floor(idx);
	int bef = flo, aft = ceil(idx);
	if (bef == aft)
	{
		while (bef >= size) bef -= size; while (bef < 0) bef += size;
		return buf[bef];
	}
	while (bef >= size) bef -= size; while (bef < 0) bef += size;
	while (aft >= size) aft -= size; while (aft < 0) aft += size;
	double ratioAft = idx - flo, ratioBef = 1. - ratioAft;
	return ratioBef * buf[bef] + ratioAft * buf[aft];
}
