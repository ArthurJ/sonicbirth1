/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBForwardFFT.h"
#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBForwardFFT *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftBlockSize = data->size;
	int fftCount = POW2Table[fftBlockSize];
	int fftCountHalf = fftCount >> 1;
	
	if (obj->mFFTBlockSize != data->size)
	{
		obj->mFFTBlockSize = data->size;
		[(SBForwardFFT*)inObj updateFFTBuffers];
	}
	
	// fr input:   0 2 4 6 x x x x
	// fi input:   1 3 5 7 x x x x
	// or output: dc 1 2 3 x x x x
	// oi output: nr 1 2 3 x x x x
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[1].floatData + offset;
		
		float *or = obj->mAudioBuffers[0].floatData + offset;
		float *oi = obj->mAudioBuffers[1].floatData + offset;
		
		float *fr = obj->mFFTDataBuffer.floatData, *fr2;
		float *fi = fr + fftCountHalf;
		
		DSPSplitComplex sc = {fr , fi};
		
		fr += dataPos;
		fi += dataPos;
		fr2 = fr + fftCount;
		
		while(count--)
		{
			*or++ = *fr      * 0.5f;
			*oi++ = *fi++    * 0.5f;
		
			*fr++ = *fr2;
			*fr2++ = *i++;
			
			dataPos++;
			if (dataPos >= fftCountHalf)
			{
				// get the base of the block
				fr = sc.realp;
				fi = sc.imagp;
				fr2 = fr;

				int j;
				for (j = 0; j < fftCountHalf; j++)
				{
					if (j & 1) *fr++ = *fr2++;
					else *fi++ = *fr2++;
				}
				
				fr2 = sc.realp + fftCount;
				for (j = 0; j < fftCountHalf; j++)
				{
					if (j & 1) *fr++ = *fr2++;
					else *fi++ = *fr2++;
				}
				
				fr = sc.realp;
				fi = sc.imagp;
				fr2 = fr + fftCount;
				
				#if 0
				static int test = 1;
				if (test)
				{
					fprintf(stderr, "ffft --------------------------------------\n");
					int j; for (j = 0; j < fftCount; j++) fprintf(stderr, "%s %f ", (j == fftCountHalf) ? "-=*=-" : "", fr[j]);
					fprintf(stderr, "\n");
					test--;
				}
				#endif

				// do the fft
				vDSP_fft_zrip(obj->mFFTSetup, &sc, 1, fftBlockSize, kFFTDirection_Forward);
				
				// replace pointers
				dataPos = 0;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[1].doubleData + offset;
		
		double *or = obj->mAudioBuffers[0].doubleData + offset;
		double *oi = obj->mAudioBuffers[1].doubleData + offset;
		
		double *fr = obj->mFFTDataBuffer.doubleData, *fr2;
		double *fi = fr + fftCountHalf;
		
		DSPDoubleSplitComplex sc = {fr , fi};
		
		fr += dataPos;
		fi += dataPos;
		fr2 = fr + fftCount;
		
		while(count--)
		{
			*or++ = *fr      * 0.5;
			*oi++ = *fi++    * 0.5;
		
			*fr++ = *fr2;
			*fr2++ = *i++;
			
			dataPos++;
			if (dataPos >= fftCountHalf)
			{
				// get the base of the block
				fr = sc.realp;
				fi = sc.imagp;
				fr2 = fr;

				int j;
				for (j = 0; j < fftCountHalf; j++)
				{
					if (j & 1) *fr++ = *fr2++;
					else *fi++ = *fr2++;
				}
				
				fr2 = sc.realp + fftCount;
				for (j = 0; j < fftCountHalf; j++)
				{
					if (j & 1) *fr++ = *fr2++;
					else *fi++ = *fr2++;
				}
				
				fr = sc.realp;
				fi = sc.imagp;
				fr2 = fr + fftCount;

				// do the fft
				vDSP_fft_zripD(obj->mFFTSetupD, &sc, 1, fftBlockSize, kFFTDirection_Forward);

				// replace pointers
				dataPos = 0;
			}
		}
	}
}

@implementation SBForwardFFT

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Forward FFT";
}

- (NSString*) name
{
	return @"fFFT";
}

- (NSString*) informations
{
	return	@"Outputs the forward fft of the input, with variable block size (delay).";
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
		[mInputNames addObject:@"in"];
		
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

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	return kNormal;
}

- (void) updateFFTBuffers
{
	if (mFFTDataBuffer.ptr) free(mFFTDataBuffer.ptr);
	
	mFFTDataBuffer.ptr = malloc(POW2Table[mFFTBlockSize - 1] * sizeof(double) * 3);
	assert(mFFTDataBuffer.ptr);
	
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mFFTBlockSize - 1] * sizeof(double) * 3);
	
	if (mFFTSetupD) sb_vDSP_destroy_fftsetupD(mFFTSetupD);
	if (mFFTSetup) sb_vDSP_destroy_fftsetup(mFFTSetup);
	mFFTSetupD = sb_vDSP_create_fftsetupD(mFFTBlockSize, kFFTRadix2);
	mFFTSetup = sb_vDSP_create_fftsetup(mFFTBlockSize, kFFTRadix2);
	assert(mFFTSetup);
	assert(mFFTSetupD);
}

- (void) reset
{
	[super reset];
	
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mFFTBlockSize - 1] * sizeof(double) * 3);
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	if (mFFTBlockSize > 0)
	{
		int j, max = POW2Table[mFFTBlockSize - 1] * 3;
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
