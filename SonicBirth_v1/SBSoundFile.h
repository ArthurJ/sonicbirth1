/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

@interface SBSoundFile : NSObject
{
	int mSampleRate;
	int mNumberOfChannels;
	int mNumberOfFrames;
	
	float *mBuffer;
}

+ (NSArray*) supportedExtensions;

// open and init for selected path
- (SBSoundFile*) initForPath:(NSString*)path;
- (SBSoundFile*) initForPath:(NSString*)path forceSampleRate:(int)sampleRate;

// simple info
- (int) sampleRate;
- (int) numberOfChannels;
- (int) numberOfFrames;

// the following returns YES if suceeded

// interleaved reading
- (BOOL) readFrames:(int)count offset:(int)offset inBuffer:(float*)buffer;

// non-interleaved reading for one channel
- (BOOL) readSamples:(int)count offset:(int)offset fromChannel:(int)idx inBuffer:(float*)buffer;

// non-interleaved reading for many channel
- (BOOL) readSamples:(int)count offset:(int)offset baseChannel:(int)idx countChannel:(int)chancount inBuffers:(float**)buffers;

@end
