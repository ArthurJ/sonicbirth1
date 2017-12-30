/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBGraphicObjectCell.h"


@implementation SBGraphicObjectCell
- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mImage = nil;
	}
	return self;
}

- (void) dealloc
{
	if (mImage) ogReleaseImage(mImage);
	[super dealloc];
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	ogDrawImage(mImage, origin.x, origin.y);
}

- (NSSize) contentSize
{
	NSSize s = { 0, 0 }; 
	if (mImage)
	{
		s.width = ogImageWidth(mImage);
		s.height = ogImageHeight(mImage);
	}
	return s;
}

- (void) setImage:(NSImage*)img
{
	if (mImage) ogReleaseImage(mImage);
	mImage = nil;
	if (img) mImage = [img toOgImage];
}

@end
