/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBSinCos.h"
#import <Accelerate/Accelerate.h>

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBSinCos *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *s = obj->mAudioBuffers[0].floatData + offset;
		float *c = obj->mAudioBuffers[1].floatData + offset;
		vvsincosf(s, c, i, &count);
		
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *s = obj->mAudioBuffers[0].doubleData + offset;
		double *c = obj->mAudioBuffers[1].doubleData + offset;
		vvsincos(s, c, i, &count);
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSinCos *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *s = obj->mAudioBuffers[0].floatData + offset;
		float *c = obj->mAudioBuffers[1].floatData + offset;
		while(count--)
		{
			float t = *i++;
			*s++ = sinf(t);
			*c++ = cosf(t);
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *s = obj->mAudioBuffers[0].doubleData + offset;
		double *c = obj->mAudioBuffers[1].doubleData + offset;
		while(count--)
		{
			double t = *i++;
			*s++ = sin(t);
			*c++ = cos(t);
		}
	}
}

@implementation SBSinCos

+ (NSString*) name
{
	return @"Sinus and cosinus";
}

- (NSString*) name
{
	return @"sincos";
}

+ (SBElementCategory) category
{
	return kTrigonometric;
}

- (NSString*) informations
{
	return @"Outputs both the sinus and the cosinus of the input.";
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
	
		[mInputNames addObject:@"x"];
		
		[mOutputNames addObject:@"sin x"];
		[mOutputNames addObject:@"cos x"];
	}
	return self;
}


@end
