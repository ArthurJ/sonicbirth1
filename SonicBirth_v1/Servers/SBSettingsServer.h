/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

@interface SBSettingsServer : NSObject
{
	IBOutlet NSPanel		*mSettingsPanel;
	IBOutlet NSScrollView	*mScrollView;
	IBOutlet NSView			*mEmptySettings;
}

- (IBAction) showPanel:(id)server;
- (void) setSettingsView:(NSView*)view;

+ (SBSettingsServer*) lastServer;

@end
