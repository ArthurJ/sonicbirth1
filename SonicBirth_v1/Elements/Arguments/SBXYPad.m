/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBXYPad.h"
#import "SBXYPadCell.h"

@implementation SBXYPad

+ (NSString*) name
{
	return @"XY Pad";
}

- (NSString*) informations
{
	return @"Two sliders combined in a XY pad.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBXYPad" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mNumberOfOutputs = 2;
	
		// x init
		mMin_x = 0.;
		mMax_x = 1.;
		mMapping_x = 0;
		mType_x = 0;
		
		// y init
		mMin_y = 0.;
		mMax_y = 1.;
		mMapping_y = 0;
		mType_y = 0;
		
		// size init
		mWidth = mHeight = 100;
		mRadius = 10;
		
		SBXYPadCell *cell = (SBXYPadCell*)mCell;
		if (cell) [cell setWidth:mWidth height:mHeight radius:mRadius];

		[mName setString:@"xypad"];
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

	// x slider
	[mRangeMinTF_x setDoubleValue:mMin_x];
	[mRangeMaxTF_x setDoubleValue:mMax_x];
	[mDefaultTF_x setDoubleValue:mTargetValue[0]];
	
	if (mMapping_x == 0)
	{
		[mSlider_x setMinValue:mMin_x];
		[mSlider_x setMaxValue:mMax_x];
		[mSlider_x setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider_x setMinValue:lin2log(mMin_x, mMin_x, mMax_x)];
		[mSlider_x setMaxValue:lin2log(mMax_x, mMin_x, mMax_x)];
		[mSlider_x setDoubleValue:lin2log(mTargetValue[0], mMin_x, mMax_x)];
	}
	[mMappingPopUp_x selectItemAtIndex:mMapping_x];
	[mTypePopUp_x selectItemAtIndex:mType_x];
	
	// y slider
	[mRangeMinTF_y setDoubleValue:mMin_y];
	[mRangeMaxTF_y setDoubleValue:mMax_y];
	[mDefaultTF_y setDoubleValue:mTargetValue[1]];
	
	if (mMapping_y == 0)
	{
		[mSlider_y setMinValue:mMin_y];
		[mSlider_y setMaxValue:mMax_y];
		[mSlider_y setDoubleValue:mTargetValue[1]];
	}
	else
	{
		[mSlider_y setMinValue:lin2log(mMin_y, mMin_y, mMax_y)];
		[mSlider_y setMaxValue:lin2log(mMax_y, mMin_y, mMax_y)];
		[mSlider_y setDoubleValue:lin2log(mTargetValue[1], mMin_y, mMax_y)];
	}
	[mMappingPopUp_y selectItemAtIndex:mMapping_y];
	[mTypePopUp_y selectItemAtIndex:mType_y];
	
	// size
	[mWidthTF setDoubleValue:mWidth];
	[mHeightTF setDoubleValue:mHeight];
	[mRadiusTF setDoubleValue:mRadius];
	
	if (mBackImage) [mBackImageView setImage:mBackImage];
	if (mFrontImage) [mFrontImageView setImage:mFrontImage];
}

- (IBAction) sliderMoved_x:(id)sender
{
	double nval = [mSlider_x doubleValue];

	if (mMapping_x == 1)
		nval = log2lin(nval, mMin_x, mMax_x);

	[self setValue:nval forOutput:0 offsetToChange:0];
	[mDefaultTF_x setDoubleValue:mTargetValue[0]];
	[self didChangeView];
}

