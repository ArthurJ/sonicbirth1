/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBGraphicObject.h"
#import "SBGraphicObjectCell.h"

@implementation SBGraphicObject

+ (NSString*) name
{
	return @"Graphic Object";
}

+ (SBElementCategory) category
{
	return kDisplay;
}


- (NSString*) informations
{
	return @"Just a graphic object doing nothing.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBGraphicObject" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[mName setString:@"graph obj"];
		mGOImage = nil;
		mNumberOfOutputs = 0;
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	if (mGOImage) [(mGOImage) release];
	[super dealloc];
}

- (void) awakeFromNib
{
	[super awakeFromNib];
	if (mGOImage) [mGOImageView setImage:mGOImage];
}


- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	if (mGOImage) [md setObject:[mGOImage TIFFRepresentation] forKey:@"image"];

	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

		
	NSData *dt;
	
	dt = [data objectForKey:@"image"];
	if (dt) mGOImage = [[NSImage alloc] initWithData:dt];
	
	SBGraphicObjectCell *cell = (SBGraphicObjectCell*)mCell;
	if (cell) [cell setImage:mGOImage];

	return YES;
}


- (int) numberOfParameters
{
	return 0;
}


- (SBCell*) createCell
{
	SBGraphicObjectCell *cell = [[SBGraphicObjectCell alloc] init];
	return cell;
}


- (IBAction) changedImage:(id)sender
{
	NSImage *nimg = [[mGOImageView image] retain];

	if (mGOImage) [mGOImage release];
	mGOImage  = nimg;
	
	SBGraphicObjectCell *cell = (SBGraphicObjectCell*)mCell;
	if (cell)
	{
		[cell setImage:mGOImage];
		[self didChangeGlobalView];
	}
}

@end
