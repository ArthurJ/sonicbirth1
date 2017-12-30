/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBSimpleArgument.h"

@class SBRootCircuitMidi;

// found in AUMidiBase.cpp
enum
{
	kMidiMessage_NoteOff 			= 0x80,
	kMidiMessage_NoteOn 			= 0x90,
	kMidiMessage_PolyPressure 		= 0xA0,
	kMidiMessage_ControlChange 		= 0xB0,
	kMidiMessage_ProgramChange 		= 0xC0,
	kMidiMessage_ChannelPressure 	= 0xD0,
	kMidiMessage_PitchWheel 		= 0xE0,

	kMidiController_AllSoundOff			= 120,
	kMidiController_ResetAllControllers	= 121,
	kMidiController_AllNotesOff			= 123,
	
};

double midiNoteToHertz(int num);
NSString *midiNoteToString(int num);

@interface SBMidiArgument : SBSimpleArgument
{
	int mChannel;
	
	IBOutlet NSPopUpButton	*mChannelPopUp;
	
	SBRootCircuitMidi *mRootCircuitMidi;
}

- (int) channel;
- (void) setChannel:(int)channel;

- (BOOL) useController;
- (int) controller;
- (void) setController:(int)controller;

- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange;

- (IBAction) changedChannel:(id)sender;

- (void) changedController;
- (void) setRootCircuitMidi:(SBRootCircuitMidi*)rootCircuitMidi;

@end
