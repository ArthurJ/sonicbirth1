/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSlider.h"
#import "SBSliderCell.h"
#import "SBSliderHorCell.h"
#import "SBSliderVerCell.h"

#include <math.h>

@implementation SBSlider

+ (NSString*) name
{
	return @"Slider";
}

- (NSString*) informations
{
	return @"Basic slider with min/max.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBSlider" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mMin = 0.;
		mMax = 1.;
		mMapping = 0;
		mType = 0;
		[mName setString:@"slider"];
		
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

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mRangeMinTF setDoubleValue:mMin];
	[mRangeMaxTF setDoubleValue:mMax];
	[mDefaultTF setDoubleValue:mTargetValue[0]];
	
	if (mMapping == 0)
	{
		[mSlider setMinValue:mMin];
		[mSlider setMaxValue:mMax];
		[mSlider setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider setMinValue:lin2log(mMin, mMin, mMax)];
		[mSlider setMaxValue:lin2log(mMax, mMin, mMax)];
		[mSlider setDoubleValue:lin2log(mTargetValue[0], mMin, mMax)];
	}
	[mMappingPopUp selectItemAtIndex:mMapping];
	[mTypePopUp selectItemAtIndex:mType];
	[mTypeOfCellPopUp selectItemAtIndex:mTypeOfCell];
	
	[mShowNumber setState:([(SBSliderCell *)mCell showsValue]) ? NSOnState : NSOffState];
	[mSliderWidthTF setIntValue:[(SBSliderCell *)mCell sliderWidth]];
	[mSliderHeightTF setIntValue:[(SBSliderCell *)mCell sliderHeight]];
	
	[mWholeNumberOnlyBt setState:(mWholeNumberOnly) ? NSOnState : NSOffState];
	
	if (mBackImage) [mBackImageView setImage:mBackImage];
	if (mFrontImage) [mFrontImageView setImage:mFrontImage];
}

- (IBAction) sliderMoved:(id)sender
{
	double nval = [mSlider doubleValue];
	
	if (mWholeNumberOnly)
		nval = floor(nval);

	if (mMapping == 1)
		nval = log2lin(nval, mMin, mMax);

	[self setValue:nval forOutput:0 offsetToChange:0];
	[mDefaultTF setDoubleValue:mTargetValue[0]];
	[self didChangeView];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[super controlTextDidEndEditing:aNotification];

	id tf = [aNotification object];
	if (tf == mRangeMinTF)
	{
		mMin = [mRangeMinTF doubleValue];
		if (mMin > mTargetValue[0]) [self setValue:mMin forOutput:0 offsetToChange:0];
		if (mMin > mMax) mMax = mMin;
	}
	else if (tf == mRangeMaxTF)
	{
		mMax = [mRangeMaxTF doubleValue];
		if (mMax < mTargetValue[0]) [self setValue:mMax forOutput:0 offsetToChange:0];
		if (mMin > mMax) mMin = mMax;
	}
	else if (tf == mDefaultTF)
	{
		double temp = [mDefaultTF doubleValue];
		if (temp < mMin) temp = mMin;
		if (temp > mMax) temp = mMax;
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
	
	[mRangeMaxTF setDoubleValue:mMax];
	[mRangeMinTF setDoubleValue:mMin];
	[mDefaultTF setDoubleValue:mTargetValue[0]];
	if (mMapping == 0)
	{
		[mSlider setMinValue:mMin];
		[mSlider setMaxValue:mMax];
		[mSlider setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider setMinValue:lin2log(mMin, mMin, mMax)];
		[mSlider setMaxValue:lin2log(mMax, mMin, mMax)];
		[mSlider setDoubleValue:lin2log(mTargetValue[0], mMin, mMax)];
	}
	[self didChangeView];
	[self didChangeParameterInfo];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mMin] forKey:@"min"];
	[md setObject:[NSNumber numberWithDouble:mMax] forKey:@"max"];
	[md setObject:[NSNumber numberWithDouble:mTargetValue[0]] forKey:@"val"];
	[md setObject:[NSNumber numberWithInt:mMapping] forKey:@"mapping"];
	[md setObject:[NSNumber numberWithInt:mType] forKey:@"type"];
	[md setObject:[NSNumber numberWithInt:([(SBSliderCell *)mCell showsValue]) ? 2 : 1] forKey:@"showsValue"];
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
	if (n) mMin = [n doubleValue];
	
	n = [data objectForKey:@"max"];
	if (n) mMax = [n doubleValue];
	
	n = [data objectForKey:@"val"];
	if (n) [self setValue:[n doubleValue] forOutput:0 offsetToChange:0];
	
	n = [data objectForKey:@"mapping"];
	if (n) mMapping = [n intValue];
	
	n = [data objectForKey:@"type"];
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

- (double) minValue
{
	return mMin;
}

- (double) maxValue
{
	return mMax;
}

- (IBAction) changedTypeOrMapping:(id)sender
{
	mMapping = [mMappingPopUp indexOfSelectedItem];
	mType = [mTypePopUp indexOfSelectedItem];
	if (mMapping == 0)
	{
		[mSlider setMinValue:mMin];
		[mSlider setMaxValue:mMax];
		[mSlider setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider setMinValue:lin2log(mMin, mMin, mMax)];
		[mSlider setMaxValue:lin2log(mMax, mMin, mMax)];
		[mSlider setDoubleValue:lin2log(mTargetValue[0], mMin, mMax)];
	}
}

- (BOOL) logarithmic
{
	return (mMapping == 1);
}

- (SBParameterType) type
{
	switch(mType)
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


- (void) takeValue:(double)preset offsetToChange:(int)offset
{
	if (mWholeNumberOnly)
		preset = floor(preset);		

	if (preset < mMin) preset = mMin;
	else if (preset > mMax) preset = mMax;
	
	[self setValue:preset forOutput:0 offsetToChange:offset];
	if (mSlider)
	{
		if (mMapping == 0)
			[mSlider setDoubleValue:mTargetValue[0]];
		else
			[mSlider setDoubleValue:lin2log(mTargetValue[0], mMin, mMax)];
	}
	if (mDefaultTF) [mDefaultTF setDoubleValue:mTargetValue[0]];
	[self didChangeView];
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
	[self takeValue:mTargetValue[0] offsetToChange:0];
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