- (IBAction) sliderMoved_y:(id)sender
{
	double nval = [mSlider_y doubleValue];

	if (mMapping_y == 1)
		nval = log2lin(nval, mMin_y, mMax_y);

	[self setValue:nval forOutput:1 offsetToChange:0];
	[mDefaultTF_y setDoubleValue:mTargetValue[1]];
	[self didChangeView];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[super controlTextDidEndEditing:aNotification];

	BOOL changedX = NO, changedY = NO, changedS = NO;

	id tf = [aNotification object];
	
	// x
	if (tf == mRangeMinTF_x)
	{
		mMin_x = [mRangeMinTF_x doubleValue];
		if (mMin_x > mTargetValue[0]) [self setValue:mMin_x forOutput:0 offsetToChange:0];
		if (mMin_x > mMax_x) mMax_x = mMin_x;
		changedX = YES;
	}
	else if (tf == mRangeMaxTF_x)
	{
		mMax_x = [mRangeMaxTF_x doubleValue];
		if (mMax_x < mTargetValue[0]) [self setValue:mMax_x forOutput:0 offsetToChange:0];
		if (mMin_x > mMax_x) mMin_x = mMax_x;
		changedX = YES;
	}
	else if (tf == mDefaultTF_x)
	{
		double temp = [mDefaultTF_x doubleValue];
		if (temp < mMin_x) temp = mMin_x;
		if (temp > mMax_x) temp = mMax_x;
		[self setValue:temp forOutput:0 offsetToChange:0];
		changedX = YES;
	}
	
	// y
	else if (tf == mRangeMinTF_y)
	{
		mMin_y = [mRangeMinTF_y doubleValue];
		if (mMin_y > mTargetValue[1]) [self setValue:mMin_y forOutput:1 offsetToChange:0];
		if (mMin_y > mMax_y) mMax_y = mMin_y;
		changedY = YES;
	}
	else if (tf == mRangeMaxTF_y)
	{
		mMax_y = [mRangeMaxTF_y doubleValue];
		if (mMax_y < mTargetValue[1]) [self setValue:mMax_y forOutput:1 offsetToChange:0];
		if (mMin_y > mMax_y) mMin_y = mMax_y;
		changedY = YES;
	}
	else if (tf == mDefaultTF_y)
	{
		double temp = [mDefaultTF_y doubleValue];
		if (temp < mMin_y) temp = mMin_y;
		if (temp > mMax_y) temp = mMax_y;
		[self setValue:temp forOutput:1 offsetToChange:0];
		changedY = YES;
	}
	
	// size
	else if (tf == mWidthTF)
	{
		float temp = [mWidthTF floatValue];
		if (temp < 20) temp = 20; else if (temp > 1000) temp = 1000;
		mWidth = temp;
		changedS = YES;
	}
	else if (tf == mHeightTF)
	{
		float temp = [mHeightTF floatValue];
		if (temp < 20) temp = 20; else if (temp > 1000) temp = 1000;
		mHeight = temp;
		changedS = YES;
	}
	else if (tf == mRadiusTF)
	{
		float temp = [mRadiusTF floatValue];
		if (temp < 2) temp = 2; else if (temp > 100) temp = 100;
		mRadius = temp;
		changedS = YES;
	}
	
	if (changedX)
	{
		[mRangeMaxTF_x setDoubleValue:mMax_x];
		[mRangeMinTF_x setDoubleValue:mMin_x];
		[mDefaultTF_x setDoubleValue:mTargetValue[0]];
		if (mMapping_x == 0)
		{
			[mSlider_x setMinValue:mMin_x];
			[mSlider_x setMaxValue:mMax_x];
			[mSlider_x setDoubleValue:mTargetValue[0]];
		}
		else
		{
			[mSlider_x setMinValue:lin2log(mMin_x, mMin_x, mMax_x)];
			[mSlider_x setMaxValue:lin2log(mMax_x, mMin_x, mMax_x)];
			[mSlider_x setDoubleValue:lin2log(mTargetValue[0], mMin_x, mMax_x)];
		}
		[self didChangeView];
	}
	else if (changedY)
	{
		[mRangeMaxTF_y setDoubleValue:mMax_y];
		[mRangeMinTF_y setDoubleValue:mMin_y];
		[mDefaultTF_y setDoubleValue:mTargetValue[1]];
		if (mMapping_y == 0)
		{
			[mSlider_y setMinValue:mMin_y];
			[mSlider_y setMaxValue:mMax_y];
			[mSlider_y setDoubleValue:mTargetValue[1]];
		}
		else
		{
			[mSlider_y setMinValue:lin2log(mMin_y, mMin_y, mMax_y)];
			[mSlider_y setMaxValue:lin2log(mMax_y, mMin_y, mMax_y)];
			[mSlider_y setDoubleValue:lin2log(mTargetValue[1], mMin_y, mMax_y)];
		}
		[self didChangeView];
	}
	else if (changedS)
	{
		SBXYPadCell *cell = (SBXYPadCell*)mCell;
		if (cell)
		{
			[cell setWidth:mWidth height:mHeight radius:mRadius];
			
			NSSize sz = [cell contentSize];
			mWidth = sz.width;
			mHeight = sz.height;
			mRadius = [cell padRadius];
			
			[self didChangeGlobalView];
		}
		
		[mWidthTF setFloatValue:mWidth];
		[mHeightTF setFloatValue:mHeight];
		[mRadiusTF setFloatValue:mRadius];
	}
	[self didChangeParameterInfo];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mMin_x] forKey:@"min_x"];
	[md setObject:[NSNumber numberWithDouble:mMax_x] forKey:@"max_x"];
	[md setObject:[NSNumber numberWithDouble:mTargetValue[0]] forKey:@"val_x"];
	[md setObject:[NSNumber numberWithInt:mMapping_x] forKey:@"mapping_x"];
	[md setObject:[NSNumber numberWithInt:mType_x] forKey:@"type_x"];
	
	[md setObject:[NSNumber numberWithDouble:mMin_x] forKey:@"min_y"];
	[md setObject:[NSNumber numberWithDouble:mMax_x] forKey:@"max_y"];
	[md setObject:[NSNumber numberWithDouble:mTargetValue[1]] forKey:@"val_y"];
	[md setObject:[NSNumber numberWithInt:mMapping_x] forKey:@"mapping_y"];
	[md setObject:[NSNumber numberWithInt:mType_x] forKey:@"type_y"];
	
	[md setObject:[NSNumber numberWithFloat:mWidth] forKey:@"width"];
	[md setObject:[NSNumber numberWithFloat:mHeight] forKey:@"height"];
	[md setObject:[NSNumber numberWithFloat:mRadius] forKey:@"radius"];
	
	if (mBackImage) [md setObject:[mBackImage TIFFRepresentation] forKey:@"backImage"];
	if (mFrontImage) [md setObject:[mFrontImage TIFFRepresentation] forKey:@"frontImage"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	// x
	n = [data objectForKey:@"min_x"];
	if (n) mMin_x = [n doubleValue];
	
	n = [data objectForKey:@"max_x"];
	if (n) mMax_x = [n doubleValue];
	
	n = [data objectForKey:@"val_x"];
	if (n) [self setValue:[n doubleValue] forOutput:0 offsetToChange:0];
	
	n = [data objectForKey:@"mapping_x"];
	if (n) mMapping_x = [n intValue];
	
	n = [data objectForKey:@"type_x"];
	if (n) mType_x = [n intValue];
	
	// y
	n = [data objectForKey:@"min_y"];
	if (n) mMin_y = [n doubleValue];
	
	n = [data objectForKey:@"max_y"];
	if (n) mMax_y = [n doubleValue];
	
	n = [data objectForKey:@"val_y"];
	if (n) [self setValue:[n doubleValue] forOutput:1 offsetToChange:0];
	
	n = [data objectForKey:@"mapping_y"];
	if (n) mMapping_y = [n intValue];
	
	n = [data objectForKey:@"type_y"];
	if (n) mType_y = [n intValue];
	
	// size
	n = [data objectForKey:@"width"];
	if (n) mWidth = [n doubleValue];
	
	n = [data objectForKey:@"height"];
	if (n) mHeight = [n doubleValue];
	
	n = [data objectForKey:@"radius"];
	if (n) mRadius = [n doubleValue];
	
	NSData *dt;
	
	dt = [data objectForKey:@"backImage"];
	if (dt) mBackImage = [[NSImage alloc] initWithData:dt];
	
	dt = [data objectForKey:@"frontImage"];
	if (dt) mFrontImage = [[NSImage alloc] initWithData:dt];
	
	SBXYPadCell *cell = (SBXYPadCell*)mCell;
	if (cell)
	{
		[cell setWidth:mWidth height:mHeight radius:mRadius];
		[cell setBackImage:mBackImage frontImage:mFrontImage];
		
		
		NSSize sz = [cell contentSize];
		mWidth = sz.width;
		mHeight = sz.height;
		mRadius = [cell padRadius];
		
		//[self didChangeGlobalView];
	}
	return YES;
}

