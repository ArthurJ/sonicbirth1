/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCrossover.h"
#import "SBLowpass.h"
#import "SBHighpass.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBCrossover *obj = inObj;
	
	if (count <= 0) return;
	
	// audio stream
	obj->lp1->pInputBuffers[0] = obj->pInputBuffers[0];
	obj->hp1->pInputBuffers[0] = obj->pInputBuffers[0];
	
	// frequency
	obj->lp1->pInputBuffers[1] = obj->pInputBuffers[1];
	obj->lp2->pInputBuffers[1] = obj->pInputBuffers[1];
	obj->hp1->pInputBuffers[1] = obj->pInputBuffers[1];
	obj->hp2->pInputBuffers[1] = obj->pInputBuffers[1];
	
	(obj->lp1->pCalcFunc)(obj->lp1, count, offset);
	(obj->lp2->pCalcFunc)(obj->lp2, count, offset);
	(obj->hp1->pCalcFunc)(obj->hp1, count, offset);
	(obj->hp2->pCalcFunc)(obj->hp2, count, offset);
}

@implementation SBCrossover

+ (NSString*) name
{
	return @"Crossover";
}

- (NSString*) name
{
	return @"xover";
}

- (NSString*) informations
{
	return @"Linkwitz-Riley 24db/octave crossover.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"f"];
		
		[mOutputNames addObject:@"high"];
		[mOutputNames addObject:@"low"];
		
		lp1 = [[[self lpClass] alloc] init];
		if (!lp1)
		{
			[self release];
			return nil;
		}
		
		lp2 = [[[self lpClass] alloc] init];
		if (!lp2)
		{
			[self release];
			return nil;
		}
		
		hp1 = [[[self hpClass] alloc] init];
		if (!hp1)
		{
			[self release];
			return nil;
		}
		
		hp2 = [[[self hpClass] alloc] init];
		if (!hp2)
		{
			[self release];
			return nil;
		}
		
		pCalcFunc = privateCalcFunc;
	}
	return self;
}

- (void) dealloc
{
	if (lp1) [lp1 release];
	if (lp2) [lp2 release];
	if (hp1) [hp1 release];
	if (hp2) [hp2 release];
	[super dealloc];
}

+ (SBElementCategory) category
{
	return kFilter;
}

- (void) changePrecision:(SBPrecision)precision
{
	[lp1 changePrecision:precision];
	[lp2 changePrecision:precision];
	[hp1 changePrecision:precision];
	[hp2 changePrecision:precision];
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	[lp1 changeInterpolation:interpolation];
	[lp2 changeInterpolation:interpolation];
	[hp1 changeInterpolation:interpolation];
	[hp2 changeInterpolation:interpolation];
}

- (void) reset
{
	[lp1 reset]; [lp2 reset];
	[hp1 reset]; [hp2 reset];
}

- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{
	[lp1 prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];
	[lp2 prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];
	[hp1 prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];
	[hp2 prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];
			
	// these won't change
	lp2->pInputBuffers[0] = [lp1 outputAtIndex:0];
	hp2->pInputBuffers[0] = [hp1 outputAtIndex:0];
}

- (SBBuffer) outputAtIndex:(int)idx
{
	SBBuffer b = { 0 };

	if (idx == 0) return [hp2 outputAtIndex:0];
	else if (idx == 1) return [lp2 outputAtIndex:0];
	else return b;
}

- (Class) lpClass
{
	return [SBLowpass class];
}

- (Class) hpClass
{
	return [SBHighpass class];
}

@end

#import "SBFastFilter.h"

@implementation SBFastCrossover

+ (NSString*) name
{
	return @"Crossover (fast)";
}

- (NSString*) name
{
	return @"fxover";
}

- (NSString*) informations
{
	return @"Same as crossover, but only checks its parameter once per audio cycle.";
}

- (Class) lpClass
{
	return [SBFastLowpass class];
}

- (Class) hpClass
{
	return [SBFastHighpass class];
}

@end

