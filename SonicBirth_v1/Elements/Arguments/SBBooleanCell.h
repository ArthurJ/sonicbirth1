/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@class SBArgument;

@interface SBBooleanCell : SBCell
{
	SBArgument	*mArgument;
	int			mParameter;
	BOOL		mMouseLock;
	
	ogImage		*mOffImage;
	ogImage		*mMidImage;
	ogImage		*mOnImage;
	int			mWidth, mHeight;
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx;
- (void) setOffImage:(NSImage*)off midImage:(NSImage*)mid onImage:(NSImage*)on;

@end
