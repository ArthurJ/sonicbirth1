/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBRootCircuitMidi.h"
#import "SBRootCircuit.h"
#import "SBMidiArgument.h"
#import "SBMidiSlider.h"
#import "SBControllerList.h"
#import "SBRootCircuitMidiCell.h"

static NSArray *gChannelsNames = nil;
static NSMutableArray *gTypesNames = nil;
static NSArray *gNotApplicableName = nil;

@implementation SBRootCircuitMidi

- (id) init
{
	self = [super init];
	if (self != nil) 
	{
		if (!gNotApplicableName)
		{
			gNotApplicableName = [[NSArray alloc] initWithObjects:@"N/A", nil];
		}
	
		if (!gChannelsNames)
		{
			gChannelsNames = [[NSArray alloc] initWithObjects:
										@"Off", @"Any", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", 
										@"11", @"12", @"13", @"14", @"15", @"16", nil];
		}
		
		if (!gTypesNames)
		{
			gTypesNames = [[NSMutableArray alloc] init];
			int c = gControllerTypesCount, j;
			for (j = 0; j < c; j++)
				[gTypesNames addObject:gControllerTypes[j].name];
		}
		
		mItemNames = [[NSMutableArray alloc] init];
		if (!mItemNames)
		{
			[self release];
			return nil;
		}
		
		mCurrentMidiArgumentIndex = 0;
		mCurrentMidiArgument = nil;
		mCurrentChannel = 0;
		mCurrentController = kOffID;
	}
	return self;
}

- (void) dealloc
{
	if (mItemNames) [mItemNames release];
	[super dealloc];
}

+ (SBElementCategory) category
{
	return kInternal;
}

+ (NSString*) name
{
	return @"Midi settings";
}

- (NSString*) name
{
	return @"Midi settings";
}

- (NSString*) informations
{
	return	@"MIDI settings central control.";
}

- (int) numberOfParameters
{
	return 3;
}

- (BOOL) realtimeForParameter:(int)i
{
	return YES;
}

- (NSString*) nameForParameter:(int)i
{
	if (i == 0) return @"Midi item";
	if (i == 1) return @"Midi channel";
	return @"Midi controller";
}

- (double) minValueForParameter:(int)i
{
	return 0;
}
- (double) maxValueForParameter:(int)i
{
	if (!mParent)
		return 0;
		
	if (i == 0)
	{
		int c = [mItemNames count];
		if (c > 0) return c - 1;
		else return 0;
	}	
	
	if (i == 1)
		return [gChannelsNames count] - 1;
		
//	NSLog(@"(max val) index: %i, name: %@", 
//					mCurrentMidiArgumentIndex,
//					(mCurrentMidiArgument) ? [mCurrentMidiArgument name] : @"nil");
		
//	if (mCurrentMidiArgument && [mCurrentMidiArgument isKindOfClass:[SBMidiSlider class]])
		return gControllerTypesCount - 1;
//	else
//		return 0;
}

- (SBParameterType) typeForParameter:(int)i
{
	return kParameterUnit_Indexed;
}

- (NSArray*) indexedNamesForParameter:(int)i
{
	if (!mParent)
		return gNotApplicableName;
		
	if (i == 0)
	{
		int c = [mItemNames count];
		if (!c) return gNotApplicableName;
		return mItemNames;
	}
	
	if (i == 1)
		return gChannelsNames;
		
//	NSLog(@"(index names) index: %i, name: %@", 
//					mCurrentMidiArgumentIndex,
//					(mCurrentMidiArgument) ? [mCurrentMidiArgument name] : @"nil");
		
//	if (mCurrentMidiArgument && [mCurrentMidiArgument isKindOfClass:[SBMidiSlider class]])
		return gTypesNames;
//	else
//		return gNotApplicableName;
}

- (double) currentValueForParameter:(int)i
{
	if (i == 0)
		return mCurrentMidiArgumentIndex;
		
	if (i == 1)
		return mCurrentChannel + 1;
		
//	if (mCurrentMidiArgument && [mCurrentMidiArgument useController])
//	{
		if (!mCurrentMidiArgument || ![mCurrentMidiArgument useController])
			mCurrentController = kOffID;

		int c = gControllerTypesCount, j;
		for (j = 0; j < c; j++)
		{
			if (gControllerTypes[j].num == mCurrentController)
				return j;
		}
		return 0;
//	}
//	else
//		return 0;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	// NSLog(@"preset change for param: %i value: %i", i, (int) preset);

	if (i == 0)
	{
		int idx = preset;
		if (idx < 0) idx = 0;
		else if (idx >= [mItemNames count]) idx = [mItemNames count] - 1;
		
		mCurrentMidiArgumentIndex = preset;
		
		mCurrentMidiArgument = [mParent midiArgumentAtIndex:mCurrentMidiArgumentIndex];
		mCurrentChannel = [mCurrentMidiArgument channel];
		mCurrentController = [mCurrentMidiArgument controller];
		
		[self didChangeParameterValueAtIndex:1];
		[self didChangeParameterValueAtIndex:2];
	}
	else if (i == 1)
	{
		int channel = preset - 1;
		if (channel < -1) channel = -1;
		else if (channel > 16) channel = 16;
		mCurrentChannel = channel;
		if (mCurrentMidiArgument) [mCurrentMidiArgument setChannel:channel];
	}
	else
	{
		if (mCurrentMidiArgument && [mCurrentMidiArgument useController])
		{
			int idx = preset;
			if (idx < 0) idx = 0;
			else if (idx >= gControllerTypesCount) idx = gControllerTypesCount - 1;
			mCurrentController = gControllerTypes[idx].num;
			[mCurrentMidiArgument setController:mCurrentController];
		}
		else
		{
			mCurrentController = kOffID;
//			[self didChangeParameterValueAtIndex:2];
		}
	}
}

- (void) setParent:(SBRootCircuit*)parent
{
	mParent = parent;
	mCurrentMidiArgumentIndex = 0;
	mCurrentMidiArgument = [mParent midiArgumentAtIndex:mCurrentMidiArgumentIndex];
	if (mCurrentMidiArgument)
	{
		mCurrentChannel = [mCurrentMidiArgument channel];
		mCurrentController = [mCurrentMidiArgument controller];
	}
}

- (void) updateItems
{
	[mItemNames removeAllObjects];

	int c = [mParent numberOfMidiArguments], i;
	for (i = 0; i < c; i++)
	{
		SBMidiArgument *m = [mParent midiArgumentAtIndex:i];
		[m setRootCircuitMidi:self];
		[mItemNames addObject:[m name]];
	}
	
	mCurrentMidiArgumentIndex = 0;
	mCurrentMidiArgument = [mParent midiArgumentAtIndex:mCurrentMidiArgumentIndex];
	if (mCurrentMidiArgument)
	{
		mCurrentChannel = [mCurrentMidiArgument channel];
		mCurrentController = [mCurrentMidiArgument controller];
	}
}

- (void) updatedController:(SBMidiArgument*)arg
{
	if (arg == mCurrentMidiArgument)
	{
		mCurrentController = [mCurrentMidiArgument controller];
		[self didChangeParameterValueAtIndex:2];
	}
}

- (SBCell*) createCell
{
	SBRootCircuitMidiCell *cell = [[SBRootCircuitMidiCell alloc] init];
	if (cell) [cell setArgument:self];
	return cell;
}
/*
- (NSMutableDictionary*) saveData
{
	return nil;
}

- (BOOL) loadData:(NSDictionary*)data
{
	return YES;
}
*/
@end
