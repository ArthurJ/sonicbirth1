/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/#import "SBEditCell.h"

@interface SBEditFloatCell : SBEditCell
{
	double mValue;
}

- (void) setValue:(double)value;
- (double) value;

@end
