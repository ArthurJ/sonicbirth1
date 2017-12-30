/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAbsSign.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAbsSign *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *ax = obj->mAudioBuffers[0].floatData + offset;
		float *si = obj->mAudioBuffers[1].floatData + offset;
		while(count--)
		{
			float c = *x++;
			if (c < 0.f)
			{
				*ax++ = -c;
				*si++ = -1.f;
			}
			else
			{
				*ax++ = c;
				*si++ = 1.f;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *ax = obj->mAudioBuffers[0].doubleData + offset;
		double *si = obj->mAudioBuffers[1].doubleData + offset;
		while(count--)
		{
			double c = *x++;
			if (c < 0.)
			{
				*ax++ = -c;
				*si++ = -1.;
			}
			else
			{
				*ax++ = c;
				*si++ = 1.;
			}
		}
	}
}

@implementation SBAbsSign

+ (NSString*) name
{
	return @"Absolute/Sign";
}

- (NSString*) name
{
	return @"abssign";
}

+ (SBElementCategory) category
{
	return kAlgebraic;
}

- (NSString*) informations
{
	return @"Outputs |x| (x if x>=0, -x if x<0), and sign of x (1 for pos, -1 for neg).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"x"];
		
		[mOutputNames addObject:@"|x|"];
		[mOutputNames addObject:@"sign"];
	}
	return self;
}

@end
