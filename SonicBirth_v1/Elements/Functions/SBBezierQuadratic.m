/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBBezierQuadratic.h"

// (1-t)^2*a + 2*t*(1-t)*b + t^2*c
// (1 - 2t + t^2)a + (2(t-t^2))*b + (t^2)c

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBBezierQuadratic *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *a = obj->pInputBuffers[1].floatData + offset;
		float *b = obj->pInputBuffers[2].floatData + offset;
		float *c = obj->pInputBuffers[3].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			float t = *i++;
			float td = t + t; // t doubled
			float ts = t * t; // t square
			float tmts = t - ts; // t minus t square
			float tmtsd = tmts + tmts; // (t minus t square) doubled
			float coeffa = 1.f - td + ts;
			*o++ = coeffa * *a++ + tmtsd * *b++ + ts * *c++;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *a = obj->pInputBuffers[1].doubleData + offset;
		double *b = obj->pInputBuffers[2].doubleData + offset;
		double *c = obj->pInputBuffers[3].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			double t = *i++;
			double td = t + t; // t doubled
			double ts = t * t; // t square
			double tmts = t - ts; // t minus t square
			double tmtsd = tmts + tmts; // (t minus t square) doubled
			double coeffa = 1. - td + ts;
			*o++ = coeffa * *a++ + tmtsd * *b++ + ts * *c++;
		}
	}
}

@implementation SBBezierQuadratic

+ (NSString*) name
{
	return @"Quadratic Bezier";
}

- (NSString*) name
{
	return @"quad bez.";
}

+ (SBElementCategory) category
{
	return kFunction;
}

- (NSString*) informations
{
	return	@"Outputs (1-t)^2*a + 2*t*(1-t)*b + t^2*c, where t is clamped to 0 .. 1. "
			@"See http://en.wikipedia.org/wiki/B%e9zier_curve.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"t"];
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		[mInputNames addObject:@"c"];
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

@end

