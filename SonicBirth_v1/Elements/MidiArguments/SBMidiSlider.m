/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiSlider.h"
#import "SBControllerList.h"
#import "SBSliderCell.h"
#import "SBSliderHorCell.h"
#import "SBSliderVerCell.h"

@implementation SBMidiSlider
+ (NSString*) name
{
	return @"Midi slider";
}

- (NSString*) informations
{
	return @"Outputs the value of the a midi parameter in a user supplied range.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBMidiSlider" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	
	[mRangeMinTF setDoubleValue:mRangeMin];
	[mRangeMaxTF setDoubleValue:mRangeMax];
	[mDefaultTF setDoubleValue:mTargetValue[0]];
	
	if (mMapping == 0)
	{
		[mSlider setMinValue:mRangeMin];
		[mSlider setMaxValue:mRangeMax];
		[mSlider setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider setMinValue:lin2log(mRangeMin, mRangeMin, mRangeMax)];
		[mSlider setMaxValue:lin2log(mRangeMax, mRangeMin, mRangeMax)];
		[mSlider setDoubleValue:lin2log(mTargetValue[0], mRangeMin, mRangeMax)];
	}
	[mMappingPopUp selectItemAtIndex:mMapping];
	[mTypePopUp selectItemAtIndex:mValueType];
	
	[mControllerType removeAllItems];
	int c = gControllerTypesCount, i;
	for (i = 0; i < c; i++)
	{
		[mControllerType addItemWithTitle:gControllerTypes[i].name];
		if (gControllerTypes[i].num == mType)
			[mControllerType selectItemAtIndex:i];
	}
	
	[mShowNumber setState:([(SBSliderCell *)mCell showsValue]) ? NSOnState : NSOffState];
	[mSliderWidthTF setIntValue:[(SBSliderCell *)mCell sliderWidth]];
	[mSliderHeightTF setIntValue:[(SBSliderCell *)mCell sliderHeight]];
	[mTypeOfCellPopUp selectItemAtIndex:mTypeOfCell];
	
	[mWholeNumberOnlyBt setState:(mWholeNumberOnly) ? NSOnState : NSOffState];
	
	if (mBackImage) [mBackImageView setImage:mBackImage];
	if (mFrontImage) [mFrontImageView setImage:mFrontImage];
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		mMapping = 0;
		mValueType = 0;
		mType = 1; // mod wheel
		mRangeMin = 0.;
		mRangeMax = 1.;
		
		mLastMSB = 0;
		mLastLSB = 0;
		[mName setString:@"midi sldr"];
		
		mTypeOfCell = 0;
		mWholeNumberOnly = NO;
		
		mBackImage = nil;
		mFrontImage = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	if (mBackImage) [mBackImage release];
	if (mFrontImage) [mFrontImage release];
	[super dealloc];
}

- (void) changedControllerType:(id)sender
{
	mType = gControllerTypes[[mControllerType indexOfSelectedItem]].num;
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[super controlTextDidEndEditing:aNotification];

	id tf = [aNotification object];
	if (tf == mRangeMinTF)
	{
		mRangeMin = [mRangeMinTF doubleValue];
		if (mRangeMin > mRangeMax) mRangeMax = mRangeMin;
		if (mTargetValue[0] < mRangeMin) [self setValue:mRangeMin forOutput:0 offsetToChange:0];
	}
	else if (tf == mRangeMaxTF)
	{
		mRangeMax = [mRangeMaxTF doubleValue];
		if (mRangeMax < mRangeMin) mRangeMin = mRangeMax;
		if (mTargetValue[0] > mRangeMax) [self setValue:mRangeMax forOutput:0 offsetToChange:0];
	}
	else if (tf == mDefaultTF)
	{
		double temp = [mDefaultTF doubleValue];
		if (temp > mRangeMax) temp = mRangeMax;
		if (temp < mRangeMin) temp = mRangeMin;
		[self setValue:temp forOutput:0 offsetToChange:0];
	}
	else if (tf == mSliderWidthTF)
	{
		float w = [mSliderWidthTF floatValue];
		if (mTypeOfCell == 0) w *= 0.5f;
		[(SBSliderCell *)mCell setSliderWidth:w];
		[mSliderWidthTF setIntValue:[(SBSliderCell *)mCell sliderWidth]];
		[self didChangeGlobalView];
		return;
	}
	else if (tf == mSliderHeightTF)
	{
		[(SBSliderCell *)mCell setSliderHeight:[mSliderHeightTF floatValue]];
		[mSliderHeightTF setIntValue:[(SBSliderCell *)mCell sliderHeight]];
		[self didChangeGlobalView];
		return;
	}
	
	[mRangeMinTF setDoubleValue:mRangeMin];
	[mRangeMaxTF setDoubleValue:mRangeMax];
	[mDefaultTF setDoubleValue:mTargetValue[0]];
	if (mMapping == 0)
	{
		[mSlider setMinValue:mRangeMin];
		[mSlider setMaxValue:mRangeMax];
		[mSlider setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider setMinValue:lin2log(mRangeMin, mRangeMin, mRangeMax)];
		[mSlider setMaxValue:lin2log(mRangeMax, mRangeMin, mRangeMax)];
		[mSlider setDoubleValue:lin2log(mTargetValue[0], mRangeMin, mRangeMax)];
	}
	[self didChangeView];
	[self didChangeParameterInfo];
}

