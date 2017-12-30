/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBValve.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBValve *obj = inObj;
	
	// http://www.notam02.no/~rbendiks/Diplom/Kurveforming.html#Overstyring
	/*
	y=filter([1 -2 1],[1 -2*rh rh^2],y);    %HP-filter 
	y=filter([1-rl],[1 -rl],y);             %LP-filter
	
	// http://ccrma.stanford.edu/~jos/filters/Matlab_Filter_Implementation.html
	
	y(n) = x(n) - 2*x(n-1) + x(n-2) + 2*rh*y(n-1) - rh^2*y(n-2)		%HP-filter
	z(n) = (1-rl)*y(n) + rl*z(n-1)  								%LP-filter
	
	// do the filters in the circuit
	*/
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *l = obj->pInputBuffers[1].floatData + offset;
		float *c = obj->pInputBuffers[2].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			float cl = *l++;
			float cc = *c++;
			
			if (cl > 1.f) cl = 1.f; else if (cl < 0.f) cl = 0.f;
			if (cc > 1.f) cc = 1.f; else if (cc < 0.f) cc = 0.f;
		
			float q = cl - 1.f;
			float dist = cc * 50.0f + 0.1f;
			float input = *i++;
			
			if (q == 0.0f)
			{
				if (input == 0.0f)
					*o++ = 1.0f / dist;
				else
					*o++ = input / (1.0f - expf(-dist * input));
			}
			else
			{
				if (input == q)
					*o++ = 1.0f / dist + q / (1.0f - expf(dist * q));
				else
					*o++ = (input - q) / (1.0f - expf(-dist * (input - q))) + q / (1.0f - expf(dist * q));
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *l = obj->pInputBuffers[1].doubleData + offset;
		double *c = obj->pInputBuffers[2].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			double cl = *l++;
			double cc = *c++;
			
			if (cl > 1.) cl = 1.; else if (cl < 0.) cl = 0.;
			if (cc > 1.) cc = 1.; else if (cc < 0.) cc = 0.;
		
			double q = cl - 1.;
			double dist = cc * 50.0 + 0.1;
			double input = *i++;
			
			if (q == 0.0)
			{
				if (input == 0.0)
					*o++ = 1.0 / dist;
				else
					*o++ = input / (1.0 - exp(-dist * input));
			}
			else
			{
				if (input == q)
					*o++ = 1.0 / dist + q / (1.0 - exp(dist * q));
				else
					*o++ = (input - q) / (1.0 - exp(-dist * (input - q))) + q / (1.0 - exp(dist * q));
			}
		}

	}
}

@implementation SBValve

+ (NSString*) name
{
	return @"Valve";
}

- (NSString*) name
{
	return @"valve";
}

+ (SBElementCategory) category
{
	return kDistortion;
}

- (NSString*) informations
{
	return	@"Valve distortion simulation. Level and character range is 0 to 1. "
			@"Level is how much the signal is driven against the limit of the valve. "
			@"Character is the hardness of the sound.";
}

- (id) init
{
	if ((self = [super init]))
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"lv"];
		[mInputNames addObject:@"ch"];
		
		[mOutputNames addObject:@"out"];

	}
	return self;
}

@end
