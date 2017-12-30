/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBSimpleArgument.h"

@interface SBSlider : SBSimpleArgument
{
	IBOutlet NSTextField	*mSliderWidthTF;
	IBOutlet NSTextField	*mSliderHeightTF;
	IBOutlet NSTextField	*mRangeMinTF;
	IBOutlet NSTextField	*mRangeMaxTF;
	IBOutlet NSTextField	*mDefaultTF;
	IBOutlet NSSlider		*mSlider;
	IBOutlet NSView			*mSettingsView;
	
	IBOutlet NSPopUpButton	*mMappingPopUp;
	IBOutlet NSPopUpButton	*mTypePopUp;
	IBOutlet NSPopUpButton	*mTypeOfCellPopUp;
	
	IBOutlet NSButton		*mShowNumber;
	IBOutlet NSButton		*mWholeNumberOnlyBt;
	
	int mMapping;
	int mType;
	double mMin, mMax;
	BOOL mWholeNumberOnly;
	
	int mTypeOfCell;
	
	
	NSImage *mBackImage;
	NSImage *mFrontImage;
	IBOutlet NSImageView *mBackImageView;
	IBOutlet NSImageView *mFrontImageView;
}

- (IBAction) changedWholeNumberOnly:(id)sender;
- (IBAction) sliderMoved:(id)sender;
- (IBAction) changedTypeOrMapping:(id)sender;
- (IBAction) changedShowNumber:(id) sender;
- (IBAction) changedTypeOfCell:(id) sender;

- (IBAction) changedImages:(id)sender;

@end

