/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBPointsToFFT.h"
#include "SBPow2Table.h"
#include "SBPointCalculation.h"


static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBPointsToFFT *obj = inObj;
	if (!count) return;
	
	SBFFTSyncData *data = obj->pInputBuffers[0].fftSyncData;
	if (!data->size) return;
	
	int dataPos = data->offset;
	int fftBlockSize = data->size;
	int fftCount = POW2Table[fftBlockSize];
	int fftCountHalf = fftCount >> 1;
	int fftCountQuarter = fftCountHalf >> 1;
	
	if (obj->mFFTBlockSize != data->size)
	{
		obj->mFFTBlockSize = data->size;
		[(SBPointsToFFT*)inObj updateFFTBuffers];
	}
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *fr = obj->mFFTDataBuffer.floatData;
		float *fi = fr + fftCountHalf;

		float *or = obj->mAudioBuffers[0].floatData + offset;
		float *oi = obj->mAudioBuffers[1].floatData + offset;
		
		fr += dataPos;
		fi += dataPos;
		
		float scale = 1.f / (float) fftCount;
		
		while(count--)
		{
			if (!dataPos)
			{
				SBPointsBuffer pts = *(obj->pInputBuffers[1].pointsData);
				int save = 0;
			
				float range05 = obj->pInputBuffers[2].floatData[offset] * 0.05f;
			
				float baseFreq = (float)obj->mSampleRate / (float)fftCountHalf;
				float logmin = lin2log(20, 20, 20000);
				float logmax = lin2log(20000, 20, 20000);
				float logrange = logmax - logmin;
				
				fr = obj->mFFTDataBuffer.floatData;
				fi = fr + fftCountHalf;

				*fr++ = 1; // dc
				*fi++ = 1; // ny
				
				int j;
				for(j = 1; j < fftCountQuarter; j++)
				{
					float freq = baseFreq * j;
					float x = (lin2log(freq, 20, 20000) - logmin) / logrange;
				
					*fr++ = powf(10.f, (pointCalculate(&pts, x, &save)*2.f-1.f) * range05);
				}
				
				fr = obj->mFFTDataBuffer.floatData;
				fi = fr + fftCountHalf;
				
				memset(fr + fftCountQuarter, 0, fftCountQuarter * sizeof(float));
				memset(fi+1, 0, (fftCountHalf-1) * sizeof(float));
				
				#if 1
					static int test = 0;
					
					if (test)
					{
						fprintf(stderr, "pts a --------------------------------------\n");
						for (j = 0; j < fftCount; j++) fprintf(stderr, "%s %f ", (j == fftCountHalf) ? "-=*=-" : "", fr[j]);
						fprintf(stderr, "\n");
					}
			
				DSPSplitComplex sc = {fr , fi};
				vDSP_fft_zrip(obj->mIFFTSetup, &sc, 1, fftBlockSize-1, kFFTDirection_Inverse);
				
					if (test)
					{
						fprintf(stderr, "pts b --------------------------------------\n");
						for (j = 0; j < fftCount; j++) fprintf(stderr, "%s %f ", (j == fftCountHalf) ? "-=*=-" : "", fr[j]);
						fprintf(stderr, "\n");
					}
				
				vDSP_fft_zrip(obj->mFFFTSetup, &sc, 1, fftBlockSize, kFFTDirection_Forward);
				
					if (test)
					{
						fprintf(stderr, "pts c --------------------------------------\n");
						for (j = 0; j < fftCount; j++) fprintf(stderr, "%s %f ", (j == fftCountHalf) ? "-=*=-" : "", fr[j]);
						fprintf(stderr, "\n");
						
						test--;
					}
				
				#else
				
				DSPSplitComplex sc = {fr , fi};
				vDSP_fft_zrip(obj->mIFFTSetup, &sc, 1, fftBlockSize-1, kFFTDirection_Inverse); // balanced by dividing by fftCountHalf
				vDSP_fft_zrip(obj->mFFFTSetup, &sc, 1, fftBlockSize, kFFTDirection_Forward); // balanced by dividing by 2
				
				#endif
			}

			*or++ = *fr++	* scale;
			*oi++ = *fi++	* scale;
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;

		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *fr = obj->mFFTDataBuffer.doubleData;
		double *fi = fr + fftCountHalf;

		double *or = obj->mAudioBuffers[0].doubleData + offset;
		double *oi = obj->mAudioBuffers[1].doubleData + offset;
		
		fr += dataPos;
		fi += dataPos;
		
		double scale = 1.f / (double) fftCount;
		
		while(count--)
		{
			if (!dataPos)
			{
				SBPointsBuffer pts = *(obj->pInputBuffers[1].pointsData);
				int save = 0;
				
				double range05 = obj->pInputBuffers[2].doubleData[offset] * 0.05;
			
				double baseFreq = (double)obj->mSampleRate / (double)fftCountHalf;
				double logmin = lin2log(20, 20, 20000);
				double logmax = lin2log(20000, 20, 20000);
				double logrange = logmax - logmin;
				
				fr = obj->mFFTDataBuffer.doubleData;
				fi = fr + fftCountHalf;
				
				*fr++ = 1; // dc
				*fi++ = 1; // ny
				
				int j;
				for(j = 1; j < fftCountQuarter; j++)
				{
					double freq = baseFreq * j;
					double x = (lin2log(freq, 20, 20000) - logmin) / logrange;
				
					*fr++ = pow(10., (pointCalculate(&pts, x, &save)*2.-1.) * range05);
				}
				
				fr = obj->mFFTDataBuffer.doubleData;
				fi = fr + fftCountHalf;
				
				memset(fr + fftCountQuarter, 0, fftCountQuarter * sizeof(double));
				memset(fi+1, 0, (fftCountHalf-1) * sizeof(double));

				DSPDoubleSplitComplex sc = {fr , fi};
				vDSP_fft_zripD(obj->mIFFTSetupD, &sc, 1, fftBlockSize-1, kFFTDirection_Inverse);
				vDSP_fft_zripD(obj->mFFFTSetupD, &sc, 1, fftBlockSize, kFFTDirection_Forward);
			}

			*or++ = *fr++	* scale;
			*oi++ = *fi++	* scale;
			
			dataPos++;
			if (dataPos >= fftCountHalf) dataPos = 0;
		}
	}
}


