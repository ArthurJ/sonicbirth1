/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBMidiMonoNote.h"
#import "SBBooleanCell.h"

@implementation SBMidiMonoNote

+ (NSString*) name
{
	return @"Midi mono note";
}

- (NSString*) informations
{
	return	@"Outputs the note and velocity (in the range 0 - 1) of the current presser note. "
			@"You can select to hold the last note pressed.";
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBMidiMonoNote" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mDefaultNoteTF setDoubleValue:mDefaultNote];
	[mDefaultVelocityTF setDoubleValue:mDefaultVelocity];
	[mHoldNoteBt setState:(mHoldNote) ? NSOnState : NSOffState];
}

- (void) holdNote:(id)sender
{
	mHoldNote = ([mHoldNoteBt state] == NSOnState);
}

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		mDefaultNote = 440;
		mDefaultVelocity = 0;
		mNumberOfOutputs = 3;
		mStackCount = 0;
		mPitchBend = NO;
		mPitchCoeff = 1.;
		[self setValue:mDefaultNote forOutput:0 offsetToChange:0];
		[self setValue:mDefaultVelocity forOutput:1 offsetToChange:0];
		[self setValue:-1 forOutput:2 offsetToChange:0];
		[mName setString:@"midi mono note"];
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
	if (idx == 0) return @"note";
	if (idx == 1) return @"velo";
	return @"numb";
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	[super controlTextDidEndEditing:aNotification];

	id tf = [aNotification object];
	if (tf == mDefaultNoteTF)
	{
		mDefaultNote = [mDefaultNoteTF doubleValue];
		[mDefaultNoteTF setDoubleValue:mDefaultNote];
	}
	else if (tf == mDefaultVelocityTF)
	{
		mDefaultVelocity = [mDefaultVelocityTF doubleValue];
		[mDefaultVelocityTF setDoubleValue:mDefaultVelocity];
	}
	if (mStackCount == 0)
	{
		mCurNote = mDefaultNote;
		[self setValue:(mPitchBend) ? (mPitchCoeff*mDefaultNote) : mDefaultNote forOutput:0 offsetToChange:0];
		[self setValue:mDefaultVelocity forOutput:1 offsetToChange:0];
		[self setValue:-1 forOutput:2 offsetToChange:0];
	}
}

- (void) reset
{
	[self setValue:mDefaultNote forOutput:0 offsetToChange:0];
	[self setValue:mDefaultVelocity forOutput:1 offsetToChange:0];
	[self setValue:-1 forOutput:2 offsetToChange:0];
	
	mStackCount = 0;
	mPitchBend = NO;
	mPitchCoeff = 1.;
	mCurNote = mDefaultNote;
	
	[super reset];
}

- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offset
{
	if (mChannel < 0)
		return;

	if (!mChannel || (mChannel - 1 == channel))
	{
		if (status == kMidiMessage_NoteOn && data2)
		{
			// make sure it isn't already in the stack
			int i;
			for (i = 0; i < mStackCount; i++)
			{
				if (mNoteStack[i] == data1)
				{
					// remove the note
					mStackCount--;
					if (i != mStackCount) // if not last
					{
						memmove(mNoteStack + i, mNoteStack + i + 1, mStackCount - i);
						memmove(mVelocityStack + i, mVelocityStack + i + 1, mStackCount - i);
					}
					i--;
				}
			}
		
			// put it on top of stack
			mNoteStack[mStackCount] = data1;
			mVelocityStack[mStackCount] = data2;
			mStackCount++;
			assert(mStackCount < kMaxNotes);

			// apply note
			double note = midiNoteToHertz(data1);
			double velo = data2 / 127.;
			
			mCurNote = note;
			[self setValue:(mPitchBend) ? (mPitchCoeff*note) : note forOutput:0 offsetToChange:offset];
			[self setValue:velo forOutput:1 offsetToChange:offset];
			[self setValue:data1 forOutput:2 offsetToChange:0];
		}
		else if (status == kMidiMessage_NoteOff || (status == kMidiMessage_NoteOn && !data2))
		{
			// find which note to remove
			int i;
			for (i = 0; i < mStackCount; i++)
			{
				if (mNoteStack[i] == data1)
				{
					// remove the note
					mStackCount--;
					if (i != mStackCount) // if not last
					{
						memmove(mNoteStack + i, mNoteStack + i + 1, (mStackCount - i) * sizeof(int));
						memmove(mVelocityStack + i, mVelocityStack + i + 1, (mStackCount - i) * sizeof(int));
					}
					i--;
				}
			}
			
			// apply note from top of stack
			if (mStackCount > 0)
			{
				double note = midiNoteToHertz(mNoteStack[mStackCount - 1]);
				double velo = mVelocityStack[mStackCount - 1] / 127.;
			
				mCurNote = note;
				[self setValue:(mPitchBend) ? (mPitchCoeff*note) : note forOutput:0 offsetToChange:offset];
				[self setValue:velo forOutput:1 offsetToChange:offset];
				[self setValue:mNoteStack[mStackCount - 1] forOutput:2 offsetToChange:0];
			}
			else if (!mHoldNote)
			{
				mCurNote = mDefaultNote;
				[self setValue:(mPitchBend) ? (mPitchCoeff*mDefaultNote) : mDefaultNote forOutput:0 offsetToChange:offset];
				[self setValue:mDefaultVelocity forOutput:1 offsetToChange:offset];
				[self setValue:-1 forOutput:2 offsetToChange:0];
			}
		}
		else if (status == kMidiMessage_PitchWheel)
		{
			// NSLog(@"kMidiMessage_PitchWheel data1: %i data2: %i", data1, data2);
			// at 0: data2 = 64
			// at high: data2 = 127
			// at low: data2 = 0
			
			if (data1 == 0 && data2 == 64)
			{
				if (mPitchBend)
				{
					mPitchBend = NO;
					[self setValue:mCurNote forOutput:0 offsetToChange:offset];
				}
			}
			else
			{
				mPitchBend = YES;
				double val = ((data2 << 7) | data1) / 16383.; // middle is 8192./16383. (0.500030519)
				double left = 0.9438743127, right = 1.059463094, range = right - left;
				double coeff = left + val*range;
				mPitchCoeff = coeff;
				[self setValue:mCurNote*coeff forOutput:0 offsetToChange:offset];
			}
			
		}
	}
}


- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithDouble:mDefaultNote] forKey:@"default note"];
	[md setObject:[NSNumber numberWithDouble:mDefaultVelocity] forKey:@"default velocity"];
	[md setObject:[NSNumber numberWithInt:(mHoldNote) ? 2 : 1] forKey:@"hold note"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n;

	n = [data objectForKey:@"default note"];
	if (n) mDefaultNote = [n doubleValue];
	
	n = [data objectForKey:@"default velocity"];
	if (n) mDefaultVelocity = [n doubleValue];
	
	n = [data objectForKey:@"hold note"];
	if (n) mHoldNote = ([n intValue] == 2);
	
	[self setValue:mDefaultNote forOutput:0 offsetToChange:0];
	[self setValue:mDefaultVelocity forOutput:1 offsetToChange:0];

	return YES;
}

- (int) numberOfParameters
{
	return 1;
}

- (BOOL) realtime
{
	return YES;
}

- (double) minValue
{
	return 0.;
}

- (double) maxValue
{
	return 1.;
}

- (SBParameterType) type
{
	return kParameterUnit_Boolean;
}

- (double) currentValue
{
	return (mHoldNote) ? 1 : 0;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset
{
	mHoldNote = preset;
	if (mHoldNoteBt) [mHoldNoteBt setState:(mHoldNote) ? NSOnState : NSOffState];
	[self didChangeView];
}

- (SBCell*) createCell
{
	SBBooleanCell *cell = [[SBBooleanCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

@end
