/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBNoResizeView.h"

@implementation SBNoResizeView

- (void)setFrame:(NSRect)frameRect
{
	[super setFrameOrigin:frameRect.origin];
}

@end
