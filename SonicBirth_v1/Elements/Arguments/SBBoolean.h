/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBSimpleArgument.h"

@interface SBBoolean : SBSimpleArgument
{

	IBOutlet NSTextField	*mTrueValueEditTF, *mTrueValueTF;
	IBOutlet NSTextField	*mFalseValueEditTF, *mFalseValueTF;
	IBOutlet NSButton		*mButton;
	IBOutlet NSView			*mSettingsView;

	double  mTrueValue;
	double  mFalseValue;
	BOOL	mState;
	
	NSImage *mOffImage;
	NSImage *mMidImage;
	NSImage *mOnImage;
	IBOutlet NSImageView *mOffImageView;
	IBOutlet NSImageView *mMidImageView;
	IBOutlet NSImageView *mOnImageView;
}

- (IBAction) pushedButton:(id) sender;
- (IBAction) changedImages:(id)sender;

@end
