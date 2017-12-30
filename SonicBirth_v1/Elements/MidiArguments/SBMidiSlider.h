/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/#import "SBMidiArgument.h"

@interface SBMidiSlider : SBMidiArgument
{
	IBOutlet NSView			*mSettingsView;
	IBOutlet NSPopUpButton	*mControllerType;
	IBOutlet NSTextField	*mSliderWidthTF;
	IBOutlet NSTextField	*mSliderHeightTF;
	IBOutlet NSTextField	*mRangeMinTF;
	IBOutlet NSTextField	*mRangeMaxTF;
	IBOutlet NSTextField	*mDefaultTF;
	
	IBOutlet NSSlider		*mSlider;
	IBOutlet NSPopUpButton	*mMappingPopUp;
	IBOutlet NSPopUpButton	*mTypePopUp;
	
	IBOutlet NSButton		*mShowNumber;
	IBOutlet NSButton		*mWholeNumberOnlyBt;
	
	IBOutlet NSPopUpButton	*mTypeOfCellPopUp;
	
	int mMapping;
	int mValueType;
	
	int		mType;
	double	mRangeMin;
	double	mRangeMax;
	BOOL mWholeNumberOnly;
	
	int mLastMSB;
	int mLastLSB;
	
	int mTypeOfCell;
	
	
	NSImage *mBackImage;
	NSImage *mFrontImage;
	IBOutlet NSImageView *mBackImageView;
	IBOutlet NSImageView *mFrontImageView;
}

- (IBAction) changedWholeNumberOnly:(id)sender;
- (IBAction) sliderMoved:(id)sender;
- (IBAction) changedControllerType:(id)sender;
- (IBAction) changedTypeOrMapping:(id)sender;
- (IBAction) changedShowNumber:(id) sender;
- (IBAction) changedTypeOfCell:(id) sender;

- (IBAction) changedImages:(id)sender;

@end
