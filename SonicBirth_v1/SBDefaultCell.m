/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBDefaultCell.h"
#import "SBElement.h"

@implementation SBDefaultCell

- (void) dealloc
{
	if (mImage) ogReleaseImage(mImage);
	[super dealloc];
}

- (void) setElement:(SBElement*)element
{
	if (mImage)
	{
		ogReleaseImage(mImage);
		mImage = nil;
	}
	mElement = element;
}

- (void) drawContentAtPoint:(NSPoint)origin
{
	if (!mImage) return;

	//NSSize imageSize = [mImage size];
	//origin.y += imageSize.height;
	//[mImage compositeToPoint:origin operation:NSCompositeSourceOver];
	
	ogDrawImage(mImage, origin.x, origin.y);
}

- (NSSize) contentSize
{
	NSSize s;
	s.width = 0;
	s.height = 0;

	if (mImage) { s.width = ogImageWidth(mImage); s.height = ogImageHeight(mImage); return s; }
	if (!mElement) return s;

	NSBundle *mainBundle = [NSBundle bundleWithIdentifier:@"com.sonicbirth.framework"];
	NSString *imagePath = [[mElement className] stringByAppendingPathExtension:@"png"];
	NSImage *image = [[NSImage alloc] initWithContentsOfFile:[mainBundle pathForImageResource:imagePath]];
	if (!image)
		image = [[NSImage alloc] initWithContentsOfFile:[mainBundle pathForImageResource:@"SBUnknown.png"]];
	if (image)
	{
		mImage = [image toOgImage];
		
		[image release];
		
		s.width = ogImageWidth(mImage);
		s.height = ogImageHeight(mImage);
	}

	return s;
}

@end
