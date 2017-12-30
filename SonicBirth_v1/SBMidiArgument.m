/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiArgument.h"
#import "SBControllerList.h"
#import "SBRootCircuitMidi.h"

static double gMidiNotes[128];
static BOOL gMiniNotesInited = NO;

static NSString *gMidiNotesNames[128];
static BOOL gMiniNotesNamesInited = NO;

double midiNoteToHertz(int num)
{
	if (!gMiniNotesInited)
	{
		int i;
		for (i = 0; i < 128; i++)
			gMidiNotes[i] = -1.;
		
		gMidiNotes[69] = 440.;
		
		for (i = 69 - 12; i >= 0; i -= 12)
			gMidiNotes[i] = gMidiNotes[i + 12] / 2.;
	
		for (i = 69 + 12; i < 128; i += 12)
			gMidiNotes[i] = gMidiNotes[i - 12] * 2.;
			
		double coef = pow(2.0, 1. / 12.);
		for (i = 1; i < 128; i++)
			if (gMidiNotes[i - 1] > 0 && gMidiNotes[i] < 0)
				gMidiNotes[i] = gMidiNotes[i - 1] * coef;
				
		for (i = 126; i >= 0; i--)
			if (gMidiNotes[i + 1] > 0 && gMidiNotes[i] < 0)
				gMidiNotes[i] = gMidiNotes[i + 1] / coef;
				
		gMiniNotesInited = YES;
	}

	if (num < 0) num = 0;
	else if (num > 127) num = 127;
	
	return gMidiNotes[num];
}

NSString *midiNoteToString(int num)
{
	if (!gMiniNotesNamesInited)
	{
		int i;
		for (i = 0; i < 128; i++)
		{
			int octave = i / 12;
			int note = i % 12;
			
			char *names[12] = {	"C", "C#", "D", "D#", "E", "F",
								"F#", "G", "G#", "A", "A#", "B" };
			
			gMidiNotesNames[i] = [[NSString alloc] initWithFormat:@"%s%i", names[note], octave];
		}
				
		gMiniNotesNamesInited = YES;
	}

	if (num < 0) num = 0;
	else if (num > 127) num = 127;
	
	return gMidiNotesNames[num];
}

@implementation SBMidiArgument

+ (SBElementCategory) category
{
	return kMidiArgument;
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		mChannel = 0;
		mRealtime = YES;
	}
	return self;
}

- (int) channel
{
	return mChannel;
}

- (void) setChannel:(int)channel
{
	mChannel = channel;
	if (mChannel < -1) mChannel = -1; // -1 is off, 0 is 'Any channel'
	else if (mChannel > 16) mChannel = 16;
	if (mChannelPopUp) [mChannelPopUp selectItemAtIndex:mChannel + 1];
}

- (IBAction) changedChannel:(id)sender
{
	[self setChannel:[mChannelPopUp indexOfSelectedItem] - 1];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mChannelPopUp selectItemAtIndex:mChannel + 1];
}

- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange
{
	
}

- (int) numberOfParameters
{
	return 0;
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:mChannel] forKey:@"midiChannel"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;
	
	n = [data objectForKey:@"midiChannel"];
	if (n) mChannel = [n intValue];
	
	return YES;
}

- (BOOL) useController
{
	return NO;
}

- (int) controller
{
	return kOffID;
}

- (void) setController:(int)controller
{
}

- (void) setRootCircuitMidi:(SBRootCircuitMidi*)rootCircuitMidi
{
	mRootCircuitMidi = rootCircuitMidi;
}

- (void) changedController
{
	if (mRootCircuitMidi) [mRootCircuitMidi updatedController:self];
}

- (id) savePreset
{
	return [NSNumber numberWithInt:mChannel];
}

- (void) loadPreset:(id)preset
{
	NSNumber *n = preset;
	[self setChannel:[n intValue]];	
}

@end