- (void) reset
{
	mLastMSB = 0;
	mLastLSB = 0;
	
	[super reset];
}

- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offset
{
	if (mType == kOffID)
		return;
		
	if (mChannel < 0)
		return;

	if ((status == kMidiMessage_ControlChange) && (!mChannel || (mChannel - 1 == channel)))
	{
		if (mType == kLearnID)
		{
			if (data1 < 120 && data1 != 100 && data1 != 98 && !(data1 >= 32 && data1 <= 63))
			{
				mType = data1;
				[self changedController];
				if (mControllerType)
				{
					int c = gControllerTypesCount, i;
					for (i = 0; i < c; i++)
					{
						if (gControllerTypes[i].num == mType)
						{
							[mControllerType selectItemAtIndex:i];
							break;
						}
					}
				}
			}
		}
		if (mType == kLearnID)
			return;

		if (data1 == kMidiController_ResetAllControllers)
		{
			/*
			[self setValue:mDefault forOutput:0 offsetToChange:offset];
		
			[mCurrentTF setDoubleValue:mDefault];
	
			if (mMapping == 0)
				[mSlider setDoubleValue:mDefault];
			else
				[mSlider setDoubleValue:lin2log(mDefault, mRangeMin, mRangeMax)];
				
			[self didChangeView];
			*/
		}
		else
		{
			int type1 = mType;
			int type2 = -1;
	
			if (type1 >= 0 && type1 <= 31) type2 = type1 + 32;
			else if (type1 == 101 || type1 == 99) type2 = type1 - 1;
		
			if (data1 !=  type1 && data1 != type2)
				return;
		
			if (data1 == type1)
				mLastMSB = data2;
				
			if (data1 == type2)
				mLastLSB = data2;
				
			int value = (mLastMSB << 7) | mLastLSB;
			// 2^14 - 1 = 16383
			
			double normValue = value / 16383.; // value normalized to [0, 1]
			
			// on/off
			if ((mType >= 64 && mType <= 69) || mType == 122)
			{
				if (normValue < 0.5) normValue = 0.;
				else normValue = 1.;
			}
			
			double appliedValue;
			
			if (mMapping == 0)
			{
				appliedValue = mRangeMin + normValue*(mRangeMax - mRangeMin);
				if (mSlider) [mSlider setDoubleValue:appliedValue];
			}
			else
			{
				double logMin = lin2log(mRangeMin, mRangeMin, mRangeMax);
				double logMax = lin2log(mRangeMax, mRangeMin, mRangeMax);
				appliedValue = logMin + normValue*(logMax - logMin);
				
				if (mSlider) [mSlider setDoubleValue:appliedValue];
				
				appliedValue = log2lin(appliedValue, mRangeMin, mRangeMax);
			}
			
			if (mDefaultTF) [mDefaultTF setDoubleValue:appliedValue];
			[self setValue:appliedValue forOutput:0 offsetToChange:offset];
			[self didChangeParameterValueAtIndex:0];
			[self didChangeView];
		}
	}
}

- (IBAction) sliderMoved:(id)sender
{
	double nval = [mSlider doubleValue];

	if (mWholeNumberOnly)
		nval = floor(nval);

	if (mMapping == 1)
		nval = log2lin(nval, mRangeMin, mRangeMax);

	[self setValue:nval forOutput:0 offsetToChange:0];
	[mDefaultTF setDoubleValue:mTargetValue[0]];
	[self didChangeView];
}

- (IBAction) changedTypeOrMapping:(id)sender
{
	mMapping = [mMappingPopUp indexOfSelectedItem];
	mValueType = [mTypePopUp indexOfSelectedItem];
	if (mMapping == 0)
	{
		[mSlider setMinValue:mRangeMin];
		[mSlider setMaxValue:mRangeMax];
		[mSlider setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider setMinValue:lin2log(mRangeMin, mRangeMin, mRangeMax)];
		[mSlider setMaxValue:lin2log(mRangeMax, mRangeMin, mRangeMax)];
		[mSlider setDoubleValue:lin2log(mTargetValue[0], mRangeMin, mRangeMax)];
	}
}

