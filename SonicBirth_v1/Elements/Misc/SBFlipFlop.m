/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFlipFlop.h"


static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFlipFlop *obj = inObj;
	
	BOOL state = obj->mState;
	BOOL outputA = obj->mOutputA;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *t = obj->pInputBuffers[0].floatData + offset;
		float *a = obj->pInputBuffers[1].floatData + offset;
		float *b = obj->pInputBuffers[2].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;

		while(count--)
		{
			if (*t++ > 0.5f) { if (!state) { state = YES; outputA = !outputA; } } else state = NO;
			if (outputA)	{ *o++ = *a++; b++; }
			else			{ *o++ = *b++; a++; }
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *t = obj->pInputBuffers[0].doubleData + offset;
		double *a = obj->pInputBuffers[1].doubleData + offset;
		double *b = obj->pInputBuffers[2].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;

		while(count--)
		{
			if (*t++ > 0.5) { if (!state) { state = YES; outputA = !outputA; } } else state = NO;
			if (outputA)	{ *o++ = *a++; b++; }
			else			{ *o++ = *b++; a++; }
		}
	}
	
	obj->mState = state;
	obj->mOutputA = outputA;
}

@implementation SBFlipFlop

+ (NSString*) name
{
	return @"Flip flop";
}

- (NSString*) name
{
	return @"flipflop";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Flip flop outputs 'a' by default. Everytime 't' crosses above 0.5, the output switch to the other input.";
}

- (void) reset
{
	[super reset];
	mState = NO;
	mOutputA = YES;
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
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

@end
