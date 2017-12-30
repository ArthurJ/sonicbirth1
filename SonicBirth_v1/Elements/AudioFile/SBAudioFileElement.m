/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBAudioFileElement.h"
#import "SBSoundFile.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
}

@implementation SBAudioFileElement

+ (NSString*) name
{
	return @"Audio file";
}

- (NSString*) name
{
	return @"audio file";
}

+ (SBElementCategory) category
{
	return kAudioFile;
}

- (NSString*) informations
{
	return	@"Loads an audio file and outputs each channel.";
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
	}
	return self;
}

- (void) dealloc
{
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

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mFilePath setStringValue:(mNumberOfSamples) ? @"none" : @"internal"];
	[mFileInfo setStringValue:[NSString stringWithFormat:@"%i frames", mNumberOfSamples ]];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBAudioFileElement" owner:self];
		return mSettingsView;
	}
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	return kAudioBuffer;
}

- (int) numberOfOutputs
{
	return mChannelCount;
}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return [NSString stringWithFormat:@"chan %i", idx];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:mChannelCount] forKey:@"channels"];
	[md setObject:[NSNumber numberWithInt:mNumberOfSamples] forKey:@"samples"];
	
	NSMutableArray *ma  = [[NSMutableArray alloc] init];
	int i;
	for (i = 0; i < mChannelCount; i++)
	{
		NSData *data = [NSData dataWithBytes:mBuffers[i] length:mNumberOfSamples * sizeof(float)];
		[ma addObject:data];
	}
	[md setObject:ma forKey:@"buffers"];
	[ma release];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	int i;
	for (i = 0; i < kMaxChannels; i++)
	{
		if (mBuffers[i])
		{
			free(mBuffers[i]);
			mBuffers[i] = nil;
		}
	}

	NSNumber *n1, *n2;
	NSArray *a;
	
	n1 = [data objectForKey:@"channels"];
	n2 = [data objectForKey:@"samples"];
	a = [data objectForKey:@"buffers"];
	if (!n1 ||!n2 || !a) return NO;
	
	mChannelCount = [n1 intValue];
	mNumberOfSamples = [n2 intValue];
	
	int c = [a count];
	if (c != mChannelCount)
	{
		mChannelCount = 0;
		return NO;
	}

	for (i = 0; i < mChannelCount; i++)
	{
		NSData *data = [a objectAtIndex:i];
		int l = [data length];
		if (l != (mNumberOfSamples * sizeof(float)))
		{
			for (i = 0; i < kMaxChannels; i++)
			{
				if (mBuffers[i])
				{
					free(mBuffers[i]);
					mBuffers[i] = nil;
				}
			}
			mChannelCount = 0;
			return NO;
		}
		
		mBuffers[i] = malloc(mNumberOfSamples * sizeof(float));
		if (!mBuffers[i]) mChannelCount = i;
		
		memcpy(mBuffers[i], [data bytes], mNumberOfSamples * sizeof(float));
	}
	
	for (i = 0; i < mChannelCount; i++)
	{
		mAB[i].time = SBGetTimeStamp();
		mAB[i].count = mNumberOfSamples;
		mAB[i].data = mBuffers[i];
	}

	return YES;
}

- (IBAction) loadAudioFile:(id)sender
{
	NSOpenPanel *panel = [NSOpenPanel openPanel];
	[panel setCanChooseDirectories:NO];
	[panel setAllowsMultipleSelection:NO];
	[panel setCanChooseFiles:YES];
	int result = [panel runModalForTypes:[SBSoundFile supportedExtensions]];
																	
	if (result != NSOKButton) return;

	NSString *path = [panel filename];
	
	SBSoundFile *file = [[SBSoundFile alloc] initForPath:path];
	if (!file)
	{
		NSRunAlertPanel(@"SonicBirth", @"Could not open file.", @"", @"", @"");
		return;
	}
	
	[self willChangeAudio];
	
		int i;
		for (i = 0; i < kMaxChannels; i++)
		{
			mAB[i].time = SBGetTimeStamp();
			mAB[i].count = 0;
			mAB[i].data = nil;
		}
	
	[self didChangeAudio];
	
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
	
	/*
	for (i = 0; i < mChannelCount; i++)
	{
		BOOL ok = [file readSamples:mNumberOfSamples offset:0 fromChannel:i inBuffer:mBuffers[i]];
		if (!ok) mChannelCount = i;
	}
	*/
	
	BOOL isOK = [file readSamples:mNumberOfSamples offset:0 baseChannel:0 countChannel:mChannelCount inBuffers:mBuffers];
	if (!isOK) mChannelCount = i;

	[self willChangeAudio];

		for (i = 0; i < mChannelCount; i++)
		{
			mAB[i].time = SBGetTimeStamp();
			mAB[i].count = mNumberOfSamples;
			mAB[i].data = mBuffers[i];
		}
	
	[self didChangeConnections];
	[self didChangeAudio];
	[self didChangeGlobalView];
	
	[mFilePath setStringValue:path];
	[mFileInfo setStringValue:[NSString stringWithFormat:@"File: %i channels %i hz %.1f secs %i frames", 
						[file numberOfChannels], [file sampleRate],
						(float)[file numberOfFrames] / (float)[file sampleRate],
						[file numberOfFrames] ]];
	
	[file release];
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