- (IBAction) changedTypeOrMapping_x:(id)sender
{
	mMapping_x = [mMappingPopUp_x indexOfSelectedItem];
	mType_x = [mTypePopUp_x indexOfSelectedItem];
	if (mMapping_x == 0)
	{
		[mSlider_x setMinValue:mMin_x];
		[mSlider_x setMaxValue:mMax_x];
		[mSlider_x setDoubleValue:mTargetValue[0]];
	}
	else
	{
		[mSlider_x setMinValue:lin2log(mMin_x, mMin_x, mMax_x)];
		[mSlider_x setMaxValue:lin2log(mMax_x, mMin_x, mMax_x)];
		[mSlider_x setDoubleValue:lin2log(mTargetValue[0], mMin_x, mMax_x)];
	}
}

- (IBAction) changedTypeOrMapping_y:(id)sender
{
	mMapping_y = [mMappingPopUp_y indexOfSelectedItem];
	mType_y = [mTypePopUp_y indexOfSelectedItem];
	if (mMapping_y == 0)
	{
		[mSlider_y setMinValue:mMin_y];
		[mSlider_y setMaxValue:mMax_y];
		[mSlider_y setDoubleValue:mTargetValue[1]];
	}
	else
	{
		[mSlider_y setMinValue:lin2log(mMin_y, mMin_y, mMax_y)];
		[mSlider_y setMaxValue:lin2log(mMax_y, mMin_y, mMax_y)];
		[mSlider_y setDoubleValue:lin2log(mTargetValue[1], mMin_y, mMax_y)];
	}
}

