/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBInfoServer.h"

static SBInfoServer *gLastServer = nil;

@implementation SBInfoServer

+ (SBInfoServer*) lastServer
{
	return gLastServer;
}

- (id) init
{
	self = [super init];
	if (self != nil)
		{ gLastServer = self; }
	return self;
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	if (mInfoPanel) [mInfoPanel retain];
	if (mInformations) [mInformations retain];
	
	NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"infoPanelShouldOpen"];
	if (!n || ([n intValue] == 2)) [mInfoPanel makeKeyAndOrderFront:self];
}

- (void) dealloc
{
	if (mInfoPanel) [mInfoPanel release];
	if (mInformations) [mInformations release];
	[super dealloc];
}

- (IBAction) showPanel:(id)server
{
	if (!mInfoPanel) return;
	if ([mInfoPanel isVisible])
	{
		[mInfoPanel orderOut:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"infoPanelShouldOpen"];
	}
	else
	{
		[mInfoPanel makeKeyAndOrderFront:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"infoPanelShouldOpen"];
	}
}

- (void) setString:(NSString*)string
{
	if (mInformations) [mInformations setString:string];
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([aNotification object] == mInfoPanel)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"infoPanelShouldOpen"];
	}
}

@end
