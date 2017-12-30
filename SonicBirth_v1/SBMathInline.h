/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#ifndef SBMATHINLINE_H
#define SBMATHINLINE_H

// begin taken from Libm-47.1

#define __fmax(x, y) \
({ \
    double __value, __argx = (x), __argy = (y); \
    asm volatile ( \
        "fcmpu 		cr0,%1,%2 ; 	/* Compare unordered */ 				\n \
         blt		cr0, 0f ; 	/* Order discerned? Then we have our answer */ 		\n \
         bnu+		cr0, 1f ; 	/* Opposite order discerned? Then we have our answer */ \n \
         fcmpu 		cr1,%2,%2 ; 	/* x, y or both are NAN. Is y NAN? */			\n \
         bun-		cr1, 1f ; 	/* If so, x is our answer */ 				\n \
    0:	 fmr		%0, %2; 	/* Else y is our answer */ 				\n \
         b		2f									\n \
    1:	 fmr		%0,%1;									\n \
    2:												\n \
        ": "=f"(__value) : "f" (__argx), "f" (__argy)); \
    __value; \
})

#define __fmaxf(x, y) \
({ \
    float __value, __argx = (x), __argy = (y); \
    asm volatile ( \
        "fcmpu 		cr0,%1,%2 ; 	/* Compare unordered */ 				\n \
         blt		cr0, 0f ; 	/* Order discerned? Then we have our answer */ 		\n \
         bnu+		cr0, 1f ; 	/* Opposite order discerned? Then we have our answer */ \n \
         fcmpu 		cr1,%2,%2 ; 	/* x, y or both are NAN. Is y NAN? */			\n \
         bun-		cr1, 1f ; 	/* If so, x is our answer */ 				\n \
    0:	 fmr		%0, %2; 	/* Else y is our answer */ 				\n \
         b		2f									\n \
    1:	 fmr		%0,%1;									\n \
    2:												\n \
        ": "=f"(__value) : "f" (__argx), "f" (__argy)); \
    __value; \
}) 

#define __fmin(x, y) \
({ \
    double __value, __argx = (x), __argy = (y); \
    asm volatile ( \
        "fcmpu 		cr0,%1,%2 ; 	/* Compare unordered */ 				\n \
         bgt		cr0, 0f ; 	/* Order discerned? Then we have our answer */ 		\n \
         bnu+		cr0, 1f ; 	/* Opposite order discerned? Then we have our answer */ \n \
         fcmpu 		cr1,%2,%2 ; 	/* x, y or both are NAN. Is y NAN? */			\n \
         bun-		cr1, 1f ; 	/* If so, x is our answer */ 				\n \
    0:	 fmr		%0, %2; 	/* Else y is our answer */ 				\n \
         b		2f									\n \
    1:	 fmr		%0,%1;									\n \
    2:												\n \
        ": "=f"(__value) : "f" (__argx), "f" (__argy)); \
    __value; \
}) 

#define __fminf(x, y) \
({ \
    float __value, __argx = (x), __argy = (y); \
    asm volatile ( \
        "fcmpu 		cr0,%1,%2 ; 	/* Compare unordered */ 				\n \
         bgt		cr0, 0f ; 	/* Order discerned? Then we have our answer */ 		\n \
         bnu+		cr0, 1f ; 	/* Opposite order discerned? Then we have our answer */ \n \
         fcmpu 		cr1,%2,%2 ; 	/* x, y or both are NAN. Is y NAN? */			\n \
         bun-		cr1, 1f ; 	/* If so, x is our answer */ 				\n \
    0:	 fmr		%0, %2; 	/* Else y is our answer */ 				\n \
         b		2f									\n \
    1:	 fmr		%0,%1;									\n \
    2:												\n \
        ": "=f"(__value) : "f" (__argx), "f" (__argy)); \
    __value; \
})  

#define __fabs(x) \
({ \
    double __value, __arg = (x); \
    asm volatile ("fabs %0,%1" : "=f" (__value): "f" (__arg)); \
    __value; \
})  

