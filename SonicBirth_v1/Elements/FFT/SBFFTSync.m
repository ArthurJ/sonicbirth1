/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#import "SBFFTSync.h"
#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFFTSync *obj = inObj;
	
	int dataPos = obj->mDataPos;
	int fftBlockSize = obj->mFFTBlockSize;
	int fftCountHalf = POW2Table[fftBlockSize - 1];
	
	obj->mFFTSync.offset = dataPos;
	dataPos += count;
	dataPos %= fftCountHalf;
	
	obj->mDataPos = dataPos;
}

@implementation SBFFTSync

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"FFT Sync";
}

- (NSString*) name
{
	return @"FFTs";
}

- (NSString*) informations
{
	return	@"States the fft size and block positions.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		mFFTBlockSize = 6; // 2^6 == 64 -- 2^8 == 256
		mFFTSync.size = mFFTBlockSize;
		mFFTSync.offset = 0;
		mFFTSyncBuffer.fftSyncData = &mFFTSync;
		
		mDataPos = 0;
		
		[mOutputNames addObject:@"sync"];
	}
	return self;
}

- (void) dealloc
{
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (SBConnectionType) typeOfOutputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	return kNormal;
}

- (SBBuffer) outputAtIndex:(int)idx
{
	if (idx == 0) return mFFTSyncBuffer;
	return [super outputAtIndex:idx];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBFFTSync" owner:self];
		return mSettingsView;
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mFFTBlockSizePopUp removeAllItems];
	[mFFTBlockSizePopUp addItemWithTitle:@"64"];
	[mFFTBlockSizePopUp addItemWithTitle:@"128"];
	[mFFTBlockSizePopUp addItemWithTitle:@"256"];
	[mFFTBlockSizePopUp addItemWithTitle:@"512"];
	[mFFTBlockSizePopUp addItemWithTitle:@"1024"];
	[mFFTBlockSizePopUp addItemWithTitle:@"2048"];
	[mFFTBlockSizePopUp addItemWithTitle:@"4096"];
	[mFFTBlockSizePopUp addItemWithTitle:@"8192"];
	[mFFTBlockSizePopUp selectItemAtIndex:mFFTBlockSize - 6]; // 0 is 2^6 == 64
}

- (void) FFTBlockSizeChanged:(id)sender
{
	[self willChangeAudio];
	mFFTBlockSize = [mFFTBlockSizePopUp indexOfSelectedItem] + 6; // 0 is 2^6 == 64
	mFFTSync.size = mFFTBlockSize;
	mFFTSync.offset = 0;
	mDataPos = 0;
	[self didChangeAudio];
}

- (void) reset
{
	[super reset];
	
	mFFTSync.size = mFFTBlockSize;
	mFFTSync.offset = 0;
	mDataPos = 0;
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:mFFTBlockSize] forKey:@"fftBlockSize"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	NSNumber *n;
	
	n = [data objectForKey:@"fftBlockSize"];
	if (n) mFFTBlockSize = [n intValue];
	
	if (mFFTBlockSize < 6) mFFTBlockSize = 6;
	else if (mFFTBlockSize > 13) mFFTBlockSize = 13;
	
	return YES;
}

@end
