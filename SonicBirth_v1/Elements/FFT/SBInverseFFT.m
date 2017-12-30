/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBInverseFFT.h"
#include "SBPow2Table.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBInverseFFT *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftBlockSize = data->size;
	int fftCount = POW2Table[fftBlockSize];
	int fftCountHalf = fftCount >> 1;
	int fftCountQuarter = fftCountHalf >> 1;
	
	if (obj->mCurSize != data->size)
	{
		obj->mCurSize = data->size;
		if (obj->mFFTDataBuffer.ptr) free(obj->mFFTDataBuffer.ptr); 
		if (obj->mFFTSetupD) sb_vDSP_destroy_fftsetupD(obj->mFFTSetupD);
		if (obj->mFFTSetup) sb_vDSP_destroy_fftsetup(obj->mFFTSetup);
		obj->mFFTDataBuffer.ptr = nil;
		obj->mFFTSetupD = nil;
		obj->mFFTSetup = nil;
		[(SBInverseFFT*)inObj updateFFTBuffers];
	}
	
	// fr input:   0 2 4 6 x x x x
	// fi input:   1 3 5 7 x x x x
	// or output: dc 1 2 3 x x x x
	// oi output: nr 1 2 3 x x x x
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *ir = obj->pInputBuffers[1].floatData + offset;
		float *ii = obj->pInputBuffers[2].floatData + offset;
		
		float *o = obj->mAudioBuffers[0].floatData + offset;

		float *fr = obj->mFFTDataBuffer.floatData, *fr2;
		float *fi = fr + fftCountHalf;
		
		float scale = 1.f / (float)fftCount;
		
		DSPSplitComplex sc = {fr , fi};
		
		fr += dataPos;
		fi += dataPos;
		fr2 = fi;

		while(count--)
		{
			*o++  = *fr2++     * scale;
		
			*fr++ = *ir++;
			*fi++ = *ii++;
			
			dataPos++;
			if (dataPos >= fftCountHalf)
			{
				// do the fft
				vDSP_fft_zrip(obj->mFFTSetup, &sc, 1, fftBlockSize, kFFTDirection_Inverse);
			
				// get the base of the block
				fr = sc.realp + fftCountQuarter;
				fi = sc.imagp + fftCountQuarter;
				fr2 = sc.imagp;

				int j;
				for (j = 0; j < fftCountHalf; j++)
				{
					if (j & 1) *fr2++ = *fi++;
					else *fr2++ = *fr++;
				}
				
				fr = sc.realp;
				fi = sc.imagp;
				fr2 = fi;
				
				#if 0
				static int test = 2;
				if (test == 1)
				{
					fprintf(stderr, "ifft --------------------------------------\n");
					int j; for (j = 0; j < fftCount; j++) fprintf(stderr, "%s %f ", (j == fftCountHalf) ? "-=*=-" : "", fr[j] / fftCount);
					fprintf(stderr, "\n");
				}
				if (test > 0) test--;
				#endif

				// replace pointers
				dataPos = 0;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *ir = obj->pInputBuffers[1].doubleData + offset;
		double *ii = obj->pInputBuffers[2].doubleData + offset;
		
		double *o = obj->mAudioBuffers[0].doubleData + offset;

		double *fr = obj->mFFTDataBuffer.doubleData, *fr2;
		double *fi = fr + fftCountHalf;
		
		double scale = 1. / (double)fftCount;
		
		DSPDoubleSplitComplex sc = {fr , fi};
		
		fr += dataPos;
		fi += dataPos;
		fr2 = fi;

		while(count--)
		{
			*o++  = *fr2++     * scale;
		
			*fr++ = *ir++;
			*fi++ = *ii++;
			
			dataPos++;
			if (dataPos >= fftCountHalf)
			{
				// do the fft
				vDSP_fft_zripD(obj->mFFTSetupD, &sc, 1, fftBlockSize, kFFTDirection_Inverse);
				
				// get the base of the block
				fr = sc.realp + fftCountQuarter;
				fi = sc.imagp + fftCountQuarter;
				fr2 = sc.imagp;

				int j;
				for (j = 0; j < fftCountHalf; j++)
				{
					if (j & 1) *fr2++ = *fi++;
					else *fr2++ = *fr++;
				}
				
				fr = sc.realp;
				fi = sc.imagp;
				fr2 = fi;

				// replace pointers
				dataPos = 0;
			}
		}
	}

}

@implementation SBInverseFFT

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Inverse FFT";
}

- (NSString*) name
{
	return @"iFFT";
}

- (NSString*) informations
{
	return	@"Outputs the inverse fft of the input.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		mFFTDataBuffer.ptr = nil;
		mFFTSetupD = nil;
		mFFTSetup = nil;
		mCurSize = 0;
		
		[mInputNames addObject:@"sync"];
		[mInputNames addObject:@"real"];
		[mInputNames addObject:@"imag"];
		
		[mOutputNames addObject:@"out"];
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

- (void) reset
{
	[super reset];
	
	if (mFFTDataBuffer.ptr)
		memset(mFFTDataBuffer.ptr, 0, POW2Table[mCurSize] * sizeof(double));
}

- (void) updateFFTBuffers
{
	mFFTSetupD = sb_vDSP_create_fftsetupD(mCurSize, kFFTRadix2);
	mFFTSetup = sb_vDSP_create_fftsetup(mCurSize, kFFTRadix2);
	mFFTDataBuffer.ptr = malloc(POW2Table[mCurSize] * sizeof(double));
			
	assert(mFFTDataBuffer.ptr);
	assert(mFFTSetup);
	assert(mFFTSetupD);
	
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mCurSize] * sizeof(double));
}

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	if (mCurSize > 0)
	{
		int j, max = POW2Table[mCurSize - 1] * 3;
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
