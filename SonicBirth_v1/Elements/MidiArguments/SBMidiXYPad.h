/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiArgument.h"

@interface SBMidiXYPad : SBMidiArgument
{
	IBOutlet NSView			*mSettingsView;
	
	IBOutlet NSPopUpButton	*mControllerType;

	// x slider
	IBOutlet NSTextField	*mRangeMinTF_x;
	IBOutlet NSTextField	*mRangeMaxTF_x;
	IBOutlet NSTextField	*mDefaultTF_x;
	IBOutlet NSSlider		*mSlider_x;
	IBOutlet NSPopUpButton	*mMappingPopUp_x;
	IBOutlet NSPopUpButton	*mTypePopUp_x;
	
	int mMapping_x;
	int mType_x;
	double mMin_x, mMax_x;
	
	// y slider
	IBOutlet NSTextField	*mRangeMinTF_y;
	IBOutlet NSTextField	*mRangeMaxTF_y;
	IBOutlet NSTextField	*mDefaultTF_y;
	IBOutlet NSSlider		*mSlider_y;
	IBOutlet NSPopUpButton	*mMappingPopUp_y;
	IBOutlet NSPopUpButton	*mTypePopUp_y;

	int mMapping_y;
	int mType_y;
	double mMin_y, mMax_y;
	
	int mType;
//	int mLastMSB;
//	int mLastLSB;
	
	// size
	IBOutlet NSTextField	*mWidthTF;
	IBOutlet NSTextField	*mHeightTF;
	IBOutlet NSTextField	*mRadiusTF;
	
	float mWidth, mHeight, mRadius;
	NSImage *mBackImage;
	NSImage *mFrontImage;
	IBOutlet NSImageView *mBackImageView;
	IBOutlet NSImageView *mFrontImageView;
}

- (IBAction) changedImages:(id)sender;

- (IBAction) sliderMoved_x:(id)sender;
- (IBAction) changedTypeOrMapping_x:(id)sender;

- (IBAction) sliderMoved_y:(id)sender;
- (IBAction) changedTypeOrMapping_y:(id)sender;

- (IBAction) changedControllerType:(id)sender;

@end
