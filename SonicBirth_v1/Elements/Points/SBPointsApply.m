/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPointsApply.h"
#import "SBPointCalculation.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBPointsApply *obj = inObj;
	
	if (!count) return;
	
	SBPointsBuffer pts = *(obj->pInputBuffers[5].pointsData);
	int save = 0;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *x = obj->pInputBuffers[1].floatData + offset;
		float *y = obj->pInputBuffers[2].floatData + offset;
		float *w = obj->pInputBuffers[3].floatData + offset;
		float *h = obj->pInputBuffers[4].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			
			float r = pointCalculate(&pts, (*i++ - *x++) / *w++, &save);
			*o++ = (r * *h++) + *y++;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *x = obj->pInputBuffers[1].doubleData + offset;
		double *y = obj->pInputBuffers[2].doubleData + offset;
		double *w = obj->pInputBuffers[3].doubleData + offset;
		double *h = obj->pInputBuffers[4].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			
			double r = pointCalculate(&pts, (*i++ - *x++) / *w++, &save);
			*o++ = (r * *h++) + *y++;
		}
	}
}

@implementation SBPointsApply

+ (NSString*) name
{
	return @"Points apply";
}

- (NSString*) name
{
	return @"pts apply";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return @"Applies the points function using x and y as origin, width and height as size.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"i"];
		[mInputNames addObject:@"x"];
		[mInputNames addObject:@"y"];
		[mInputNames addObject:@"w"];
		[mInputNames addObject:@"h"];
		[mInputNames addObject:@"pts"];
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx < 5) return kNormal;
	return kPoints;
}

@end
