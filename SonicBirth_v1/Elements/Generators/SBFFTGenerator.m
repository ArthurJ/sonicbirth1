/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFFTGenerator.h"
#import "SBPointCalculation.h"

#define kFFTSizeBase2 (12)
#define kFFTSizeBase10 (4096)

#import "SBMidiArgument.h"

// double midiNoteToHertz(int num); // 0 .. 127

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBFFTGenerator *obj = inObj;
	
	if (!count) return;
	
	SBPointsBuffer *ptsIn = obj->pInputBuffers[0].pointsData;
	SBPointsBuffer *ptsCur = &(obj->mPts);
	
	double *buf = obj->mBuf;
	
	if (memcmp(ptsIn, ptsCur, sizeof(SBPointsBuffer)))
	{
		*ptsCur = *ptsIn;
	
		double baseFreq = (double)obj->mSampleRate / (double)(kFFTSizeBase10);
		double logmin = lin2log(20, 20, 20000);
		double logmax = lin2log(20000, 20, 20000);
		double logrange = logmax - logmin;
				
		double *fr = buf;
		double *fi = fr + (kFFTSizeBase10/2);
		
		int save = 0;
		double scale = 0;
		
		memset(fr, 0, kFFTSizeBase10 * sizeof(double));
				
		int j;
		for(j = 0; j < 128; j++)
		{
			double freq = midiNoteToHertz(j);
			double x = (lin2log(freq, 20, 20000) - logmin) / logrange;

			double a = pointCalculate(ptsCur, x, &save) * 2. - 1.; scale += a;
			double p = j * 11.051981; // randomize somewhat the phase
			
			double r = a * cos(p);
			double i = a * sin(p);
			
			// find nearest bin
			int bin = 1 + (freq / baseFreq);
			if (bin < 0) bin = 0; else if (bin >= (kFFTSizeBase10/2)) bin = (kFFTSizeBase10/2) - 1;
			
			fr[bin] = r;
			fi[bin] = i;
		}
		
		DSPDoubleSplitComplex sc = {fr , fi};
		vDSP_fft_zripD(obj->mFFTSetup, &sc, 1, kFFTSizeBase2, kFFTDirection_Inverse);
		
		scale = 1. / (scale * 2);
		for(j = 0; j < kFFTSizeBase10; j++) *fr++ *= scale;
	}
	
	// copy back sound into buffer
	int pos = obj->mPosition;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			int off = (pos & 1) ? (kFFTSizeBase10/2) : 0;
			int bas = pos >> 1;
			*o++ = buf[bas + off];
			pos++;
			if (pos >= kFFTSizeBase10) pos = 0;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			int off = (pos & 1) ? (kFFTSizeBase10/2) : 0;
			int bas = pos >> 1;
			*o++ = buf[bas + off];
			pos++;
			if (pos >= kFFTSizeBase10) pos = 0;
		}
	}
	
	obj->mPosition = pos;
}

@implementation SBFFTGenerator

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mFFTSetup = sb_vDSP_create_fftsetupD(kFFTSizeBase2, kFFTRadix2);
		mBuf = (double*) malloc(kFFTSizeBase10 * sizeof(double));
		if (!mFFTSetup || !mBuf)
		{
			[self release];
			return nil;
		}
		
		memset(mBuf, 0, kFFTSizeBase10 * sizeof(double));
	
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"pts"];
		[mOutputNames addObject:@"snd"];
	}
	return self;
}


- (void) dealloc
{
	if (mFFTSetup) sb_vDSP_destroy_fftsetupD(mFFTSetup);
	if (mBuf) free(mBuf);
	[super dealloc];
}

+ (NSString*) name
{
	return @"FFT Generator";
}

- (NSString*) name
{
	return @"fft gen";
}

+ (SBElementCategory) category
{
	return kGenerator;
}

- (NSString*) informations
{
	return @"Generates waves using FFT based on input points..";
}

- (void) reset
{
	[super reset];

	mPosition = 0;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	return kPoints;
}


@end
