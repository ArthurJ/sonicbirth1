/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBMidiNoteState.h"

@implementation SBMidiNoteState

+ (NSString*) name
{
	return @"Midi note state";
}

- (NSString*) informations
{
	return	@"Outputs the state (pressed or not) and velocity (0 to 1) for each specified note.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBMidiNoteState" owner:self];
		return mSettingsView;
	}
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		[mName setString:@"midi note state"];
		mNumberOfOutputs = 0;
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	int note = idx >> 1;
	if (note >= kNoteCount) return @"err";
	
	BOOL velo = (idx & 1);
	if (velo) return [NSString stringWithFormat:@"%@ vel", midiNoteToString(mIndexToNote[note])];
	
	return [NSString stringWithFormat:@"%@ sta", midiNoteToString(mIndexToNote[note])];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	NSPopUpButtonCell *pcell = [[mNoteTableView tableColumnWithIdentifier:@"note"] dataCell];
	[pcell removeAllItems];
	
	int i;
	for (i = 0; i < kNoteCount; i++)
		[pcell addItemWithTitle:midiNoteToString(i)];
		
	[mNoteDelete setEnabled:NO];
}

// load / save stuff
- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	NSMutableArray *ma = [[NSMutableArray alloc] init];
	
	int i;
	for (i = 0; i < mNoteActiveCount; i++)
	{
		int note = mIndexToNote[i];
		[ma addObject:[NSNumber numberWithInt:note]];
		[ma addObject:[NSNumber numberWithDouble:mNoteOnValue[note]]];
		[ma addObject:[NSNumber numberWithDouble:mNoteOffValue[note]]];
	}
	
	[md setObject:ma forKey:@"notes"];
	[ma release];
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSArray *a;

	a = [data objectForKey:@"notes"];
	if (a)
	{
		int c = [a count], i, n;
		for (i = 0; i < c - 2;)
		{
			n = [[a objectAtIndex:i++] intValue];
			if (n < 0) n = 0; else if (n >= kNoteCount) n = kNoteCount - 1;
			
			mNoteActive[n] = YES;
			mNoteOnValue[n] = [[a objectAtIndex:i++] doubleValue];
			mNoteOffValue[n] = [[a objectAtIndex:i++] doubleValue];
		}
	}
	
	[self update];

	return YES;
}

// do the midi stuff
- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange
{
	if (mChannel < 0)
		return;

	if (!mChannel || (mChannel - 1 == channel))
	{
		if (status == kMidiMessage_NoteOn && data2)
		{
			// apply note
			if (data1 < 0) data1 = 0; else if (data1 >= kNoteCount) data1 = kNoteCount - 1;
			
			if (mNoteActive[data1])
			{
				int ind = mNoteToIndex[data1];
				double velo = data2 / 127.;

				[self setValue:mNoteOnValue[data1] forOutput:ind * 2	 offsetToChange:offsetToChange];
				[self setValue:velo				   forOutput:ind * 2 + 1 offsetToChange:offsetToChange];
			}
		}
		else if (status == kMidiMessage_NoteOff || (status == kMidiMessage_NoteOn && !data2))
		{
			if (data1 < 0) data1 = 0; else if (data1 >= kNoteCount) data1 = kNoteCount - 1;
			
			if (mNoteActive[data1])
			{
				int ind = mNoteToIndex[data1];

				[self setValue:mNoteOffValue[data1] forOutput:ind * 2	  offsetToChange:offsetToChange];
				[self setValue:0				    forOutput:ind * 2 + 1 offsetToChange:offsetToChange];
			}
		}
	}
}

- (void) reset
{
	int i;
	for (i = 0; i < mNoteActiveCount; i++)
	{
		int note = mIndexToNote[i];
		[self setValue:mNoteOffValue[note] forOutput:i * 2	   offsetToChange:0];
		[self setValue:0				   forOutput:i * 2 + 1 offsetToChange:0];
	}

	[super reset];
}


// internal function
- (void) update
{
	[self willChangeAudio];

	int i, j;
	for (i = 0, j = 0; i < kNoteCount; i++)
		if (mNoteActive[i])
		{
			mIndexToNote[j] = i;
			mNoteToIndex[i] = j;
			j++;
		}
		
	mNoteActiveCount = j;
	mNumberOfOutputs = mNoteActiveCount * 2;

	// as we may have more output than before, we need to allocate them...
	[self prepareForSamplingRate:mSampleRate
			sampleCount:mSampleCount
			precision:mPrecision
			interpolation:mInterpolation];

	[self didChangeConnections];
	[self didChangeAudio];

	[self didChangeGlobalView];
}

// user event
- (IBAction) addNote:(id)sender
{
	int i;
	for (i = 0; i < kNoteCount; i++)
		if (!mNoteActive[i])
		{
			mNoteActive[i] = YES;
			break;
		}
		
	[self update];
	[mNoteTableView reloadData];
}

- (IBAction) removeNote:(id)sender
{
	int i = [mNoteTableView selectedRow];
	if (i < 0) return;
	
	mNoteActive[mIndexToNote[i]] = NO;
	
	[self update];
	[mNoteTableView reloadData];
	
	[mNoteDelete setEnabled:(mNoteActiveCount > 0)];
}

// tableview stuff
- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return mNoteActiveCount;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqual:@"note"])
	{
		return [NSNumber numberWithInt:mIndexToNote[rowIndex]];
	}
	else if ([identifier isEqual:@"on"])
	{
		return [NSNumber numberWithDouble:mNoteOnValue[mIndexToNote[rowIndex]]];
	}
	else // off
	{
		return [NSNumber numberWithDouble:mNoteOffValue[mIndexToNote[rowIndex]]];
	}
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	NSString *identifier = [aTableColumn identifier];
	if ([identifier isEqual:@"note"])
	{
		mNoteActive[mIndexToNote[rowIndex]] = NO;
		
		int ind = [anObject intValue];
		if (ind < 0) ind = 0; else if (ind >= kNoteCount) ind = kNoteCount - 1;
		mNoteActive[ind] = YES;
		
		[self update];
	}
	else if ([identifier isEqual:@"on"])
	{
		mNoteOnValue[mIndexToNote[rowIndex]] = [anObject doubleValue];
	}
	else // off
	{
		mNoteOffValue[mIndexToNote[rowIndex]] = [anObject doubleValue];
	}
	[mNoteTableView reloadData];
	return;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
	int i = [mNoteTableView selectedRow];
	[mNoteDelete setEnabled:(i >= 0)];
}

// disable any gui
- (void) drawContent
{
	if (mGuiMode != kCircuitDesign) return;
	[super drawContent];
}

- (BOOL) hitTestX:(int)x Y:(int)y
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super hitTestX:x Y:y];
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseDownX:x Y:y clickCount:clickCount];
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseDraggedX:x Y:y lastX:lx lastY:ly];
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseUpX:x Y:y];
}

- (BOOL) keyDown:(unichar)ukey
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super keyDown:ukey];
}

@end
