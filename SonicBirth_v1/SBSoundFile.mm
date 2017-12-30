/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBSoundFile.h"
//#import "CAAudioFile.h"
#warning "CAAudioFile missing"

@implementation SBSoundFile

+ (NSArray*) supportedExtensions
{
	NSArray *a;
	UInt32 size = sizeof(NSArray*);
	
	OSStatus err = AudioFileGetGlobalInfo(	kAudioFileGlobalInfo_AllExtensions,
											0, nil,
											&size, &a);
	if ((err != noErr) || (size != sizeof(NSArray*)) || (a == nil))
	{
		return [NSArray arrayWithObjects:	@"aif", @"AIF",
											@"aiff", @"AIFF",
											@"wav", @"WAV",
											nil];
	}
										
	return [a autorelease];
}

// open and init for selected path
- (SBSoundFile*) initForPath:(NSString*)path
{
	return [self initForPath:path forceSampleRate:0];
}

- (SBSoundFile*) initForPath:(NSString*)path forceSampleRate:(int)sampleRate
{
	if ((self = [super init]))
	{	
		NSURL *url = [NSURL fileURLWithPath:path];
		
		ExtAudioFileRef file;
		OSStatus err = ExtAudioFileOpenURL((CFURLRef)url, &file);
		if (err || !file)
		{
			[self release];
			return nil;
		}
		
		SInt64 numberOfFrames; UInt32 numberOfFramesSize = sizeof(numberOfFrames);
		err = ExtAudioFileGetProperty(file, kExtAudioFileProperty_FileLengthFrames,
										&numberOfFramesSize, &numberOfFrames);
		if (err)
		{
			ExtAudioFileDispose(file);
			[self release];
			return nil;
		}
		
		AudioStreamBasicDescription desc; UInt32 descSize = sizeof(desc);
		err = ExtAudioFileGetProperty(file, kExtAudioFileProperty_FileDataFormat,
										&descSize, &desc);
		if (err)
		{
			ExtAudioFileDispose(file);
			[self release];
			return nil;
		}
		
		desc.mFormatID = kAudioFormatLinearPCM;
		desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked;
		desc.mBitsPerChannel = sizeof(float) * 8;
		desc.mFramesPerPacket = 1;
		desc.mBytesPerPacket = desc.mBytesPerFrame = sizeof(float) * desc.mChannelsPerFrame;
		
		int fileSampleRate = (int)desc.mSampleRate;
		if (sampleRate > 0) desc.mSampleRate = sampleRate;
		
		err = ExtAudioFileSetProperty(file, kExtAudioFileProperty_ClientDataFormat,
										sizeof(desc), &desc);
		if (err)
		{
			ExtAudioFileDispose(file);
			[self release];
			return nil;
		}
		
		mSampleRate = (int)desc.mSampleRate;
		mNumberOfChannels = desc.mChannelsPerFrame;
		mNumberOfFrames = numberOfFrames;
		
		if (mSampleRate != fileSampleRate)
			mNumberOfFrames = (long long)mNumberOfFrames * mSampleRate / fileSampleRate;
			
		// converter may have some trailing data
		mNumberOfFrames += mSampleRate;
		
		int bufferSize = mNumberOfFrames * mNumberOfChannels * sizeof(float);
		mBuffer = (float*) malloc(bufferSize);
		if (!mBuffer)
		{
			ExtAudioFileDispose(file);
			[self release];
			return nil;
		}
		
		UInt32 num = mNumberOfFrames;
		AudioBufferList list;

		list.mNumberBuffers = 1;
		list.mBuffers[0].mData = mBuffer;
		list.mBuffers[0].mNumberChannels = mNumberOfChannels;
		list.mBuffers[0].mDataByteSize = bufferSize;
		
		err = ExtAudioFileRead(file, &num, &list);
		if (err)
		{
			ExtAudioFileDispose(file);
			[self release];
			return nil;
		}
		
		mNumberOfFrames = num;
		ExtAudioFileDispose(file);
	}
	return self;
}

- (void) dealloc
{
	if (mBuffer) free(mBuffer);
	[super dealloc];
}

// simple info
- (int) sampleRate
{
	return mSampleRate;
}

- (int) numberOfChannels
{
	return mNumberOfChannels;
}

- (int) numberOfFrames
{
	return mNumberOfFrames;
}

// interleaved reading
- (BOOL) readFrames:(int)count offset:(int)offset inBuffer:(float*)buffer
{
	if (!buffer) return NO;
	if (count <= 0) return NO;
	if (offset < 0) return NO;
	if (offset + count > mNumberOfFrames) return NO;
	
	memcpy(buffer, mBuffer + offset * mNumberOfChannels, count * mNumberOfChannels * sizeof(float));
	return YES;
}

// non-interleaved reading for one channel
- (BOOL) readSamples:(int)count offset:(int)offset fromChannel:(int)idx inBuffer:(float*)buffer
{
	return [self readSamples:count offset:offset baseChannel:idx countChannel:1 inBuffers:&buffer];
}

// non-interleaved reading for many channel
- (BOOL) readSamples:(int)count offset:(int)offset baseChannel:(int)idx countChannel:(int)chancount inBuffers:(float**)buffers
{
	int channels = mNumberOfChannels;
	if (idx < 0 || idx >= channels) return NO;
	if (chancount <= 0 || (idx+chancount) > channels) return NO;
	if (!buffers) return NO;
	if (count <= 0) return NO;
	if (offset < 0) return NO;
	if (offset + count > mNumberOfFrames) return NO;
	
	int i;
	for (i = 0; i < chancount; i++) if (!buffers[i]) return NO;

	float *b = mBuffer + idx;
	
	int j, off = channels - chancount;
	for (i = 0; i < count; i++)
	{
		for(j = 0; j < chancount; j++)
			buffers[j][i] = *b++;
		b += off;
	}

	return YES;
}

@end
