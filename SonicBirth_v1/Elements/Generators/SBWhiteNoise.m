/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBWhiteNoise.h"

// http://www.dspguru.com/howto/tech/wgn2.htm
/*
   X=0
   for i = 1 to N
      U = uniform()
      X = X + U
   end
        
   // for uniform randoms in [0,1], mu = 0.5 and var = 1/12
   // adjust X so mu = 0 and var = 1
        
   X = X - N/2                // set mean to 0
   X = X * sqrt(12 / N)       // adjust variance to 1
*/   

#define kRandomMax ((double)(0x7FFFFFFF))
#define kRandomMaxF ((float)(0x7FFFFFFF))

#define N (20)
#define HN (10)				// N / 2
#define VR (0.77459666924)	// sqrt(12 / N)
#define VRf (0.77459666924f)	// sqrt(12 / N)

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBWhiteNoise *obj = inObj;
	if (count <= 0) return;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *wnoise = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			int i;
			float x = (float)random() / kRandomMaxF;
			for (i = 1; i < N; i++) x += (float)random() / kRandomMaxF;
				
			x = x - HN;
			x = x * VRf;
			
			*wnoise++ = x;
		}
	}
	else
	{
		double *wnoise = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			int i;
			double x = (double)random() / kRandomMax;
			for (i = 1; i < N; i++) x += (double)random() / kRandomMax;
				
			x = x - HN;
			x = x * VR;
			
			*wnoise++ = x;
		}
	}
}



/*
static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBWhiteNoise *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *wnoise = obj->mAudioBuffers[0].floatData + offset;
		if (obj->mHasSavedValue)
		{
			*wnoise++ = (float) obj->mSavedValue;
			count--;
			obj->mHasSavedValue = NO;
		}
		while(count > 1)
		{
			float x1, x2, w;
			do
			{
				x1 = (float)random() / kRandomMaxF; x1 = (x1 + x1) - 1.f;
				x2 = (float)random() / kRandomMaxF; x2 = (x2 + x2) - 1.f;
				w = x1 * x1 + x2 * x2;
			} while (w >= 1.0f);
			w = sqrtf( (-2.0f * log10f(w) ) / w );
			*wnoise++ = x1 * w;
			*wnoise++ = x2 * w;
			count -= 2;
		}
		if (count)
		{
			float x1, x2, w;
			do
			{
				x1 = (float)random() / kRandomMaxF; x1 = (x1 + x1) - 1.f;
				x2 = (float)random() / kRandomMaxF; x2 = (x2 + x2) - 1.f;
				w = x1 * x1 + x2 * x2;
			} while (w >= 1.0f);
			w = sqrtf( (-2.0f * log10f(w) ) / w );
			*wnoise++ = x1 * w;
			obj->mSavedValue = x2 * w;
			obj->mHasSavedValue = YES;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *wnoise = obj->mAudioBuffers[0].doubleData + offset;
		if (obj->mHasSavedValue)
		{
			*wnoise++ = obj->mSavedValue;
			count--;
			obj->mHasSavedValue = NO;
		}
		while(count > 1)
		{
			double x1, x2, w;
			do
			{
				x1 = (double)random() / kRandomMax; x1 = (x1 + x1) - 1.;
				x2 = (double)random() / kRandomMax; x2 = (x2 + x2) - 1.;
				w = x1 * x1 + x2 * x2;
			} while (w >= 1.0);
			w = sqrt( (-2.0 * log10(w) ) / w );
			*wnoise++ = x1 * w;
			*wnoise++ = x2 * w;
			count -= 2;
		}
		if (count)
		{
			float x1, x2, w;
			do
			{
				x1 = (double)random() / kRandomMax; x1 = (x1 + x1) - 1.;
				x2 = (double)random() / kRandomMax; x2 = (x2 + x2) - 1.;
				w = x1 * x1 + x2 * x2;
			} while (w >= 1.0);
			w = sqrt( (-2.0 * log10(w) ) / w );
			*wnoise++ = x1 * w;
			obj->mSavedValue = x2 * w;
			obj->mHasSavedValue = YES;
		}
	}
}
*/
@implementation SBWhiteNoise

+ (NSString*) name
{
	return @"White Noise";
}

- (NSString*) name
{
	return @"wnoise";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates white noise (random values between -1 and 1, with gaussian distribution).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		[mOutputNames addObject:@"wnoise"];
	}
	return self;
}
/*
- (void) reset
{
	[super reset];
	mHasSavedValue = NO;
}
*/
@end
