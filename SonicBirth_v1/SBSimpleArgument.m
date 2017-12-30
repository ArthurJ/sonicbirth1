/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBSimpleArgument.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSimpleArgument *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		int i, c = obj->mNumberOfOutputs;
		for (i = 0; i < c; i++)
		{
			int curCount = count;
			float *o = obj->mAudioBuffers[i].floatData + offset;
			float currentValue = obj->mCurrentValue[i];
			float currentCoeff = obj->mCurrentCoeff;
			float targetCoeff = obj->mTargetCoeff;

			// first check if a changed is planned in this cycle
			int offsetToChange = obj->mOffsetToChange[i];
			if (offsetToChange > 0 && offsetToChange < count)
			{
				// there will be a change in this cycle
				while(curCount > 0)
				{
					*o++ = currentValue = currentCoeff * currentValue + targetCoeff * (float)obj->mTargetValue[i];
					curCount--;
					offsetToChange--;
					
					if (offsetToChange <= 0)
					{
						obj->mTargetValue[i] = obj->mNewValue[i];
						break;
					}
				}
				
				// change is done
				while(curCount > 0)
				{
					*o++ = currentValue = currentCoeff * currentValue + targetCoeff * (float)obj->mTargetValue[i];
					curCount--;
				}
			}
			else
			{
				float cv;
			
				// no change in this cycle, process until stable
				while(curCount > 0)
				{
					cv = currentCoeff * currentValue + targetCoeff * (float)obj->mTargetValue[i];
					if (cv == currentValue) break;
					
					*o++ = currentValue = cv;
					curCount--;
				}
				
				// process is stable
				while(curCount > 7)
				{
					*o++ = currentValue; *o++ = currentValue;
					*o++ = currentValue; *o++ = currentValue;
					*o++ = currentValue; *o++ = currentValue;
					*o++ = currentValue; *o++ = currentValue;
					curCount -= 8;
				}
				while(curCount > 0)
				{
					*o++ = currentValue;
					curCount--;
				}
			
				if (offsetToChange > 0) offsetToChange -= count;
			}
			
			obj->mCurrentValue[i] = currentValue;
			obj->mOffsetToChange[i] = offsetToChange;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		int i, c = obj->mNumberOfOutputs;
		for (i = 0; i < c; i++)
		{
			int curCount = count;
			double *o = obj->mAudioBuffers[i].doubleData + offset;
			double currentValue = obj->mCurrentValue[i];
			double currentCoeff = obj->mCurrentCoeff;
			double targetCoeff = obj->mTargetCoeff;

			// first check if a changed is planned in this cycle
			int offsetToChange = obj->mOffsetToChange[i];
			if (offsetToChange > 0 && offsetToChange < count)
			{
				// there will be a change in this cycle
				while(curCount > 0)
				{
					*o++ = currentValue = currentCoeff * currentValue + targetCoeff * obj->mTargetValue[i];
					curCount--;
					offsetToChange--;
					
					if (offsetToChange <= 0)
					{
						obj->mTargetValue[i] = obj->mNewValue[i];
						break;
					}
				}
				
				// change is done
				while(curCount > 0)
				{
					*o++ = currentValue = currentCoeff * currentValue + targetCoeff * obj->mTargetValue[i];
					curCount--;
				}
			}
			else
			{
				double cv;
			
				// no change in this cycle, process until stable
				while(curCount > 0)
				{
					cv = currentCoeff * currentValue + targetCoeff * obj->mTargetValue[i];
					if (cv == currentValue) break;
					
					*o++ = currentValue = cv;
					curCount--;
				}
				
				// process is stable
				while(curCount > 7)
				{
					*o++ = currentValue; *o++ = currentValue;
					*o++ = currentValue; *o++ = currentValue;
					*o++ = currentValue; *o++ = currentValue;
					*o++ = currentValue; *o++ = currentValue;
					curCount -= 8;
				}
				while(curCount > 0)
				{
					*o++ = currentValue;
					curCount--;
				}
			
				if (offsetToChange > 0) offsetToChange -= count;
			}
			
			obj->mCurrentValue[i] = currentValue;
			obj->mOffsetToChange[i] = offsetToChange;
		}
	}
}

/*
static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBSimpleArgument *obj = inObj;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		int i, c = obj->mNumberOfOutputs;
		for (i = 0; i < c; i++)
		{
			int curCount = count;
			float *output = obj->mAudioBuffers[i].floatData + offset;
			float currentValue = obj->mCurrentValue[i];
			float currentCoeff = obj->mCurrentCoeff;
			float targetCoeff = obj->mTargetCoeff;

			while(curCount--)
			{
				*output++ = currentValue = currentCoeff * currentValue + targetCoeff * (float)obj->mTargetValue[i];
				if (obj->mOffsetToChange[i] > 0)
					obj->mOffsetToChange[i]--;
				else
					obj->mTargetValue[i] = obj->mNewValue[i];
			}
			
			obj->mCurrentValue[i] = currentValue;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		int i, c = obj->mNumberOfOutputs;
		for (i = 0; i < c; i++)
		{
			int curCount = count;
			double *output = obj->mAudioBuffers[i].doubleData + offset;
			double currentValue = obj->mCurrentValue[i];
			double currentCoeff = obj->mCurrentCoeff;
			double targetCoeff = obj->mTargetCoeff;

			while(curCount--)
			{
				*output++ = currentValue = currentCoeff * currentValue + targetCoeff * obj->mTargetValue[i];
				if (obj->mOffsetToChange[i] > 0)
					obj->mOffsetToChange[i]--;
				else
					obj->mTargetValue[i] = obj->mNewValue[i];
			}
			
			obj->mCurrentValue[i] = currentValue;
		}
	}
}
*/

