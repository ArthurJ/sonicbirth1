/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBDebug.h"
#import "SBValueCell.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBDebug *obj = inObj;
	
	if (!count) return;
	double cur = 0;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		cur = *i;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		cur = *i;
	}
	
	SBValueCell *cell = (SBValueCell*)obj->mCell;
	if (cell) [cell setValue:cur];
}

@implementation SBDebug

+ (NSString*) name
{
	return @"Debug";
}

- (NSString*) name
{
	return @"dbg";
}

- (NSString*) informations
{
	return	@"Shows the first value of the input of each audio cycle.";
}

+ (SBElementCategory) category
{
	return kAnalysis;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;

		[mInputNames addObject:@"in"];
	}
	return self;
}

- (SBCell*) createCell
{
	return [[SBValueCell alloc] init];
}

- (BOOL) alwaysExecute
{
	return YES;
}

- (BOOL) constantRefresh
{
	return YES;
}


@end
