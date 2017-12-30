/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBTrigger.h"


static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBTrigger *obj = inObj;
	
	BOOL state = obj->mState;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *tt = obj->pInputBuffers[0].floatData + offset;
		float *rt = obj->pInputBuffers[1].floatData + offset;
		float *t = obj->pInputBuffers[2].floatData + offset;
		float *r = obj->pInputBuffers[3].floatData + offset;
		float *on = obj->pInputBuffers[4].floatData + offset;
		float *off = obj->pInputBuffers[5].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;

		while(count--)
		{
			if (*r++ > *rt++) state = NO;
			if (*t++ > *tt++) state = YES;
			if (state)	{ *o++ = *on++; off++; }
			else		{ *o++ = *off++; on++; }
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *tt = obj->pInputBuffers[0].doubleData + offset;
		double *rt = obj->pInputBuffers[1].doubleData + offset;
		double *t = obj->pInputBuffers[2].doubleData + offset;
		double *r = obj->pInputBuffers[3].doubleData + offset;
		double *on = obj->pInputBuffers[4].doubleData + offset;
		double *off = obj->pInputBuffers[5].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;

		while(count--)
		{
			if (*r++ > *rt++) state = NO;
			if (*t++ > *tt++) state = YES;
			if (state)	{ *o++ = *on++; off++; }
			else		{ *o++ = *off++; on++; }
		}
	}
	
	obj->mState = state;
}

@implementation SBTrigger

+ (NSString*) name
{
	return @"Trigger";
}

- (NSString*) name
{
	return @"trigger";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Trigger sends either the on value or off value depending on its internal state. "
			@"Its state is initialized as off. If the t (trigger) input is higher than the tt "
			@"(trigger threshold) input, its state is turned on. If the r (reset) input is "
			@"higher than the rt (reset threshold) input, its stated is turned off. In case both "
			@"events are occuring simultaneously, the state is turned on.";
}

- (void) reset
{
	[super reset];
	mState = NO;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"tt"];
		[mInputNames addObject:@"rt"];
		[mInputNames addObject:@"t"];
		[mInputNames addObject:@"r"];
		[mInputNames addObject:@"on"];
		[mInputNames addObject:@"off"];
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

@end
