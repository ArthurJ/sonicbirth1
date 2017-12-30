/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBBandstop.h"
#import "SBLowpass.h"
#import "SBHighpass.h"
#import "SBSort.h"
#import "SBAdd.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBBandstop *obj = inObj;
	
	if (count <= 0) return;
	
	// audio stream
	obj->lp1->pInputBuffers[0] = obj->pInputBuffers[0];
	obj->hp1->pInputBuffers[0] = obj->pInputBuffers[0];
	
	// frequency
	obj->sort->pInputBuffers[0] = obj->pInputBuffers[1];
	obj->sort->pInputBuffers[1] = obj->pInputBuffers[2];
	
	// in order!
	(obj->sort->pCalcFunc)(obj->sort, count, offset);
	(obj->lp1->pCalcFunc)(obj->lp1, count, offset);
	(obj->lp2->pCalcFunc)(obj->lp2, count, offset);
	(obj->hp1->pCalcFunc)(obj->hp1, count, offset);
	(obj->hp2->pCalcFunc)(obj->hp2, count, offset);
	(obj->add->pCalcFunc)(obj->add, count, offset);
}

@implementation SBBandstop

+ (NSString*) name
{
	return @"Bandstop";
}

- (NSString*) name
{
	return @"bstop";
}

- (NSString*) informations
{
	return @"24db/octave bandstop.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"f1"];
		[mInputNames addObject:@"f2"];
		
		[mOutputNames addObject:@"out"];
		
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
		
		sort = [[[self sortClass] alloc] init];
		if (!sort)
		{
			[self release];
			return nil;
		}
		
		add = [[SBAdd alloc] init];
		if (!add)
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
	if (sort) [sort release];
	if (add) [add release];
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
	[sort changePrecision:precision];
	[add changePrecision:precision];
}

- (void) changeInterpolation:(SBInterpolation)interpolation
{
	[lp1 changeInterpolation:interpolation];
	[lp2 changeInterpolation:interpolation];
	[hp1 changeInterpolation:interpolation];
	[hp2 changeInterpolation:interpolation];
	[sort changeInterpolation:interpolation];
	[add changeInterpolation:interpolation];
}

- (void) reset
{
	[lp1 reset]; [lp2 reset];
	[hp1 reset]; [hp2 reset];
	[sort reset]; [add reset];
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
	[sort prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];
	[add prepareForSamplingRate:samplingRate
			sampleCount:sampleCount
			precision:precision
			interpolation:interpolation];
			
	// these won't change
	
	// audio chain
	// in > lp1 > lp2 > out1
	// in > hp1 > hp2 > out2
	// out1, out2 > add > out
	
	lp2->pInputBuffers[0] = [lp1 outputAtIndex:0];
	hp2->pInputBuffers[0] = [hp1 outputAtIndex:0];
	add->pInputBuffers[0] = [lp2 outputAtIndex:0];
	add->pInputBuffers[1] = [hp2 outputAtIndex:0];
	
	// freq
	hp1->pInputBuffers[1] = [sort outputAtIndex:1];
	hp2->pInputBuffers[1] = [sort outputAtIndex:1];
	lp1->pInputBuffers[1] = [sort outputAtIndex:0];
	lp2->pInputBuffers[1] = [sort outputAtIndex:0];
}

- (SBBuffer) outputAtIndex:(int)idx
{
	SBBuffer b = { 0 };

	if (idx == 0) return [add outputAtIndex:0];
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

- (Class) sortClass
{
	return [SBSort class];
}

@end


#import "SBFastFilter.h"

@implementation SBFastBandstop

+ (NSString*) name
{
	return @"Bandstop (fast)";
}

- (NSString*) name
{
	return @"fbstop";
}

- (NSString*) informations
{
	return @"Same as bandstop, but only checks its parameters once per audio cycle.";
}

- (Class) lpClass
{
	return [SBFastLowpass class];
}

- (Class) hpClass
{
	return [SBFastHighpass class];
}

- (Class) sortClass
{
	return [SBSortOne class];
}
@end
