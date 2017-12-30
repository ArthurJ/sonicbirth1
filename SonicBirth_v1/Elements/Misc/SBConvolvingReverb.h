/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBElement.h"
#include <Accelerate/Accelerate.h>
#include <pthread.h>

#define kBlockSize (8192)
#define kBlockSizeHalf (4096)
#define kBlockSizeQuarter (2048)
#define kBlockSizeBase2 (13)

#define kBlockMaxCount (600)

#define kMaxWorkers (2)

typedef struct
{
	void *obj;
	int index;
	int blockStart;
	int blockEnd;
} SBCRTData;

enum
{
	WORKER_DONE,
	START_WORKER
};

@interface SBConvolvingReverb : SBElement
{
@public
	SBTimeStamp		mLastTS;
	
	FFTSetup	mFFTSetup;
	FFTSetupD	mFFTSetupD;
	
	int			mBlockCount;
	SBBuffer	mInputBuffer;
	SBBuffer	mOutputBuffer;
	SBBuffer	mSignalBuffers[kBlockMaxCount];
	SBBuffer	mFilterBuffers[kBlockMaxCount];

	BOOL		mStop, mStarted;
	int			mNumberOfWorkers;
	SBBuffer	mScratchBuffer[kMaxWorkers];
	SBBuffer	mResultBuffer[kMaxWorkers];

	NSConditionLock *mWorkerLock[kMaxWorkers];
	
	pthread_t		mWorkerThread[kMaxWorkers];
	SBCRTData		mWorkerData[kMaxWorkers];
	
	int			mBlockPos;
	int			mBlockDone;
}

- (void) allocBuffers:(int)count;
- (void) clearBuffers;
- (void) freeBuffers;

- (void) startThreads;
- (void) destroyThreads;
- (void) distributeLoad;

- (void) updateFiltersForBuffer:(float*)buf count:(int)count;

@end


// fft block 8
// fr input:   0 2 4 6
// fi input:   1 3 5 7
// or output: dc 1 2 3
// oi output: nr 1 2 3


