/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiServer.h"
#import "SBAudioProcess.h"
#import "SBSoundServer.h"

// check AUMidiBase.cpp :: NextMIDIEvent

static inline const unsigned char *NextMIDIEvent(const unsigned char *event, const unsigned char *end)
{
	unsigned char c = *event;
	switch (c >> 4)
	{

		case 0x8:
		case 0x9:
		case 0xA:
		case 0xB:
		case 0xE:
			event += 3;
			break;
			
		case 0xC:
		case 0xD:
			event += 2;
			break;
			
		case 0xF:
			switch (c)
			{
				case 0xF0:
					while ((*++event & 0x80) == 0 && event < end) ;
					break;
					
				case 0xF1:
				case 0xF3:
					event += 2;
					break;
					
				case 0xF2:
					event += 3;
					break;
					
				default:
					++event;
					break;
			}
			
		default:	// data byte -- assume in sysex
			while ((*++event & 0x80) == 0 && event < end) ;
			break;
	}
	
	return (event >= end) ? end : event;
}

static void readCallback(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcConnRefCon)
{
	[(SBMidiServer*)readProcRefCon handlePackets:pktlist];
}

static void midiNotifyCallback(const MIDINotification *message, void *refCon)
{
	if (message->messageID == kMIDIMsgObjectAdded || message->messageID == kMIDIMsgObjectRemoved)
		[(SBMidiServer*)refCon updateSetup];
}

@implementation SBMidiServer

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		mSource = nil;
		mClient = nil;
		mPort = nil;
	
		OSStatus err;
		err = MIDIClientCreate(	(CFStringRef)([[NSProcessInfo processInfo] globallyUniqueString]), 
								midiNotifyCallback,
								self,
								&mClient);
		if (err != noErr || !mClient)
		{
			[self release];
			return nil;
		}
		
		err = MIDIInputPortCreate(mClient, 
									(CFStringRef)(NSString*)(@"port"), 
									readCallback, 
									self, 
									&mPort);
		if (err != noErr || !mPort)
		{
			[self release];
			return nil;
		}
		
		int sources = MIDIGetNumberOfSources();
		if (sources > 0)
		{
			mSource = MIDIGetSource(0);
			if (mSource)
			{
				OSStatus errResult = MIDIPortConnectSource(mPort, mSource, nil);
				if (errResult != noErr)
					mSource = nil;
			}
		}
	}
	return self;
}

- (void) dealloc
{
	if (mPort && mSource) MIDIPortDisconnectSource(mPort, mSource);
	if (mPort) MIDIPortDispose(mPort);
	if (mClient) MIDIClientDispose(mClient);
	
	[super dealloc];
}


- (void) updateSetup
{
	int i;
	int sources = MIDIGetNumberOfSources();
	
	[mSources removeAllItems];
	[mSources addItemWithTitle:@"None"];
	[mSources selectItemAtIndex:0];
	BOOL foundOurSource = NO;
	for (i = 0; i < sources; i++)
	{
		MIDIEndpointRef src = MIDIGetSource(i);
		CFStringRef name = nil, model = nil, manuf = nil;
		OSStatus err;
		
		err = MIDIObjectGetStringProperty((MIDIObjectRef)src, 
											kMIDIPropertyName, 
											&name);
		if (err) name = nil;
										
		err = MIDIObjectGetStringProperty((MIDIObjectRef)src, 
											kMIDIPropertyModel, 
											&model);
		if (err) model = nil;
										
		err = MIDIObjectGetStringProperty((MIDIObjectRef)src, 
											kMIDIPropertyManufacturer, 
											&manuf);
		if (err) manuf = nil;

		[mSources addItemWithTitle:[NSString stringWithFormat:@"%@ :: %@ :: %@",
								(manuf) ? (NSString*)manuf : @"Unknown",
								(model) ? (NSString*)model : @"Unknown",
								(name) ? (NSString*)name : @"Unknown"]];
			
		if (manuf) CFRelease(manuf);
		if (model) CFRelease(model);
		if (name) CFRelease(name);
		
		if (mSource == src)
		{
			[mSources selectItemAtIndex:i + 1];
			foundOurSource = YES;
		}
	}
	
	if (mSource && !foundOurSource) // our source diappeared
	{
		MIDIPortDisconnectSource(mPort, mSource);
		mSource = nil;
	}
}

- (void) awakeFromNib
{
	//[super awakeFromNib];

	[self updateSetup];
	
	NSNumber *n = [[NSUserDefaults standardUserDefaults] objectForKey:@"midiPanelShouldOpen"];
	if (!n || ([n intValue] == 2)) [mMidiPanel makeKeyAndOrderFront:self];
}

- (IBAction) showPanel:(id)server
{
	if (!mMidiPanel) return;
	if ([mMidiPanel isVisible])
	{
		[mMidiPanel orderOut:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"midiPanelShouldOpen"];
	}
	else
	{
		[mMidiPanel makeKeyAndOrderFront:self];
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:2] forKey:@"midiPanelShouldOpen"];
	}
}

- (void)windowWillClose:(NSNotification *)aNotification
{
	if ([aNotification object] == mMidiPanel)
	{
		[[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:1] forKey:@"midiPanelShouldOpen"];
	}
}

- (IBAction) changedSource:(id)server
{
	if (mSource) MIDIPortDisconnectSource(mPort, mSource);
	mSource = nil;
	
	int i = [mSources indexOfSelectedItem];
	if (i != 0)
	{
		mSource = MIDIGetSource(i - 1);
		if (mSource)
		{
			OSStatus err = MIDIPortConnectSource(mPort, mSource, nil);
			if (err != noErr)
				mSource = nil;
		}
	}
}

- (void) handlePackets:(const MIDIPacketList *)packetList
{
	if (!gSoundServer) return;
	
	SBAudioProcess *ap = [gSoundServer currentAudioProcess];
	if (!ap) return;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	// check AUMidiBase.cpp :: HandleMIDIPacketList

	const MIDIPacket *packet = &packetList->packet[0];
	int numPackets = packetList->numPackets;
	
	for (int i = 0; i < numPackets; i++)
	{
		const unsigned char *event = packet->data, *packetEnd = event + packet->length;
		// long startFrame = (long)packet->timeStamp;
		while (event < packetEnd)
		{
			unsigned char status = event[0];
			if (status & 0x80)
			{
				// HandleMidiEvent(status & 0xF0, status & 0x0F, event[1], event[2], startFrame);
				int sta = status & 0xF0;
				int cha = status & 0x0F;
				[ap dispatchMidiEvent:sta channel:cha data1:event[1] data2:event[2] offsetToChange:0];
			}
			event = NextMIDIEvent(event, packetEnd);
		}
		packet = MIDIPacketNext(packet);
	}
	
	[pool release];
}

@end
