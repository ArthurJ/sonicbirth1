/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

@interface SBInfoServer : NSObject
{
	IBOutlet NSPanel		*mInfoPanel;
	IBOutlet NSTextView		*mInformations;
}

- (IBAction) showPanel:(id)server;
- (void) setString:(NSString*)string;

+ (SBInfoServer*) lastServer;

@end