#define __fabsf(x) \
({ \
    float __value, __arg = (x); \
    asm volatile ("fabs %0,%1" : "=f" (__value): "f" (__arg)); \
    __value; \
}) 

// end taken from Libm-47.1

#if defined(__ppc__) || defined(__ppc64__)

static inline float sminf(float a, float b) __attribute__ ((always_inline));
static inline float sminf(float a, float b) { return __fminf(a, b); }

static inline double smin(double a, double b) __attribute__ ((always_inline));
static inline double smin(double a, double b) { return __fmin(a, b); }

static inline float smaxf(float a, float b) __attribute__ ((always_inline));
static inline float smaxf(float a, float b) { return __fmaxf(a, b); }

static inline double smax(double a, double b) __attribute__ ((always_inline));
static inline double smax(double a, double b) { return __fmax(a, b); }

static inline float sabsf(float a) __attribute__ ((always_inline));
static inline float sabsf(float a) { return __fabsf(a); }

static inline double sabs(double a) __attribute__ ((always_inline));
static inline double sabs(double a) { return __fabs(a); }

// http://www.psc.edu/general/software/packages/ieee/ieee.html

static inline float signf(float a) __attribute__ ((always_inline));
static inline float signf(float a)
{
	//unsigned int i = *(unsigned int*)(&a);
	union { unsigned int i; float a; } t;
	t.a = a; int i = t.i;
	if (i & 0x7FFFFFFF) return (i & 0x80000000) ? -1.f : 1.f;
	else return 0.f;
}

static inline double sign(double a) __attribute__ ((always_inline));
static inline double sign(double a)
{
	//unsigned int hi = ((unsigned int*)(&a))[0];
	//unsigned int lo = ((unsigned int*)(&a))[1];
	union { struct {unsigned int hi; unsigned int lo;} i; double a; } t;
	t.a = a; int hi = t.i.hi; int lo = t.i.lo;
	if (lo ||(hi & 0x7FFFFFFF)) return (hi & 0x80000000) ? -1. : 1.;
	else return 0.;
}

#elif defined(__i386__) || defined(__x86_64__)

static inline float sminf(float a, float b) __attribute__ ((always_inline));
static inline float sminf(float a, float b) { return fminf(a, b); }

static inline double smin(double a, double b) __attribute__ ((always_inline));
static inline double smin(double a, double b) { return fmin(a, b); }

static inline float smaxf(float a, float b) __attribute__ ((always_inline));
static inline float smaxf(float a, float b) { return fmaxf(a, b); }

static inline double smax(double a, double b) __attribute__ ((always_inline));
static inline double smax(double a, double b) { return fmax(a, b); }

static inline float sabsf(float a) __attribute__ ((always_inline));
static inline float sabsf(float a) { return fabsf(a); }

static inline double sabs(double a) __attribute__ ((always_inline));
static inline double sabs(double a) { return fabs(a); }

static inline float signf(float a) __attribute__ ((always_inline));
static inline float signf(float a)
{
	return (a < 0) ? -1.f : ((a > 0) ? 1.f : 0.f);
}

static inline double sign(double a) __attribute__ ((always_inline));
static inline double sign(double a)
{
	return (a < 0) ? -1. : ((a > 0) ? 1. : 0.);
}

#else
	#error "Unknown Architecture"
#endif


static inline double lin2log(double lin, double min, double max)
{
	if (lin < min) lin = min;
	if (lin > max) lin = max;

	return log(lin - min + 10)/log(10.);
}

static inline double log2lin(double logIn, double min, double max)
{
	double logmin = lin2log(min, min, max);
	double logmax = lin2log(max, min, max);
	
	if (logIn < logmin) logIn = logmin;
	if (logIn > logmax) logIn = logmax;
	
	return pow(10., logIn) + min - 10;
}

#endif /* SBMATHINLINE_H */
