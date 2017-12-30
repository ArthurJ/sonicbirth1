/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import <CoreMIDI/CoreMIDI.h>

@interface SBMidiServer : NSObject
{
	IBOutlet	NSPopUpButton	*mSources;
	IBOutlet	NSPanel			*mMidiPanel;
	
	MIDIClientRef	mClient;
	MIDIPortRef		mPort;
	MIDIEndpointRef	mSource;
}

- (void) updateSetup;

- (IBAction) showPanel:(id)server;
- (IBAction) changedSource:(id)server;

- (void) handlePackets:(const MIDIPacketList *)pktlist;

@end
