/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBDCBlocker.h"

// http://ccrma.stanford.edu/~jos/filters/DC_Blocker.html

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDCBlocker *obj = inObj;
	
	if (count == 0) return;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset, *i1 = i;
		float *o = obj->mAudioBuffers[0].floatData + offset, *o1 = o;
		float r = obj->mR;
		*o++ = *i++ - (float)obj->mX1 + r * (float)obj->mY1;
		count--;
		while(count--) *o++ = *i++ - *i1++ + r * *o1++;
		obj->mX1 = *i1;
		obj->mY1 = *o1;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset, *i1 = i;
		double *o = obj->mAudioBuffers[0].doubleData + offset, *o1 = o;
		double r = obj->mR;
		*o++ = *i++ - obj->mX1 + r * obj->mY1;
		count--;
		while(count--) *o++ = *i++ - *i1++ + r * *o1++;
		obj->mX1 = *i1;
		obj->mY1 = *o1;
	}
}

@implementation SBDCBlocker

+ (NSString*) name
{
	return @"DC Blocker";
}

- (NSString*) name
{
	return @"dc block";
}

+ (SBElementCategory) category
{
	return kFilter;
}

- (NSString*) informations
{
	return @"Cuts frequencies below 20 hz.";
}

- (void) reset
{
	[super reset];
	mX1 = 0.;
	mY1 = 0.;
}

- (void) specificPrepare
{
	mR = 1. - (126./mSampleRate);
	if (mR > 0.9999) mR = 0.9999; // safeguard
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

@end