- (double) minValueForParameter:(int)i;
{
	return (i == 0) ? mMin_x : mMin_y;
}

- (double) maxValueForParameter:(int)i;
{
	return (i == 0) ? mMax_x : mMax_y;
}

- (BOOL) logarithmicForParameter:(int)i;
{
	if (i == 0) return (mMapping_x == 1);
	return (mMapping_y == 1);
}

- (SBParameterType) typeForParameter:(int)i;
{
	int type = (i == 0) ? mType_x : mType_y;
	switch(type)
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


- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i;
{
	if (i == 0)
	{
		if (preset < mMin_x) preset = mMin_x;
		else if (preset > mMax_x) preset = mMax_x;
		
		[self setValue:preset forOutput:0 offsetToChange:offset];
		if (mSlider_x)
		{
			if (mMapping_x == 0)
				[mSlider_x setDoubleValue:mTargetValue[0]];
			else
				[mSlider_x setDoubleValue:lin2log(mTargetValue[0], mMin_x, mMax_x)];
		}
		if (mDefaultTF_x) [mDefaultTF_x setDoubleValue:mTargetValue[0]];
		[self didChangeView];
	}
	else if (i == 1)
	{
		if (preset < mMin_y) preset = mMin_y;
		else if (preset > mMax_y) preset = mMax_y;
		
		[self setValue:preset forOutput:1 offsetToChange:offset];
		if (mSlider_y)
		{
			if (mMapping_y == 0)
				[mSlider_y setDoubleValue:mTargetValue[1]];
			else
				[mSlider_y setDoubleValue:lin2log(mTargetValue[1], mMin_y, mMax_y)];
		}
		if (mDefaultTF_y) [mDefaultTF_y setDoubleValue:mTargetValue[1]];
		[self didChangeView];
	}
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	if (idx == 0) return @"x";
	return @"y";
}

- (NSString*) nameForParameter:(int)i
{
	return [NSString stringWithFormat:@"%@ :: %@", mName, (i == 0) ? @"X" : @"Y"];
}

- (double) currentValueForParameter:(int)i
{
	return mTargetValue[i];
}

- (SBCell*) createCell
{
	SBXYPadCell *cell = [[SBXYPadCell alloc] init];
	if (cell) [cell setArgument:self];
	return cell;
}

- (int) numberOfParameters
{
	return 2;
}

- (IBAction) changedImages:(id)sender
{
	NSImage *nb = [[mBackImageView image] retain];
	NSImage *nf = [[mFrontImageView image] retain];
	
	if (mBackImage) [mBackImage release];
	if (mFrontImage) [mFrontImage release];
	
	mBackImage = nb;
	mFrontImage = nf;
	
	SBXYPadCell *cell = (SBXYPadCell*)mCell;
	if (cell)
	{
		[cell setBackImage:mBackImage frontImage:mFrontImage];
		
		NSSize sz = [cell contentSize];
		mWidth = sz.width;
		mHeight = sz.height;
		mRadius = [cell padRadius];
		
		[mWidthTF setFloatValue:mWidth];
		[mHeightTF setFloatValue:mHeight];
		[mRadiusTF setFloatValue:mRadius];
		
		[self didChangeGlobalView];
	}
}

@end
