/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPreferenceServer.h"

BOOL gShowWireAnchors = YES;
BOOL gShowGuiDesignGrid = YES;
float gBackgroundColor[3] = { 255.f/255.f, 223.f/255.f, 131.f/255.f };

@implementation SBPreferenceServer

// gui stuff
- (void) awakeFromNib
{
	//[super awakeFromNib];
	[[NSColorPanel sharedColorPanel] setShowsAlpha:YES];

	[mShowWireAnchors setState:(gShowWireAnchors) ? NSOnState : NSOffState];
	[mShowGuiDesignGrid setState:(gShowGuiDesignGrid) ? NSOnState : NSOffState];
	[mColorWellBack setColor:
		[NSColor colorWithCalibratedRed:gBackgroundColor[0]
								  green:gBackgroundColor[1]
								   blue:gBackgroundColor[2]
								  alpha:1] ];
}

- (IBAction) changedWireAnchors:(id)sender
{
	gShowWireAnchors = ([mShowWireAnchors state] == NSOnState);
	[mShowWireAnchors setState:(gShowWireAnchors) ? NSOnState : NSOffState];
	[self savePref];
	[self updateCircuits];
}

- (IBAction) changedGuiDesignGrid:(id)sender
{
	gShowGuiDesignGrid = ([mShowGuiDesignGrid state] == NSOnState);
	[mShowGuiDesignGrid setState:(gShowGuiDesignGrid) ? NSOnState : NSOffState];
	[self savePref];
	[self updateCircuits];
}

- (IBAction) changedBackColor:(id)sender
{
	NSColor *color = [[mColorWellBack color] colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	gBackgroundColor[0] = [color redComponent];
	gBackgroundColor[1] = [color greenComponent];
	gBackgroundColor[2] = [color blueComponent];
	[mColorWellBack setColor:
		[NSColor colorWithCalibratedRed:gBackgroundColor[0]
								  green:gBackgroundColor[1]
								   blue:gBackgroundColor[2]
								  alpha:1] ];
	[self savePref];
	[self updateCircuits];
}
// no more gui stuff below

- (id) init
{
	self = [super init];
	if (self != nil)
		{ [self loadPref]; }
	return self;
}

+ (void) loadPref
{
//	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];

	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *ud = [userDefaults persistentDomainForName:@"com.sonicbirth.application"];
	
	NSNumber *n;
	
	n = [ud objectForKey:@"showWireAnchors"];
	if (n) gShowWireAnchors = ([n intValue] == 2);
	
	n = [ud objectForKey:@"showGuiDesignGrid"];
	if (n) gShowGuiDesignGrid = ([n intValue] == 2);
	
	n = [ud objectForKey:@"backColor_r"];
	if (n) gBackgroundColor[0] = [n floatValue];
	
	n = [ud objectForKey:@"backColor_g"];
	if (n) gBackgroundColor[1] = [n floatValue];
	
	n = [ud objectForKey:@"backColor_b"];
	if (n) gBackgroundColor[2] = [n floatValue];
}

- (void) loadPref
{
	[SBPreferenceServer loadPref];
}

- (void) savePref
{
	NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
	NSNumber *n;

	n = [NSNumber numberWithInt:(gShowWireAnchors) ? 2 : 1];
	[ud setObject:n forKey:@"showWireAnchors"];
	
	n = [NSNumber numberWithInt:(gShowGuiDesignGrid) ? 2 : 1];
	[ud setObject:n forKey:@"showGuiDesignGrid"];
	
	n = [NSNumber numberWithFloat:gBackgroundColor[0]];
	[ud setObject:n forKey:@"backColor_r"];
	
	n = [NSNumber numberWithFloat:gBackgroundColor[1]];
	[ud setObject:n forKey:@"backColor_g"];
	
	n = [NSNumber numberWithFloat:gBackgroundColor[2]];
	[ud setObject:n forKey:@"backColor_b"];
}

- (void) updateCircuits
{
	NSDocumentController *dc = [NSDocumentController sharedDocumentController];
	NSArray *docs = [dc documents];
	int i, c = [docs count];
	for (i = 0; i < c; i++)
	{
		NSDocument *cur = [docs objectAtIndex:i];
		NSView *cView = [cur performSelector:@selector(circuitView) withObject:nil];
		if (cView) [cView setNeedsDisplay:YES];
	}
}

@end
