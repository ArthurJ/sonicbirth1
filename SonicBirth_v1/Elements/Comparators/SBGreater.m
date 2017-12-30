/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBGreater.h"

static inline float sopf(float a, float b, float c, float d) __attribute__ ((always_inline));
static inline float sopf(float a, float b, float c, float d) { return (a > b) ? c : d; }

static inline double sop(double a, double b, double c, double d) __attribute__ ((always_inline));
static inline double sop(double a, double b, double c, double d) { return (a > b) ? c : d; }

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBGreater *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *a = obj->pInputBuffers[0].floatData + offset;
		float *b = obj->pInputBuffers[1].floatData + offset;
		float *c = obj->pInputBuffers[2].floatData + offset;
		float *d = obj->pInputBuffers[3].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--) *o++ = sopf(*a++, *b++, *c++, *d++);
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *a = obj->pInputBuffers[0].doubleData + offset;
		double *b = obj->pInputBuffers[1].doubleData + offset;
		double *c = obj->pInputBuffers[2].doubleData + offset;
		double *d = obj->pInputBuffers[3].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--) *o++ = sop(*a++, *b++, *c++, *d++);
	}
}

@implementation SBGreater

+ (NSString*) name
{
	return @"Greater";
}

- (NSString*) name
{
	return @"grtr";
}

+ (SBElementCategory) category
{
	return kComparator;
}

- (NSString*) informations
{
	return @"If (a > b) the outputs c else outputs d.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"a"];
		[mInputNames addObject:@"b"];
		[mInputNames addObject:@"c"];
		[mInputNames addObject:@"d"];
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

@end