- (int) numberOfParameters
{
	return 1;
}

- (BOOL) realtime
{
	return YES;
}

- (BOOL) logarithmic
{
	return (mMapping == 1);
}

- (double) minValue
{
	return mRangeMin;
}

- (double) maxValue
{
	return mRangeMax;
}

- (SBParameterType) type
{
	switch(mValueType)
	{
		case 1: return kParameterUnit_Percent;
		case 2: return kParameterUnit_Seconds;
		case 3: return kParameterUnit_SampleFrames;
		case 4: return kParameterUnit_Phase;
		case 5: return kParameterUnit_Rate;
		case 6: return kParameterUnit_Hertz;
		case 7: return kParameterUnit_Cents;
		case 8: return kParameterUnit_Decibels;
		case 9: return kParameterUnit_LinearGain;
		case 10: return kParameterUnit_Degrees;
		case 11: return kParameterUnit_EqualPowerCrossfade;
		case 12: return kParameterUnit_MixerFaderCurve1;
		case 13: return kParameterUnit_Pan;
		case 14: return kParameterUnit_Meters;
		case 15: return kParameterUnit_AbsoluteCents;
		case 16: return kParameterUnit_Beats;
		case 17: return kParameterUnit_Milliseconds;
		default: return kParameterUnit_Generic;
	}
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	if (mWholeNumberOnly)
		preset = floor(preset);

	if (preset < mRangeMin) preset = mRangeMin;
	else if (preset > mRangeMax) preset = mRangeMax;
	[self setValue:preset forOutput:0 offsetToChange:offset];
	if (mSlider)
	{
		if (mMapping == 0)
			[mSlider setDoubleValue:mTargetValue[0]];
		else
			[mSlider setDoubleValue:lin2log(mTargetValue[0], mRangeMin, mRangeMax)];
	}
	if (mDefaultTF) [mDefaultTF setDoubleValue:mTargetValue[0]];
	[self didChangeView];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mRangeMin] forKey:@"min"];
	[md setObject:[NSNumber numberWithDouble:mRangeMax] forKey:@"max"];
	[md setObject:[NSNumber numberWithDouble:mTargetValue[0]] forKey:@"default"];
	[md setObject:[NSNumber numberWithInt:mMapping] forKey:@"mapping"];
	[md setObject:[NSNumber numberWithInt:mValueType] forKey:@"value type"];
	[md setObject:[NSNumber numberWithInt:mType] forKey:@"ctrl type"];
	[md setObject:[NSNumber numberWithDouble:([(SBSliderCell *)mCell showsValue]) ? 2 : 1] forKey:@"showsValue"];
	[md setObject:[NSNumber numberWithInt:mTypeOfCell] forKey:@"typeOfCell"];
	
	[md setObject:[NSNumber numberWithInt:
							(mTypeOfCell == 0)
						?	([(SBSliderCell *)mCell sliderWidth]*0.5f)
						:	[(SBSliderCell *)mCell sliderWidth]] forKey:@"cellWidth"];
						
	[md setObject:[NSNumber numberWithInt:[(SBSliderCell *)mCell sliderHeight]] forKey:@"cellHeight"];
	
	[md setObject:[NSNumber numberWithInt:(mWholeNumberOnly) ? 2 : 1] forKey:@"wholeNumberOnly"];
	
	if (mBackImage) [md setObject:[mBackImage TIFFRepresentation] forKey:@"backImage"];
	if (mFrontImage) [md setObject:[mFrontImage TIFFRepresentation] forKey:@"frontImage"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"min"];
	if (n) mRangeMin = [n doubleValue];
	
	n = [data objectForKey:@"max"];
	if (n) mRangeMax = [n doubleValue];
	
	n = [data objectForKey:@"default"];
	if (n) [self setValue:[n doubleValue] forOutput:0 offsetToChange:0];
	
	n = [data objectForKey:@"mapping"];
	if (n) mMapping = [n intValue];
	
	n = [data objectForKey:@"value type"];
	if (n) mValueType = [n intValue];
	
	n = [data objectForKey:@"ctrl type"];
	if (n) mType = [n intValue];
	
	n = [data objectForKey:@"typeOfCell"];
	if (n) mTypeOfCell = [n intValue];

	// force rechange of cell
	SBCell *cell = mCell;
	mCell = [self createCell];
	if (cell)
	{
		[mCell setColorsBack:[cell backColor]
					 contour:[cell contourColor]
					   front:[cell frontColor]];
		[cell release];
	}
	mCalculatedFrame = NO;
	
	n = [data objectForKey:@"showsValue"];
	if (n) [(SBSliderCell *)mCell setShowValue:([n intValue] == 2)];
	
	n = [data objectForKey:@"wholeNumberOnly"];
	if (n) mWholeNumberOnly = ([n intValue] == 2);
	
	n = [data objectForKey:@"cellWidth"];
	if (n) [(SBSliderCell *)mCell setSliderWidth:[n intValue]];
	
	n = [data objectForKey:@"cellHeight"];
	if (n) [(SBSliderCell *)mCell setSliderHeight:[n intValue]];
	
	NSData *dt;
	
	dt = [data objectForKey:@"backImage"];
	if (dt) mBackImage = [[NSImage alloc] initWithData:dt];
	
	dt = [data objectForKey:@"frontImage"];
	if (dt) mFrontImage = [[NSImage alloc] initWithData:dt];
	
	SBSliderCell *scell = (SBSliderCell*)mCell;
	if (scell) [scell setBackImage:mBackImage frontImage:mFrontImage];
	
	return YES;
}

