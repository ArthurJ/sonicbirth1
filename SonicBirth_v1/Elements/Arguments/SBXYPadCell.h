/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@class SBArgument;

@interface SBXYPadCell : SBCell
{
	float			mWidth, mHeight, mRadius;
	BOOL			mMouseLock;
	SBArgument		*mArgument;
	
	ogImage			*mBackImage;
	ogImage			*mFrontImage;
}

- (void) setArgument:(SBArgument*)argument;
- (void) setWidth:(float)width height:(float)height radius:(float)radius;
- (void) setBackImage:(NSImage*)back frontImage:(NSImage*)front; 
- (float) padRadius;

@end
