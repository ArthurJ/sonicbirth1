/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAudioFileArgument.h"
#import "SBSoundFile.h"
#import "SBIndexedCell.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
}

@implementation SBAudioFileArgument

+ (NSString*) name
{
	return @"Audio file argument";
}

- (NSString*) name
{
	return mName;
}

+ (SBElementCategory) category
{
	return kArgument;
}

- (NSString*) informations
{
	return	@"User selectable audio file with preset channel count.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		int i;	
		for (i = 0; i < kMaxChannels; i++)
			mAudioBuffers[i].audioData = mAB + i;
		
		mName = [[NSMutableString alloc] initWithString:@"afile arg"];
		if (!mName)
		{
			[self release];
			return nil;
		}
		
		mPresetChannelCount = 1;
	}
	return self;
}

- (void) dealloc
{
	if (mName) [mName release];
	if (mFileName) [mFileName release];
	if (mSettingsView) [mSettingsView release];
	int i;
	for (i = 0; i < kMaxChannels; i++)
	{
		if (mBuffers[i])
		{
			free(mBuffers[i]);
			mBuffers[i] = nil;
		}
	}
	[super dealloc];
}

- (id) savePreset
{
	return (mFileName) ? [NSString stringWithString:mFileName] : [NSString string];
}

- (void) loadPreset:(id)preset
{
	[self loadAudioFile:preset];
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mNameTF setStringValue:mName];
	[mPresetChannelCountTF setIntValue:mPresetChannelCount];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBAudioFileArgument" owner:self];
		return mSettingsView;
	}
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mPresetChannelCountTF)
	{
		[self willChangeAudio];
		
		mPresetChannelCount = [mPresetChannelCountTF intValue];
		if (mPresetChannelCount < 1) mPresetChannelCount = 1;
		else if (mPresetChannelCount > 100) mPresetChannelCount = 100;
		[mPresetChannelCountTF setIntValue:mPresetChannelCount];
	
		[self didChangeConnections];
		[self didChangeAudio];
	}
	else if (tf == mNameTF)
	{
		[mName setString:[mNameTF stringValue]];
	}
	
	[self didChangeGlobalView];
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return kAudioBuffer;
}

- (int) numberOfOutputs
{
	return mPresetChannelCount;
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return [NSString stringWithFormat:@"chan %i", idx];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [super saveData];
	if (!md) return nil;

	[md setObject:[NSNumber numberWithInt:mPresetChannelCount] forKey:@"channels"];
	[md setObject:mName forKey:@"name"];
	if (mFileName) [md setObject:mFileName forKey:@"filename"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	[super loadData:data];

	NSNumber *n = [data objectForKey:@"channels"];
	if (n) mPresetChannelCount = [n intValue];
	
	if (mPresetChannelCount < 1) mPresetChannelCount = 1;
	else if (mPresetChannelCount > 100) mPresetChannelCount = 100;
	
	NSString *s = [data objectForKey:@"name"];
	if (s) [mName setString:s];
	
	s = [data objectForKey:@"filename"];
	if (s) [self loadAudioFile:s];

	return YES;
}

- (NSString*) findAudioFile
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	if (!panel) return nil;
	
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	int result = [panel runModalForTypes:[SBSoundFile supportedExtensions]];
																	
	if (result != NSOKButton) return nil;

	return [panel filename];
}

- (void) loadAudioFile:(NSString*)path
{
	if (mFileName) [mFileName release];
	mFileName = nil;

	[self willChangeAudio];
	
		int i;
		for (i = 0; i < kMaxChannels; i++)
		{
			mAB[i].time = SBGetTimeStamp();
			mAB[i].count = 0;
			mAB[i].data = nil;
		}
	
	[self didChangeAudio];
	
	if (!path || [path length] == 0) return;
	
	SBSoundFile *file = [[SBSoundFile alloc] initForPath:path];
	if (!file)
	{
		NSRunAlertPanel(@"SonicBirth", @"Could not open file.", @"", @"", @"");
		return;
	}
	
	for (i = 0; i < kMaxChannels; i++)
	{
		if (mBuffers[i])
		{
			free(mBuffers[i]);
			mBuffers[i] = nil;
		}
	}
	
	mNumberOfSamples = [file numberOfFrames];
	mChannelCount = [file numberOfChannels];
	
	if (mChannelCount > kMaxChannels)
		mChannelCount = kMaxChannels;
	
	for (i = 0; i < mChannelCount; i++)
	{
		mBuffers[i] = malloc(mNumberOfSamples * sizeof(float));
		if (!mBuffers[i]) mChannelCount = i;
	}
	
	BOOL isOK = [file readSamples:mNumberOfSamples offset:0 baseChannel:0 countChannel:mChannelCount inBuffers:mBuffers];
	if (!isOK) mChannelCount = i;

	[self willChangeAudio];

		if (mChannelCount == 1)
			for (i = 0; i < mPresetChannelCount; i++)
			{
				mAB[i].time = SBGetTimeStamp();
				mAB[i].count = mNumberOfSamples;
				mAB[i].data = mBuffers[0];
			}
		else
			for (i = 0; i < mChannelCount; i++)
			{
				mAB[i].time = SBGetTimeStamp();
				mAB[i].count = mNumberOfSamples;
				mAB[i].data = mBuffers[i];
			}
	
	[self didChangeAudio];
	[self didChangeView];
	
	[file release];
	
	mFileName = [path copy];
}

- (SBCell*) createCell
{
	SBIndexedCell *cell = [[SBIndexedCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

- (NSString*) nameForParameter:(int)i
{
	return [self name];
}


- (NSArray*) indexedNamesForParameter:(int)i
{
	return [NSArray arrayWithObjects:@"Load file...", ((mFileName) ? [mFileName lastPathComponent] : @"No file loaded"), nil];
}

- (double) minValueForParameter:(int)i
{
	return 0;
}

- (double) maxValueForParameter:(int)i
{
	return 1;
}

- (SBParameterType) typeForParameter:(int)i
{
	return kParameterUnit_Indexed;
}

- (double) currentValueForParameter:(int)i
{
	return 1;
}

- (int) numberOfParameters
{
	return 0; // do not actually export the parameter
}

- (void) setName:(NSString*)name
{
	[mName setString:name];
	if (mNameTF) [mNameTF setStringValue:name];
	[self didChangeGlobalView];
	[self didChangeParameterInfo];
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	int idx = preset;
	if (idx == 0) 
		[self loadAudioFile:[self findAudioFile]];
	[self didChangeParameterValueAtIndex:0];
}

// we don't need any of that
- (void) prepareForSamplingRate:(int)samplingRate
			sampleCount:(int)sampleCount
			precision:(SBPrecision)precision
			interpolation:(SBInterpolation)interpolation
{}

- (void) changePrecision:(SBPrecision)precision
{}

- (void) changeInterpolation:(SBInterpolation)interpolation
{}

- (void) reset
{}

@end

