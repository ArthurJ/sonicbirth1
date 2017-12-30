/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSlow.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSlow *obj = inObj;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float t = obj->mTarg, c = obj->mCoef, l = obj->mCur;
		while(count--)
			*o++ = l = c*l + t**i++;
		obj->mCur = l;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double t = obj->mTarg, c = obj->mCoef, l = obj->mCur;
		while(count--)
			*o++ = l = c*l + t**i++;
		obj->mCur = l;
	}
}

@implementation SBSlow

+ (NSString*) name
{
	return @"Change Slower";
}

- (NSString*) name
{
	return @"slow";
}

- (NSString*) informations
{
	return @"Slows the rate of change of the input on a specified amount of milliseconds.";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"i"];
		
		// output 'o' has been added by superclass sbconstant
	}
	return self;
}

- (void) specificPrepare
{
	[self setValue:mValue];
}

- (void) reset
{
	mCur = 0;
	[super reset];
}

- (void) setValue:(double)value
{
	if (value < 0) value = 0;
	
	mValue = value;
	if (mValue < 0.001) mCoef = 0.;
	else mCoef = pow(0.01, 1000. / ( mValue * mSampleRate ));
	mTarg = 1. - mCoef;
	
	// fprintf(stderr, "mCo: %f mTa: %f\n", mCoef, mTarg);
}

@end
