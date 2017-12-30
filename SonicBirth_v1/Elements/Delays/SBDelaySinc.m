/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBDelaySinc.h"

#include <math.h>

#define kWindowCenter (8)
#define kWindowWidth (kWindowCenter * 2)

#define kMaxSamples (100001)
#define kLastDelay (kMaxSamples - 1)

// interpolation can read max (kWindowCenter + 1) backward
// use kWindowWidth to be safe (doesn't cost much)
#define kBufferSize (kMaxSamples + kWindowWidth)
#define kLastSample (kBufferSize - 1)

#define kQuantStep (32)

// kQuantTableSize -> +3 is 1 for center, 2 for extra right
#define kQuantTableSize ((kWindowCenter + 3) * kQuantStep) 

// even index are value
// odd index are diff with next value
// align on cache lines, even better, on a page
static BOOL gTableInited = NO;
static double gTable[kQuantTableSize * 2] __attribute__ ((aligned (4096)));


// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// sinc function
// http://mathworld.wolfram.com/SincFunction.html
// sinc(0) = 1, sinc(x) = sin (pi x) / (pi x)

static double sinc(double x)
{
	if (x != 0.)
	{
		double pi_x = M_PI * x;
		return sin (pi_x) / pi_x;
	}

	return 1.;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// blackman window (w is width - 1, i is sample)
// width should be odd, center is at w/2
// (if width == 13, w = 12, center = 6)
// http://www.mathworks.com/access/helpdesk/help/toolbox/signal/blackman.html
// 0.42 - 0.5 cos (2pi i / w) + 0.08 cos (4pi i/ w)	

static double blackman(double i, double w)
{
	if (i <= 0) return 0.;
	if (i >= w) return 0.;

	return 	  0.42
			- 0.5  * cos ((2. * M_PI) * i / w)
			+ 0.08 * cos ((4. * M_PI) * i / w);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
static inline double blackman_sinc(double x)
{
	return sinc(x) * blackman(x + kWindowCenter, kWindowWidth);
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// see trunc: http://darwinsource.opendarwin.org/10.3/Libm-47/ppc.subproj/rndint.c
static const double gTwoTo52 = 4503599627370496.0;

#define EXTRACT(__val, __ival, __dval)						\
{															\
	__ival = __val;											\
	__dval = ( __val + gTwoTo52 ) - gTwoTo52;				\
	if (__dval > __val)										\
		__dval = __val - __dval + 1.0;						\
	else													\
		__dval = __val - __dval;							\
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// linear interpolated windowed sinc
static inline double windowedSinc(double x)
{
	if (x < 0)
		x *= -kQuantStep;
	else
		x *= kQuantStep;

	int p;
	double fr;
	EXTRACT(x, p, fr)
	
//	printf("x: %.20f p: %i fr: %.20f\n", x, p, fr);
//	assert( p >= 0 && p < kQuantTableSize );

	p <<= 1;
	
	double w = gTable[p];
	double d = gTable[p + 1];
	double r = w + fr * d;
	
	return r;
}


// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
void InitTable()
{
	if (gTableInited) return;
	gTableInited = YES;
	
	int i;
	//double sum = 0;
	for (i = 0; i < kQuantTableSize; i++)
	{
		double x1 = i / (double)kQuantStep;
		double x2 = (i+1) / (double)kQuantStep;

		double w = blackman_sinc(x1);
		double d = blackman_sinc(x2) - w;
		
		//sum += w;
		
		gTable[i * 2] = w;
		gTable[i * 2 + 1] = d;
	}
	
	//printf("sum: %f\n", sum);
	
	//double ratio = 0.5 / sum;
	//for (i = 0; i < (kQuantTableSize*2); i++)
	//	gTable[i] *= ratio;
	
	/*
	// testing:
	double t;
	for (t = 0; t <= kWindowCenter + 1.5; t += 0.01)
	{
		printf("t: %f d: %f\n",
				t, windowedSinc(t));
	}
	*/
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - -
// if delay is increasing (playing slower)
// sinc is used as is
// if delay is decreasing (playing faster)
// sinc must be adjusted to lowpass extra freq.
static void privateCalcFunc(void *inObj, int count, int offset)
{
	if (!count) return;
	
	SBDelaySinc *obj = inObj;
	int pos = obj->mPos;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *d = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float *b = obj->mBuffer.floatData;
		double prevDelay = obj->mPrevDelay;
		
		while(count--)
		{
			// save incoming sample
			b[pos] = *i++;
			
			// load, clamp and round delay
			double delay = (*d++ + 0.5);

			if (delay < kWindowCenter)
				delay = kWindowCenter;
			else if (delay > kLastDelay)
				delay = kLastDelay;
			
			int delayInt;
			double delayFrac;
			EXTRACT(delay, delayInt, delayFrac)

			// apply windowed sync
			double v = 0, j; int k;
			
			if (delay >= prevDelay)
			{
				for (k = -(kWindowCenter - 1), j = -(kWindowCenter - 1); k < kWindowCenter; k++, j += 1.)
				{
					// calculate integer offset
					int off = k - delayInt;
				
					// read sample
					int rp = pos + off;
					if (rp < 0) rp += kMaxSamples;
					double sp = b[rp];
					
					// apply window with float offset, ie
					// k = -2, delay = 1.3, delayInt = 1, off = -3, - (off + delay) = 1.7
					// since it is symetric, no need to negate
					v += sp * windowedSinc(j + delayFrac);
				}
			}
			else // prevDelay > delay
			{
				double deltaDelay = (prevDelay - delay) + 1;	// > 1
				double ratio = 1 / deltaDelay;					// < 0
				for (k = -(kWindowCenter - 1), j = -(kWindowCenter - 1); k < kWindowCenter; k++, j += 1.)
				{
					int off = k - delayInt;

					int rp = pos + off;
					if (rp < 0) rp += kMaxSamples;
					double sp = b[rp];

					v += sp * windowedSinc( (j + delayFrac) * ratio );
				}
				v *= ratio;
			}

			*o++ = v;
			
			pos++;
			if (pos >= kMaxSamples) pos = 0;
			
			prevDelay = delay;
		}
		
		obj->mPrevDelay = prevDelay;
	}
	else
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *d = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double *b = obj->mBuffer.doubleData;
		double prevDelay = obj->mPrevDelay;
		
		while(count--)
		{
			// save incoming sample
			b[pos] = *i++;
			
			// load, clamp and round delay
			double delay = (*d++ + 0.5);

			if (delay < kWindowCenter)
				delay = kWindowCenter;
			else if (delay > kLastDelay)
				delay = kLastDelay;
			
			int delayInt;
			double delayFrac;
			EXTRACT(delay, delayInt, delayFrac)

			// apply windowed sync
			double v = 0, j; int k;
			
			if (delay >= prevDelay)
			{
				for (k = -(kWindowCenter - 1), j = -(kWindowCenter - 1); k < kWindowCenter; k++, j += 1.)
				{
					int off = k - delayInt;
				
					int rp = pos + off;
					if (rp < 0) rp += kMaxSamples;
					double sp = b[rp];

					v += sp * windowedSinc(j + delayFrac);
				}
			}
			else // prevDelay > delay
			{
				double deltaDelay = (prevDelay - delay) + 1; // > 1
				double ratio = 1 / deltaDelay;				// < 0
				for (k = -(kWindowCenter - 1), j = -(kWindowCenter - 1); k < kWindowCenter; k++, j += 1.)
				{
					int off = k - delayInt;

					int rp = pos + off;
					if (rp < 0) rp += kMaxSamples;
					double sp = b[rp];

					v += sp * windowedSinc( (j + delayFrac) * ratio );
				}
				v *= ratio;
			}

			*o++ = v;
			
			pos++;
			if (pos >= kMaxSamples) pos = 0;
			
			prevDelay = delay;
		}
		
		obj->mPrevDelay = prevDelay;
	}
	
	obj->mPos = pos;
}

@implementation SBDelaySinc

+ (NSString*) name
{
	return @"Delay Sinc (samples)";
}

- (NSString*) name
{
	return @"dly sinc smp";
}

+ (SBElementCategory) category
{
	return kDelay;
}

- (NSString*) informations
{
	return	[NSString stringWithFormat:@"Delays the input signal by a variable time in samples, using "
										@"%i points Blackman windowed sinc interpolation "
										@"(min delay: %i samples, max delay: %i samples).",
										kWindowWidth, kWindowCenter, kLastDelay];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		InitTable();
	
		mBuffer.ptr = malloc(kBufferSize * sizeof(double));
		if (!mBuffer.ptr)
		{
			[self release];
			return nil;
		}
		
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"dly"];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

- (void) dealloc
{
	if (mBuffer.ptr) free(mBuffer.ptr);
	[super dealloc];
}

- (void) reset
{
	[super reset];
	memset(mBuffer.ptr, 0, kBufferSize * sizeof(double));
	mPos = 0;
	mPrevDelay = 0;
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	int i;
	if (mPrecision == kFloatPrecision)
	{
		// float to double
		for (i = kLastSample; i >= 0; i--)
			mBuffer.doubleData[i] = mBuffer.floatData[i];
	}
	else
	{
		// double to float
		for (i = 0; i < kBufferSize; i++)
			mBuffer.floatData[i] = mBuffer.doubleData[i];
	}
	
	[super changePrecision:precision];
}

@end
