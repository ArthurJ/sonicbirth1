/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSort.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBSort *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *min = obj->mAudioBuffers[0].floatData + offset;
		float *max = obj->mAudioBuffers[1].floatData + offset;
		while(count--)
		{
			float ca = *a++, cb = *b++;
			if (ca < cb)
			{
				*min++ = ca;
				*max++ = cb;
			}
			else
			{
				*min++ = cb;
				*max++ = ca;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *min = obj->mAudioBuffers[0].doubleData + offset;
		double *max = obj->mAudioBuffers[1].doubleData + offset;
		vDSP_vminD(a, 1, b, 1, min, 1, count);
		vDSP_vmaxD(a, 1, b, 1, max, 1, count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSort *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *min = obj->mAudioBuffers[0].floatData + offset;
		float *max = obj->mAudioBuffers[1].floatData + offset;
		while(count--)
		{
			float ca = *a++, cb = *b++;
			if (ca < cb)
			{
				*min++ = ca;
				*max++ = cb;
			}
			else
			{
				*min++ = cb;
				*max++ = ca;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *min = obj->mAudioBuffers[0].doubleData + offset;
		double *max = obj->mAudioBuffers[1].doubleData + offset;
		while(count--)
		{
			double ca = *a++, cb = *b++;
			if (ca < cb)
			{
				*min++ = ca;
				*max++ = cb;
			}
			else
			{
				*min++ = cb;
				*max++ = ca;
			}
		}
	}
}

@implementation SBSort

+ (NSString*) name
{
	return @"Sort";
}

- (NSString*) name
{
	return @"sort";
}

+ (SBElementCategory) category
{
	return kComparator;
}

- (NSString*) informations
{
	return @"Outputs the min and max of both inputs.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
#if (MAX_OS_VERSION_USE >= 4)
		pCalcFunc = (frameworkOSVersion() >= 4) ? privateCalcFuncFast : privateCalcFunc;
#else
		pCalcFunc = privateCalcFunc;
#endif
	
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		
		[mOutputNames addObject:@"min"];
		[mOutputNames addObject:@"max"];
	}
	return self;
}

@end


static void privateCalcFunc_one(void *inObj, int count, int offset)
{
	SBSortOne *obj = inObj;
	if (count <= 0) return;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *min = obj->mAudioBuffers[0].floatData + offset;
		float *max = obj->mAudioBuffers[1].floatData + offset;

		float ca = *a++, cb = *b++;
		if (ca < cb)
		{
			*min++ = ca;
			*max++ = cb;
		}
		else
		{
			*min++ = cb;
			*max++ = ca;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *min = obj->mAudioBuffers[0].doubleData + offset;
		double *max = obj->mAudioBuffers[1].doubleData + offset;

		double ca = *a++, cb = *b++;
		if (ca < cb)
		{
			*min++ = ca;
			*max++ = cb;
		}
		else
		{
			*min++ = cb;
			*max++ = ca;
		}
	}
}

// internal only - do not add to element list
@implementation SBSortOne

+ (NSString*) name
{
	return @"Sort one";
}

- (NSString*) name
{
	return @"sort 1";
}

+ (SBElementCategory) category
{
	return kComparator;
}

- (NSString*) informations
{
	return @"Outputs the min and max of both inputs (first sample only).";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc_one;

		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		
		[mOutputNames addObject:@"min"];
		[mOutputNames addObject:@"max"];
	}
	return self;
}

@end

