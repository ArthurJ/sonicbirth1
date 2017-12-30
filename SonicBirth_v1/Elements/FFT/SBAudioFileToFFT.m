/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBAudioFileToFFT.h"
#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAudioFileToFFT *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftBlockSize = data->size;
	int fftCount = POW2Table[fftBlockSize];
	int fftCountHalf = fftCount >> 1;
	
	BOOL updateFile = NO;
	
	if (obj->mFFTBlockSize != data->size)
	{
		obj->mFFTBlockSize = data->size;
		[(SBAudioFileToFFT*)inObj updateFFTBuffers];
		updateFile = YES;
	}
	
	SBTimeStamp ts = obj->pInputBuffers[1].audioData->time;
	if (ts != obj->mLastTS) updateFile = YES;

	if (updateFile)
	{
		float *bf = obj->pInputBuffers[1].audioData->data;
		int bfc = obj->pInputBuffers[1].audioData->count;
		
		// fr input:   0 2 4 6 x x x x
		// fi input:   1 3 5 7 x x x x
		// or output: dc 1 2 3 x x x x
		// oi output: nr 1 2 3 x x x x
		
		if (bfc && bf)
		{
			if (obj->mPrecision == kFloatPrecision)
			{
				float *fr = obj->mFFTDataBuffer.floatData;
				float *fi = fr + fftCountHalf;
			
				DSPSplitComplex sc = {fr , fi};
				
				memset(fr, 0, fftCount * sizeof(float));
				
				int copy = (bfc > fftCountHalf) ? fftCountHalf : bfc;
				int i;
				for (i = 0; i < copy; i++)
				{
					if (i & 1) *fi++ = *bf++;
					else *fr++ = *bf++;
				}
				
				vDSP_fft_zrip(obj->mFFTSetup, &sc, 1, fftBlockSize, kFFTDirection_Forward);
				
				// scale back
				fr = obj->mFFTDataBuffer.floatData;
				for (i = 0; i < fftCount; i++) *fr++ *= 0.5f; 
				
				#if 0
				static int test = 1;
				if (test)
				{
					fr = obj->mFFTDataBuffer.floatData;
					fprintf(stderr, "af2fft --------------------------------------\n");
					int j; for (j = 0; j < fftCountHalf; j++) fprintf(stderr, "%f ", *fr++);
					fprintf(stderr, "*********\n");
					for (j = 0; j < fftCountHalf; j++) fprintf(stderr, "%f ", *fr++);
					fprintf(stderr, "\n");
					test--;
				}
				#endif
			}
			else
			{
				double *fr = obj->mFFTDataBuffer.doubleData;
				double *fi = fr + fftCountHalf;
			
				DSPDoubleSplitComplex sc = {fr , fi};
				
				memset(fr, 0, fftCount * sizeof(double));
				
				int copy = (bfc > fftCountHalf) ? fftCountHalf : bfc;
				int i;
				for (i = 0; i < copy; i++)
				{
					if (i & 1) *fi++ = *bf++;
					else *fr++ = *bf++;
				}
				
				vDSP_fft_zripD(obj->mFFTSetupD, &sc, 1, fftBlockSize, kFFTDirection_Forward);
				
				// scale back
				fr = obj->mFFTDataBuffer.doubleData;
				for (i = 0; i < fftCount; i++) *fr++ *= 0.5; 
			}
		}
		obj->mLastTS = ts;
	}
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *or = obj->mAudioBuffers[0].floatData + offset;
		float *oi = obj->mAudioBuffers[1].floatData + offset;
		
		float *fr = obj->mFFTDataBuffer.floatData;
		float *fi = fr + fftCountHalf;

		fr += dataPos;
		fi += dataPos;
		
		while(count--)
		{
			*or++ = *fr++;
			*oi++ = *fi++;
			
			dataPos++;
			if (dataPos >= fftCountHalf)
			{
				fr = obj->mFFTDataBuffer.floatData;
				fi = fr + fftCountHalf;
				
				dataPos = 0;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *or = obj->mAudioBuffers[0].doubleData + offset;
		double *oi = obj->mAudioBuffers[1].doubleData + offset;
		
		double *fr = obj->mFFTDataBuffer.doubleData;
		double *fi = fr + fftCountHalf;

		fr += dataPos;
		fi += dataPos;
		
		while(count--)
		{
			*or++ = *fr++;
			*oi++ = *fi++;
			
			dataPos++;
			if (dataPos >= fftCountHalf)
			{
				fr = obj->mFFTDataBuffer.doubleData;
				fi = fr + fftCountHalf;
				
				dataPos = 0;
			}
		}
	}
}

@implementation SBAudioFileToFFT

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Audio file To FFT";
}

- (NSString*) name
{
	return @"af2fft";
}

- (NSString*) informations
{
	return	@"Transforms an audio file to an fft block (considering samples up to half the fft block size).";
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	return kAudioBuffer;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		mFFTBlockSize = 6; // 2^6 == 64 -- 2^8 == 256
		
		[self updateFFTBuffers];
	
		[mInputNames addObject:@"sync"];
		[mInputNames addObject:@"af"];
		
		[mOutputNames addObject:@"real"];
		[mOutputNames addObject:@"imag"];
	}
	return self;
}

- (void) dealloc
{
	if (mFFTDataBuffer.ptr) free(mFFTDataBuffer.ptr); 
	if (mFFTSetupD) sb_vDSP_destroy_fftsetupD(mFFTSetupD);
	if (mFFTSetup) sb_vDSP_destroy_fftsetup(mFFTSetup);
	[super dealloc];
}

- (void) reset
{
	mLastTS = 0;
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mFFTBlockSize] * sizeof(double));

	[super reset];
}

- (void) updateFFTBuffers
{
	if (mFFTDataBuffer.ptr) free(mFFTDataBuffer.ptr);
	
	mFFTDataBuffer.ptr = malloc(POW2Table[mFFTBlockSize] * sizeof(double));
	assert(mFFTDataBuffer.ptr);
	
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mFFTBlockSize] * sizeof(double));
	
	if (mFFTSetupD) sb_vDSP_destroy_fftsetupD(mFFTSetupD);
	if (mFFTSetup) sb_vDSP_destroy_fftsetup(mFFTSetup);
	mFFTSetupD = sb_vDSP_create_fftsetupD(mFFTBlockSize, kFFTRadix2);
	mFFTSetup = sb_vDSP_create_fftsetup(mFFTBlockSize, kFFTRadix2);
	assert(mFFTSetup);
	assert(mFFTSetupD);
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	if (mFFTBlockSize > 0)
	{
		int j, max = POW2Table[mFFTBlockSize];
		if (mPrecision == kFloatPrecision)
		{
			// float to double
			for (j = max - 1; j >= 0; j--)
				mFFTDataBuffer.doubleData[j] = mFFTDataBuffer.floatData[j];
		}
		else
		{
			// double to float
			for (j = 0; j < max; j++)
				mFFTDataBuffer.floatData[j] = mFFTDataBuffer.doubleData[j];
		}
	}
	
	[super changePrecision:precision];
}


@end