@implementation SBSimpleArgument

+ (SBElementCategory) category
{
	return kArgument;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mCurrentCoeff = mTargetCoeff = 0;
		mNumberOfOutputs = 1;
	
		int i;
		for (i = 0; i < kMaxChannels; i++)
		{
			mOffsetToChange[i] = -1;
			mNewValue[i] = 0;
			mTargetValue[i] = 0;
			mCurrentValue[i] = 0;
		}
		mName = [[NSMutableString alloc] initWithString:@"arg"];
		if (!mName)
		{
			[self release];
			return nil;
		}
		
		mAverageMs = 1.f;
	}
	return self;
}

- (void) dealloc
{
	if (mName) [mName release];
	[super dealloc];
}

- (NSString*) name
{
	return mName;
}

- (int) numberOfInputs
{
	return 0;
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	return nil;
}

- (int) numberOfOutputs
{
	return mNumberOfOutputs;
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return @"value";
}

- (void) reset
{
	// [super reset]; // no need to
	
	int i, j;
	
	for (i = 0; i < mNumberOfOutputs; i++)
	{
		if (mOffsetToChange[i] >= 0)
		{
			mTargetValue[i] = mNewValue[i];
			mOffsetToChange[i] = -1;
		}
		mCurrentValue[i] = mTargetValue[i];
	}
	
	if (mPrecision == kFloatPrecision)
	{
		for (i = 0; i < mNumberOfOutputs; i++)
			for (j = 0; j < mSampleCount; j++)
				mAudioBuffers[i].floatData[j] = mCurrentValue[i];
	}
	else
	{
		for (i = 0; i < mNumberOfOutputs; i++)
			for (j = 0; j < mSampleCount; j++)
				mAudioBuffers[i].doubleData[j] = mCurrentValue[i];
	}
}

- (void) setValue:(double)value forOutput:(int)output offsetToChange:(int)offset
{
	if (offset <= 0)
	{
		mTargetValue[output] = mNewValue[output] = value;
		mOffsetToChange[output] = -1;
		
	}
	else if (offset > 0)
	{
		mNewValue[output] = value;
		mOffsetToChange[output] = offset;
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mNameTF)
	{
		[self setName:[mNameTF stringValue]];
	}
}

- (IBAction) pushedRealtimeButton:(id)sender;
{
	[self setRealtime:([mRealtimeButton state] == NSOnState)];
}

- (void) specificPrepare
{
	if (mAverageMs < 0.001) mCurrentCoeff = 0.;
	else mCurrentCoeff = pow(0.01, 1000. / ( mAverageMs * mSampleRate ));
	mTargetCoeff = 1. - mCurrentCoeff;
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
	if (mNameTF) [mNameTF setStringValue:name];
	[self didChangeGlobalView];
	[self didChangeParameterInfo];
}

- (BOOL) realtime
{
	return mRealtime;
}

- (void) setRealtime:(BOOL)realtime
{
	mRealtime = realtime;
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	if (mRealtimeButton) [mRealtimeButton setState:(mRealtime) ? NSOnState : NSOffState];
	if (mNameTF) [mNameTF setStringValue:mName];
	if (mAverageSlider) [mAverageSlider setFloatValue:mAverageMs];
	if (mAverageTF) [mAverageTF setFloatValue:mAverageMs];
}

- (IBAction) changedAverage:(id)sender
{
	mAverageMs = [mAverageSlider floatValue];
	if (mAverageMs < 0.001) mCurrentCoeff = 0.;
	else mCurrentCoeff = pow(0.01, 1000. / ( mAverageMs * mSampleRate ));
	mTargetCoeff = 1. - mCurrentCoeff;
	if (mAverageTF) [mAverageTF setFloatValue:mAverageMs];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:mName forKey:@"argName"];
	[md setObject:[NSNumber numberWithInt:((mRealtime) ? 2 : 1)] forKey:@"argRealtime"];
	[md setObject:[NSNumber numberWithFloat:mAverageMs] forKey:@"argAverage"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSString *s = [data objectForKey:@"argName"];
	if (s) [mName setString:s];
	
	NSNumber *n = [data objectForKey:@"argRealtime"];
	if (n) mRealtime = ([n intValue] == 2);
	
	n = [data objectForKey:@"argAverage"];
	if (n) mAverageMs = [n floatValue];

	return YES;
}

- (double) minValue
{
	return mTargetValue[0];
}

- (double) maxValue
{
	return mTargetValue[0];
}

- (SBParameterType) type
{
	return kParameterUnit_Generic;
}

- (double) currentValue
{
	return mTargetValue[0];
}

- (void) takeValue:(double)preset offsetToChange:(int)offset
{
	[self setValue:preset forOutput:0 offsetToChange:offset];
}

- (BOOL) logarithmic
{
	return NO;
}

// for indexed types:
- (NSArray*) indexedNames
{
	return nil;
}

- (int) numberOfParameters
{
	return 1;
}

- (double) minValueForParameter:(int)i
{
	return [self minValue];
}

- (double) maxValueForParameter:(int)i
{
	return [self maxValue];
}

- (BOOL) logarithmicForParameter:(int)i
{
	return [self logarithmic];
}

- (BOOL) realtimeForParameter:(int)i
{
	return [self realtime];
}

- (SBParameterType) typeForParameter:(int)i
{
	return [self type];
}

- (double) currentValueForParameter:(int)i
{
	return [self currentValue];
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	[self takeValue:preset offsetToChange:offset];
}

- (NSArray*) indexedNamesForParameter:(int)i
{
	return [self indexedNames];
}

- (NSString*) nameForParameter:(int)i
{
	return [self name];
}

@end
