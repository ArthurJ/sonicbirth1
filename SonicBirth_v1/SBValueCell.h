/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@interface SBValueCell : SBCell
{
	double mValue;
	float mWidth;
	float mHeight;
}

- (void) setValue:(double)value;
- (void) setWidth:(float)width height:(float)height;
@end
