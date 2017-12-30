/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBCell.h"

@interface SBGraphicObjectCell : SBCell
{
	ogImage		*mImage;
}
- (void) setImage:(NSImage*)img;
@end
