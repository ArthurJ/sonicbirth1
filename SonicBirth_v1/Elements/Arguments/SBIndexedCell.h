/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBCell.h"

// used by subclass

#define kTextHeightOffset (2)
#define kTextWidthOffset (5)
#define kTextWidth (90)
#ifndef kTextHeight
#define kTextHeight (12)
#endif
#define kButtonHeight (kTextHeight + 2 * kTextHeightOffset)

#define kTriangleBoxSize (kButtonHeight)
#define kButtonWidth (kTextWidth + 2 * kTextWidthOffset + kTriangleBoxSize)


@class SBArgument;

@interface SBIndexedCell : SBCell
{
	SBArgument	*mArgument;
	int			mParameter;
	NSMutableDictionary *mStringAttributes;
	
	NSMenu		*mMenu;
	int			mMaxChars;
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx;
- (void) changedIndex:(id)sender;

@end

