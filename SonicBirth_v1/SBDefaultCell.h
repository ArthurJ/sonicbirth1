/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBCell.h"

@class SBElement;

@interface SBDefaultCell : SBCell
{
	SBElement	*mElement;
	ogImage		*mImage;
}

- (void) setElement:(SBElement*)element;

@end