- (int) controller
{
	return mType;
}

- (void) setController:(int)controller
{
	mType = controller;
	if (mControllerType)
	{
		int c = gControllerTypesCount, i;
		for (i = 0; i < c; i++)
		{
			if (gControllerTypes[i].num == mType)
			{
				[mControllerType selectItemAtIndex:i];
				break;
			}
		}
	}
}

- (BOOL) useController
{
	return YES;
}

- (id) savePreset
{
	NSMutableArray *a = [[[NSMutableArray alloc] init] autorelease];
	if (a)
	{
		[a addObject:[NSNumber numberWithDouble:[self currentValueForParameter:0]]];
		[a addObject:[NSNumber numberWithInt:mChannel]];
		[a addObject:[NSNumber numberWithInt:mType]];
	}
	return a;
}

- (void) loadPreset:(id)preset
{
	NSArray *a = preset;
	if (a)
	{
		[self takeValue:[[a objectAtIndex:0] doubleValue] offsetToChange:0 forParameter:0];
		[self setChannel:[[a objectAtIndex:1] intValue]];
		[self setController:[[a objectAtIndex:2] intValue]];
	}
}

- (SBCell*) createCell
{
	SBSliderCell *cell;
	if (mTypeOfCell == 0) cell = [[SBSliderCell alloc] init];
	else if (mTypeOfCell == 1) cell = [[SBSliderHorCell alloc] init];
	else cell = [[SBSliderVerCell alloc] init];
	
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

- (IBAction) changedShowNumber:(id) sender
{
	mCalculatedFrame = NO;
	[(SBSliderCell *)mCell setShowValue:([mShowNumber state] == NSOnState)];
	[self didChangeGlobalView];
}

- (IBAction) changedTypeOfCell:(id) sender
{
	mTypeOfCell = [mTypeOfCellPopUp indexOfSelectedItem];
	SBCell *cell = mCell;
	mCell = [self createCell];
	if (cell)
	{
		[mCell setColorsBack:[cell backColor]
					 contour:[cell contourColor]
					   front:[cell frontColor]];
		[(SBSliderCell *)mCell setShowValue:[(SBSliderCell *)cell showsValue]];
		[(SBSliderCell *)mCell setBackImage:mBackImage frontImage:mFrontImage];
		[mSliderWidthTF setIntValue:[(SBSliderCell *)mCell sliderWidth]];
		[mSliderHeightTF setIntValue:[(SBSliderCell *)mCell sliderHeight]];
		[cell release];
	}
	mCalculatedFrame = NO;
	[self didChangeGlobalView];
}

- (IBAction) changedWholeNumberOnly:(id)sender
{
	mWholeNumberOnly = ([mWholeNumberOnlyBt state] == NSOnState);
	[self takeValue:mTargetValue[0] offsetToChange:0 forParameter:0];
}

- (IBAction) changedImages:(id)sender
{
	NSImage *nback = [[mBackImageView image] retain];
	NSImage *nfront = [[mFrontImageView image] retain];
	
	if (mBackImage) [mBackImage release];
	if (mFrontImage) [mFrontImage release];
	
	mBackImage = nback;
	mFrontImage = nfront;
	
	SBSliderCell *cell = (SBSliderCell*)mCell;
	if (cell)
	{
		[cell setBackImage:mBackImage frontImage:mFrontImage];
		[self didChangeGlobalView];
	}
}


@end
