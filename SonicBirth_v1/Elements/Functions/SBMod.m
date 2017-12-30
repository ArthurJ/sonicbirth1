/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMod.h"
#import <Accelerate/Accelerate.h>

// mod(x, y) = x - i*y, i = int(x/y)

#if (MAX_OS_VERSION_USE >= 4)
static void privateCalcFuncFast(void *inObj, int count, int offset)
{
	SBMod *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *y = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
					
		vvdivf(o, x, y, &count);				// o = x/y 
		vvintf(o, o, &count);					// o = int(x/y)
		vDSP_vmul(o, 1, y, 1, o, 1, count);		// o = int(x/y)*y
		vDSP_vsub(o, 1, x, 1, o, 1, count);		// o = x - int(x/y)*y
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *y = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		vDSP_vdivD(y, 1, x, 1, o, 1, count);	// o = x/y
		vvint(o, o, &count);					// o = int(x/y)
		vDSP_vmulD(o, 1, y, 1, o, 1, count);	// o = int(x/y)*y
		vDSP_vsubD(o, 1, x, 1, o, 1, count);	// o = x - int(x/y)*y
	}
}
#endif

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBMod *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *x = obj->pInputBuffers[0].floatData + offset;
		float *y = obj->pInputBuffers[1].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = fmodf(*x++, *y++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *x = obj->pInputBuffers[0].doubleData + offset;
		double *y = obj->pInputBuffers[1].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *o++ = fmod(*x++, *y++);
	}
}

@implementation SBMod

+ (NSString*) name
{
	return @"Modulus";
}

- (NSString*) name
{
	return @"mod";
}

+ (SBElementCategory) category
{
	return kFunction;
}

- (NSString*) informations
{
	return @"Outputs x % y (x mod y).";
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
		[mInputNames addObject:@"y"];
		
		[mOutputNames addObject:@"x%y"];
	}
	return self;
}

@end
