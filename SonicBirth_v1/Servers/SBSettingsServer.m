/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSettingsServer.h"

static SBSettingsServer *gLastServer = nil;

@implementation SBSettingsServer

+ (SBSettingsServer*) lastServer
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

	[self setSettingsView:nil];
	if (mSettingsPanel) [mSettingsPanel retain];
	if (mScrollView) [mScrollView retain];
	
	NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"settingsPanelShouldOpen"];
	if (!n || ([n intValue] == 2)) [mSettingsPanel makeKeyAndOrderFront:self];
}

- (void) dealloc
{
	if (mSettingsPanel) [mSettingsPanel release];
	if (mScrollView) [mScrollView release];
	[super dealloc];
}


- (IBAction) showPanel:(id)server
{
	if (!mSettingsPanel) return;
	if ([mSettingsPanel isVisible])
	{
		[mSettingsPanel orderOut:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"settingsPanelShouldOpen"];
	}
	else
	{
		[mSettingsPanel makeKeyAndOrderFront:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"settingsPanelShouldOpen"];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([aNotification object] == mSettingsPanel)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"settingsPanelShouldOpen"];
	}
}

- (void) setSettingsView:(NSView*)view
{
	if (!view) view = mEmptySettings;
	if (!view) return;
	
	if (mSettingsPanel)
	{
		NSRect viewFrame = [view frame];
	
		[mSettingsPanel setContentView:view];	
		
		NSRect panelFrame = [mSettingsPanel frame];
		NSPoint topleft = panelFrame.origin;
		topleft.y += panelFrame.size.height;
		
		// NSLog(@"bef top left x: %f y: %f", topleft.x, topleft.y);
		
		NSRect newRect = [NSPanel frameRectForContentRect:viewFrame styleMask:[mSettingsPanel styleMask]];
		newRect.origin = topleft;
		newRect.origin.y -= newRect.size.height;
		
		// NSLog(@"aft top left x: %f y: %f", topleft.x, topleft.y);
		
		[mSettingsPanel setFrame:newRect display:YES animate:NO];
		
		[view setFrame:viewFrame];
	}
	else if (mScrollView)
	{
		[mScrollView setDocumentView:view];
		
		// try to scroll to top left
		NSClipView *clipView = [mScrollView contentView];
		NSClipView *docView = [mScrollView documentView];
		NSSize ctSize = [clipView frame].size;
		NSSize docSize = [docView frame].size;
		NSPoint pt = {0, docSize.height - ctSize.height};
		[clipView scrollToPoint:pt];
		[mScrollView reflectScrolledClipView:clipView];
	}
	
}

@end
