/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@class SBArgument;

@interface SBFocusCell : SBCell
{
	SBArgument	*mArgument;
	int			mParameter;
	
	float		mRadius;
	BOOL		mTapped;
	
	int			mClickCount;
}

- (void) setArgument:(SBArgument*)argument parameter:(int)idx;
- (void) tap;
- (void) setRadius:(float)radius;

@end