@implementation SBPointsToFFT

+ (SBElementCategory) category
{
	return kFFT;
}

+ (NSString*) name
{
	return @"Points To FFT";
}

- (NSString*) name
{
	return @"pts2fft";
}

- (NSString*) informations
{
	return	@"Transforms a points function into frequency amplitudes. Range is in db.";
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 0) return kFFTSync;
	else if (idx == 1) return kPoints;
	else return kNormal;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
		
		[mInputNames addObject:@"sync"];
		[mInputNames addObject:@"pts"];
		[mInputNames addObject:@"range"];
		
		[mOutputNames addObject:@"real"];
		[mOutputNames addObject:@"imag"];
		
		mFFTBlockSize = 6; // 2^6 == 64 -- 2^8 == 256
		
		[self updateFFTBuffers];
	}
	return self;
}

- (void) dealloc
{
	if (mFFTDataBuffer.ptr) free(mFFTDataBuffer.ptr); 
	
	if (mFFFTSetupD) sb_vDSP_destroy_fftsetupD(mFFFTSetupD);
	if (mFFFTSetup) sb_vDSP_destroy_fftsetup(mFFFTSetup);
	
	if (mIFFTSetupD) sb_vDSP_destroy_fftsetupD(mIFFTSetupD);
	if (mIFFTSetup) sb_vDSP_destroy_fftsetup(mIFFTSetup);
	
	[super dealloc];
}

- (void) reset
{
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mFFTBlockSize] * sizeof(double));

	[super reset];
}

- (void) updateFFTBuffers
{
	if (mFFTDataBuffer.ptr) free(mFFTDataBuffer.ptr);
	
	mFFTDataBuffer.ptr = malloc(POW2Table[mFFTBlockSize] * sizeof(double));
	assert(mFFTDataBuffer.ptr);
	
	memset(mFFTDataBuffer.ptr, 0, POW2Table[mFFTBlockSize] * sizeof(double));
	
	if (mFFFTSetupD) sb_vDSP_destroy_fftsetupD(mFFFTSetupD);
	if (mFFFTSetup) sb_vDSP_destroy_fftsetup(mFFFTSetup);
	
	if (mIFFTSetupD) sb_vDSP_destroy_fftsetupD(mIFFTSetupD);
	if (mIFFTSetup) sb_vDSP_destroy_fftsetup(mIFFTSetup);
	
	mFFFTSetupD = sb_vDSP_create_fftsetupD(mFFTBlockSize, kFFTRadix2);
	mFFFTSetup = sb_vDSP_create_fftsetup(mFFTBlockSize, kFFTRadix2);
	
	mIFFTSetupD = sb_vDSP_create_fftsetupD(mFFTBlockSize - 1, kFFTRadix2);
	mIFFTSetup = sb_vDSP_create_fftsetup(mFFTBlockSize - 1, kFFTRadix2);
	
	assert(mFFFTSetup);
	assert(mFFFTSetupD);
	
	assert(mIFFTSetup);
	assert(mIFFTSetupD);
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
