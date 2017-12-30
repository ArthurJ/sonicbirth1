/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRootCircuitMidiCell.h"

@implementation SBRootCircuitMidiCell

- (void) setArgument:(SBArgument*)argument
{
	mArgument = argument;
}

- (NSSize) contentSize
{
	NSSize s = { kButtonWidth, kButtonHeight * 3}; 
	return s;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	mParameter = 0;
	[super drawContentAtPoint:origin];
	
	mParameter = 1;
	origin.y += kButtonHeight;
	[super drawContentAtPoint:origin];
	
	mParameter = 2;
	origin.y += kButtonHeight;
	[super drawContentAtPoint:origin];
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (x < 0 || x >= kButtonWidth || y < 0 || y >= (kButtonHeight*3))	return NO;
	
	mParameter = y / kButtonHeight;
	if (mParameter < 0) mParameter = 0;
	else if (mParameter > 2) mParameter = 2;
	
	y -= mParameter * kButtonHeight;
	
	return [super mouseDownX:x Y:y clickCount:clickCount];
}

@end
