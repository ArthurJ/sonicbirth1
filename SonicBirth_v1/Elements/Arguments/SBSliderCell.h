/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"
#import "SBEditFloatCell.h"

@class SBArgument;

#define kTextMinWidth (30)
#define kTextMaxWidth (60)

@interface SBSliderCell : SBCell
{
	SBArgument	*mArgument;
	int			mParameter;
	BOOL		mMouseLock;
	
	BOOL		mShowValue;
	
	int mStartPos;
	double mStartVal;
	
	int mSliderWidth;
	int mSliderHeight;
	
	ogImage				*mBackImage;
	ogImage				*mFrontImage;
	
	SBEditFloatCell		*mValueCell;
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx;
- (void) setShowValue:(BOOL)showValue;
- (BOOL) showsValue;
- (void) setSliderWidth:(float)width;
- (void) setSliderHeight:(float)height;
- (int) sliderWidth;
- (int) sliderHeight;

- (void) drawValueContentPoint:(NSPoint)origin value:(double)value;
- (void) setBackImage:(NSImage*)back frontImage:(NSImage*)front;

@end

