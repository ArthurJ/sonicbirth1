/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBWindow.h"
#import "SBSoundServer.h"

@implementation SBWindow
- (void)mouseDown:(NSEvent *)theEvent
{
	[self makeFirstResponder:self];
}
- (void)keyDown:(NSEvent *)theEvent
{
	NSString *utf16 = [theEvent characters];
	unichar  ukey = [utf16 characterAtIndex: 0];

	if (ukey == ' ')
		[gSoundServer pushedPlayButton:nil];
	else
		[super keyDown:theEvent];
}
@end
