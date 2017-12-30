/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBConvolvingReverb.h"

// #define DEBUG_CONVOLVER

#ifndef DEBUG_CONVOLVER
	#define LOG(args...)
#else
	static int gLogCount = 1000;
	#define LOG(args...) \
		do \
		{ \
			if (gLogCount > 0) \
			{ \
				fprintf(stderr, "SonicBirth (conv): " args); \
				gLogCount--; \
			} \
		} while(0);
	#warning "convolver logging enabled."
#endif

// ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ 

//
//
// Rotate Buffer
//
//

static inline void rotateBuffers(SBBuffer *buffers, int count)
{
	// a b c d -> d a b c
	void *last = buffers[count - 1].ptr;

	int i;
	for (i = count - 1; i > 0; i--) buffers[i].ptr = buffers[i-1].ptr;

	buffers[0].ptr = last;
}

//
//
// Block convolve
//
//

static inline void convolve_float(float *i1, float *i2, float *o)
{
	float *a = i1, *b = i1 + kBlockSizeHalf;
	float *c = i2, *d = i2 + kBlockSizeHalf;
	float *r = o, *i = o + kBlockSizeHalf;
	
	// do the particuliar case of dc and ny
	*r++ = *a++ * *c++;
	*i++ = *b++ * *d++;
	
	// realign pointers to 16 bytes (for float == do 3 values)
	int s;
	for (s = 0; s < 3; s++)
	{
		*r++ = *a   * *c   -  *b   * *d  ;
		*i++ = *b++ * *c++ +  *a++ * *d++;
	}

	DSPSplitComplex sc_i1 = { a, b }; 
	DSPSplitComplex sc_i2 = { c, d }; 
	DSPSplitComplex sc_o  = { r, i };
	
	vDSP_zvmul(&sc_i1, 1, &sc_i2, 1, &sc_o, 1, (kBlockSizeHalf - 4), 1);
}

static inline void convolve_double(double *i1, double *i2, double *o)
{
	double *a = i1, *b = i1 + kBlockSizeHalf;
	double *c = i2, *d = i2 + kBlockSizeHalf;
	double *r = o, *i = o + kBlockSizeHalf;
	
	// do the particuliar case of dc and ny
	*r++ = *a++ * *c++;
	*i++ = *b++ * *d++;
	
	// realign pointers to 16 bytes (for double == do 1 values)
	*r++ = *a   * *c   -  *b   * *d  ;
	*i++ = *b++ * *c++ +  *a++ * *d++;

	DSPDoubleSplitComplex sc_i1 = { a, b }; 
	DSPDoubleSplitComplex sc_i2 = { c, d }; 
	DSPDoubleSplitComplex sc_o  = { r, i };
	
	vDSP_zvmulD(&sc_i1, 1, &sc_i2, 1, &sc_o, 1, (kBlockSizeHalf - 2), 1);
}

//
//
// Block reverb
//
//

static void reverb_float(	FFTSetup setup, SBBuffer output, SBBuffer scratch, 
							SBBuffer *bufferSignal, SBBuffer *filter,
							int blockStart, int blockMax, BOOL clear )
{
	// clear output
	float *op1 = output.floatData + kBlockSizeQuarter;
	float *op2 = output.floatData + (kBlockSizeHalf + kBlockSizeQuarter);
	
	if (clear)
	{
		memset(op1, 0, kBlockSizeQuarter * sizeof(float));
		memset(op2, 0, kBlockSizeQuarter * sizeof(float));
	}
	
	// convolve, defft, and accumulate everything
	DSPSplitComplex sc_s = { scratch.floatData, scratch.floatData + kBlockSizeHalf };
	float *sp1 = scratch.floatData + kBlockSizeQuarter;
	float *sp2 = scratch.floatData + (kBlockSizeHalf + kBlockSizeQuarter);
	int i;
	for (i = blockStart; i < blockMax; i++)
	{
		convolve_float(bufferSignal[i].floatData, filter[i].floatData, scratch.floatData);

		vDSP_fft_zrip(setup, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Inverse);
		vDSP_vadd(sp1, 1, op1, 1, op1, 1, kBlockSizeQuarter);
		vDSP_vadd(sp2, 1, op2, 1, op2, 1, kBlockSizeQuarter);
	}
}

static void reverb_double(	FFTSetupD setup, SBBuffer output, SBBuffer scratch, 
							SBBuffer *bufferSignal, SBBuffer *filter,
							int blockStart, int blockMax, BOOL clear )
{
	// clear output
	double *op1 = output.doubleData + kBlockSizeQuarter;
	double *op2 = output.doubleData + (kBlockSizeHalf + kBlockSizeQuarter);
		
	if (clear)
	{
		memset(op1, 0, kBlockSizeQuarter * sizeof(double));
		memset(op2, 0, kBlockSizeQuarter * sizeof(double));
	}
	
	// convolve, defft, and accumulate everything
	DSPDoubleSplitComplex sc_s = { scratch.doubleData, scratch.doubleData + kBlockSizeHalf };
	double *sp1 = scratch.doubleData + kBlockSizeQuarter;
	double *sp2 = scratch.doubleData + (kBlockSizeHalf + kBlockSizeQuarter);
	int i;
	for (i = blockStart; i < blockMax; i++)
	{
		convolve_double(bufferSignal[i].doubleData, filter[i].doubleData, scratch.doubleData);

		vDSP_fft_zripD(setup, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Inverse);
		vDSP_vaddD(sp1, 1, op1, 1, op1, 1, kBlockSizeQuarter);
		vDSP_vaddD(sp2, 1, op2, 1, op2, 1, kBlockSizeQuarter);
	}
}

//
//
// worker thread
//
//

#include <mach/mach_init.h>
#include <mach/mach_time.h>
#include <mach/thread_policy.h>
#include <CoreServices/CoreServices.h>

kern_return_t	thread_policy_set(
					thread_t					thread,
					thread_policy_flavor_t		flavor,
					thread_policy_t				policy_info,
					mach_msg_type_number_t		count);

typedef union
{
	uint64_t u;
	Nanoseconds n;
	AbsoluteTime a;
} TimeData;

static uint64_t secondsToMachTime(double sec)
{
	TimeData t;
	t.u = sec * 1e9;
	t.a = NanosecondsToAbsolute(t.n);
	return t.u;
}

static void setTimePolicy(uint64_t cp, uint64_t pr)
{
//	fprintf(stderr, "setTimePolicy cp: %lld pr: %lld ratio: %f\n", cp, pr, (double)cp/(double)pr);

	int ret;
    struct thread_time_constraint_policy ttcpolicy;

    ttcpolicy.computation = cp;
    ttcpolicy.period = pr;
    ttcpolicy.constraint = pr;
    ttcpolicy.preemptible = 1;
	
	ret = thread_policy_set(mach_thread_self(),
							THREAD_TIME_CONSTRAINT_POLICY,
							(thread_policy_t)&ttcpolicy,
							THREAD_TIME_CONSTRAINT_POLICY_COUNT);
							
    if (ret != KERN_SUCCESS)
		fprintf(stderr, "set_realtime() failed with err %i.\n", ret);
}

static void * worker_thread(void *threadData)
{
	int pos = 0;
	uint64_t start, end, elapsed = 0;

	SBCRTData *data = (SBCRTData*)threadData;
	
	// cache some info
	int idx = data->index;

	SBConvolvingReverb *obj = data->obj;
	
	FFTSetup	setup = obj->mFFTSetup;
	FFTSetupD	setupD = obj->mFFTSetupD;
	
	SBBuffer	*bufferSignal = obj->mSignalBuffers;
	SBBuffer	*filter = obj->mFilterBuffers;
	
	SBBuffer	result = obj->mResultBuffer[idx];
	SBBuffer	scratch = obj->mScratchBuffer[idx];
	
	NSConditionLock *lock = obj->mWorkerLock[idx];
	
	LOG("thread %i launched\n", idx)
	
	while(1)
	{
		[lock lockWhenCondition:START_WORKER];
		if (obj->mStop) break;
		
		LOG("\tthread %i beg processing\n", idx)
		
		start = mach_absolute_time();
		
		int blockStart = data->blockStart;
		int blockEnd = data->blockEnd;
			
		if (obj->mPrecision == kFloatPrecision)
			reverb_float(	setup, result, scratch,
							bufferSignal, filter, blockStart, blockEnd, YES);
		else
			reverb_double(	setupD, result, scratch,
							bufferSignal, filter, blockStart, blockEnd, YES);
							
		end = mach_absolute_time();;
		elapsed += end - start;

		LOG("\tthread %i end processing\n", idx)
		[lock unlockWithCondition:WORKER_DONE];
		
		// update time policy

		pos += kBlockSizeHalf;
		int sr = obj->mSampleRate;
		if (pos >= sr)
		{
			// ask for a 20 ms period
			// as the sys limit is 50 ms for computation
			// see  osfmk/kern/sched_prim.c
			// and  osfmk/kern/thread_policy.c
			double pr_d = 0.020;
			
			// ask for double the measured amount
			uint64_t cp = elapsed * pr_d * 2.;
			uint64_t pr = secondsToMachTime(pr_d);
			
			// don't ask for more than 95%
			uint64_t mx = pr * 0.95;
			if (cp > mx) cp = mx;
			
			setTimePolicy(cp, pr);
			
			pos = 0;
			elapsed = 0;
		}
	}
	
	LOG("thread %i terminated\n", idx)

	pthread_exit(NULL);
}

//
//
// Signal shift
//
//

static inline void copySignal_float(SBBuffer input)
{
	// copy (4 5 6 7) over (0 1 2 3)
	memcpy(		input.floatData,
				input.floatData + kBlockSizeQuarter,
				kBlockSizeQuarter * sizeof(float));
				
	memcpy(		input.floatData + kBlockSizeHalf,
				input.floatData + (kBlockSizeHalf + kBlockSizeQuarter),
				kBlockSizeQuarter * sizeof(float));
}

static inline void copySignal_double(SBBuffer input)
{
	// copy (4 5 6 7) over (0 1 2 3)
	memcpy(		input.doubleData,
				input.doubleData + kBlockSizeQuarter,
				kBlockSizeQuarter * sizeof(double));
				
	memcpy(		input.doubleData + kBlockSizeHalf,
				input.doubleData + (kBlockSizeHalf + kBlockSizeQuarter),
				kBlockSizeQuarter * sizeof(double));
}

//
//
// Calcultating fonction
//
//

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBConvolvingReverb *obj = inObj;
	if (!count) return;
	
	// check if IR has changed
	SBTimeStamp ts = obj->pInputBuffers[1].audioData->time;
	if (ts != obj->mLastTS)
	{
		float *bf = obj->pInputBuffers[1].audioData->data;
		int bfc = obj->pInputBuffers[1].audioData->count;
		[(SBConvolvingReverb*)inObj updateFiltersForBuffer:bf count:bfc];
		obj->mLastTS = ts;
	}
	
	// check if IR is empty
	int blockCount = obj->mBlockCount;
	if (blockCount < 1)
	{
		if (obj->mPrecision == kFloatPrecision)
		{
			float *o = obj->mAudioBuffers[0].floatData + offset;
			memset(o, 0, count * sizeof(float));
		}
		else
		{
			double *o = obj->mAudioBuffers[0].doubleData + offset;
			memset(o, 0, count * sizeof(double));
		}
		return;
	}
	
	// do reverb
	int pos = obj->mBlockPos;
	int	w, workers = obj->mNumberOfWorkers;
	NSConditionLock **locks = obj->mWorkerLock;
	
	SBBuffer input = obj->mInputBuffer;
	SBBuffer bufferSignal = obj->mSignalBuffers[0];
	SBBuffer filter = obj->mFilterBuffers[0];
	SBBuffer *results = obj->mResultBuffer;
	SBBuffer output = obj->mOutputBuffer;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *sig = obj->mInputBuffer.floatData;
		
		float *rev = obj->mOutputBuffer.floatData;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		
		FFTSetup setup = obj->mFFTSetup;
		
		while(count--)
		{
			// write and read from second part of blocks (4 5 6 7)
			int off = (pos & 1) ? (kBlockSizeHalf+kBlockSizeQuarter) : kBlockSizeQuarter;
			int bas = pos >> 1;
			int tot = off + bas;
		
			sig[tot] = *i++;
			*o++ = rev[tot];
			
			pos++;
			if (pos >= kBlockSizeHalf)
			{
				// do fft on the input
				DSPSplitComplex sc_i = { input.floatData, input.floatData + kBlockSizeHalf };
				DSPSplitComplex sc_s = { bufferSignal.floatData, bufferSignal.floatData + kBlockSizeHalf };
				vDSP_fft_zrop(setup, &sc_i, 1, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Forward);
				
				// scale input ffft
				float scale = 0.5f;
				vDSP_vsmul(bufferSignal.floatData, 1, &scale, bufferSignal.floatData, 1, kBlockSize);
			
				// do the head
				DSPSplitComplex sc_o = { output.floatData, output.floatData + kBlockSizeHalf };
				convolve_float(bufferSignal.floatData, filter.floatData, output.floatData);
				vDSP_fft_zrip(setup, &sc_o, 1, kBlockSizeBase2, kFFTDirection_Inverse);
				
				// do tail
				float *op1 = output.floatData + kBlockSizeQuarter;
				float *op2 = output.floatData + (kBlockSizeHalf + kBlockSizeQuarter);
				
				LOG("controller acquiring %i workers\n", workers)

				for (w = 0; w < workers; w++)
				{
					// lock workers
					[locks[w] lockWhenCondition:WORKER_DONE];
					LOG("controller acquired %i\n", w)
							
					// get and accumulate data
					float *rp1 = results[w].floatData + kBlockSizeQuarter;
					float *rp2 = results[w].floatData + (kBlockSizeHalf + kBlockSizeQuarter);
					
					vDSP_vadd(rp1, 1, op1, 1, op1, 1, kBlockSizeQuarter);
					vDSP_vadd(rp2, 1, op2, 1, op2, 1, kBlockSizeQuarter);
				}
				
				rotateBuffers(obj->mSignalBuffers, blockCount);
				
				LOG("controller restarting workers\n")
				
				for (w = 0; w < workers; w++)
					[locks[w] unlockWithCondition:START_WORKER];
							
				// scale result
				scale = 1.f / kBlockSize;
				vDSP_vsmul(op1, 1, &scale, op1, 1, kBlockSizeQuarter);
				vDSP_vsmul(op2, 1, &scale, op2, 1, kBlockSizeQuarter);

				// shift input
				copySignal_float(obj->mInputBuffer);
				pos = 0;
			}
		}
	}
	else
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *sig = obj->mInputBuffer.doubleData;
		
		double *rev = obj->mOutputBuffer.doubleData;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		FFTSetupD setup = obj->mFFTSetupD;
		
		while(count--)
		{
			// write and read from second part of blocks (4 5 6 7)
			int off = (pos & 1) ? (kBlockSizeHalf+kBlockSizeQuarter) : kBlockSizeQuarter;
			int bas = pos >> 1;
			int tot = off + bas;
		
			sig[tot] = *i++;
			*o++ = rev[tot];
			
			pos++;
			if (pos >= kBlockSizeHalf)
			{
				// do fft on the input
				DSPDoubleSplitComplex sc_i = { input.doubleData, input.doubleData + kBlockSizeHalf };
				DSPDoubleSplitComplex sc_s = { bufferSignal.doubleData, bufferSignal.doubleData + kBlockSizeHalf };
				vDSP_fft_zropD(setup, &sc_i, 1, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Forward);
				
				// scale input ffft
				double scale = 0.5;
				vDSP_vsmulD(bufferSignal.doubleData, 1, &scale, bufferSignal.doubleData, 1, kBlockSize);
			
				// do the head
				DSPDoubleSplitComplex sc_o = { output.doubleData, output.doubleData + kBlockSizeHalf };
				convolve_double(bufferSignal.doubleData, filter.doubleData, output.doubleData);
				vDSP_fft_zripD(setup, &sc_o, 1, kBlockSizeBase2, kFFTDirection_Inverse);
				
				// do tail
				double *op1 = output.doubleData + kBlockSizeQuarter;
				double *op2 = output.doubleData + (kBlockSizeHalf + kBlockSizeQuarter);
				
				LOG("controller acquiring %i workers\n", workers)

				for (w = 0; w < workers; w++)
				{
					// lock workers
					[locks[w] lockWhenCondition:WORKER_DONE];
					LOG("controller acquired %i\n", w)
										
					// get and accumulate data
					double *rp1 = results[w].doubleData + kBlockSizeQuarter;
					double *rp2 = results[w].doubleData + (kBlockSizeHalf + kBlockSizeQuarter);
					
					vDSP_vaddD(rp1, 1, op1, 1, op1, 1, kBlockSizeQuarter);
					vDSP_vaddD(rp2, 1, op2, 1, op2, 1, kBlockSizeQuarter);
				}
				
				rotateBuffers(obj->mSignalBuffers, blockCount);
				
				LOG("controller restarting workers\n")
				
				for (w = 0; w < workers; w++)
					[locks[w] unlockWithCondition:START_WORKER];
				
				// scale result
				scale = 1. / kBlockSize;
				vDSP_vsmulD(op1, 1, &scale, op1, 1, kBlockSizeQuarter);
				vDSP_vsmulD(op2, 1, &scale, op2, 1, kBlockSizeQuarter);
							
				// shift input
				copySignal_double(obj->mInputBuffer);
				pos = 0;
			}
		}
	}
	obj->mBlockPos = pos;
}


//
//
// Calcultating fonction - No workers
//
//




static void privateCalcFuncNoWorkers(void *inObj, int count, int offset)
{
	SBConvolvingReverb *obj = inObj;
	if (!count) return;
	
	// check if IR has changed
	SBTimeStamp ts = obj->pInputBuffers[1].audioData->time;
	if (ts != obj->mLastTS)
	{
		float *bf = obj->pInputBuffers[1].audioData->data;
		int bfc = obj->pInputBuffers[1].audioData->count;
		[(SBConvolvingReverb*)inObj updateFiltersForBuffer:bf count:bfc];
		obj->mLastTS = ts;
	}
	
	// check if IR is empty
	int blockCount = obj->mBlockCount;
	if (blockCount < 1)
	{
		if (obj->mPrecision == kFloatPrecision)
		{
			float *o = obj->mAudioBuffers[0].floatData + offset;
			memset(o, 0, count * sizeof(float));
		}
		else
		{
			double *o = obj->mAudioBuffers[0].doubleData + offset;
			memset(o, 0, count * sizeof(double));
		}
		return;
	}
	
	// do reverb
	int pos = obj->mBlockPos, done = obj->mBlockDone;
	
	SBBuffer input = obj->mInputBuffer;
	SBBuffer *bufferSignal = obj->mSignalBuffers;
	SBBuffer *filter = obj->mFilterBuffers;
	SBBuffer scratch = obj->mScratchBuffer[0];
	SBBuffer result = obj->mResultBuffer[0];
	SBBuffer output = obj->mOutputBuffer;

	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *sig = obj->mInputBuffer.floatData;
		
		float *rev = obj->mOutputBuffer.floatData;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		
		FFTSetup setup = obj->mFFTSetup;
		
		while(count--)
		{
			// write and read from second part of blocks (4 5 6 7)
			int off = (pos & 1) ? (kBlockSizeHalf+kBlockSizeQuarter) : kBlockSizeQuarter;
			int bas = pos >> 1;
			int tot = off + bas;
		
			sig[tot] = *i++;
			*o++ = rev[tot];
			
			pos++;
			if (pos >= kBlockSizeHalf)
			{
				// make sure all is done
				reverb_float(	setup, result, scratch,
								bufferSignal, filter, done, blockCount, NO);
			
				// do fft on the input
				DSPSplitComplex sc_i = { input.floatData, input.floatData + kBlockSizeHalf };
				DSPSplitComplex sc_s = { bufferSignal[0].floatData, bufferSignal[0].floatData + kBlockSizeHalf };
				vDSP_fft_zrop(setup, &sc_i, 1, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Forward);
				
				// scale input ffft
				float scale = 0.5f;
				vDSP_vsmul(bufferSignal[0].floatData, 1, &scale, bufferSignal[0].floatData, 1, kBlockSize);
			
				// do the head
				DSPSplitComplex sc_o = { output.floatData, output.floatData + kBlockSizeHalf };
				convolve_float(bufferSignal[0].floatData, filter[0].floatData, output.floatData);
				vDSP_fft_zrip(setup, &sc_o, 1, kBlockSizeBase2, kFFTDirection_Inverse);
				
				// do tail
				float *op1 = output.floatData + kBlockSizeQuarter;
				float *op2 = output.floatData + (kBlockSizeHalf + kBlockSizeQuarter);

				float *rp1 = result.floatData + kBlockSizeQuarter;
				float *rp2 = result.floatData + (kBlockSizeHalf + kBlockSizeQuarter);
					
				vDSP_vadd(rp1, 1, op1, 1, op1, 1, kBlockSizeQuarter);
				vDSP_vadd(rp2, 1, op2, 1, op2, 1, kBlockSizeQuarter);
				
				// clear result
				memset(rp1, 0, kBlockSizeQuarter * sizeof(float));
				memset(rp2, 0, kBlockSizeQuarter * sizeof(float));

				rotateBuffers(obj->mSignalBuffers, blockCount);

				// scale result
				scale = 1.f / kBlockSize;
				vDSP_vsmul(op1, 1, &scale, op1, 1, kBlockSizeQuarter);
				vDSP_vsmul(op2, 1, &scale, op2, 1, kBlockSizeQuarter);

				// shift input
				copySignal_float(obj->mInputBuffer);
				pos = 0; done = 1;
			}
		}
		
		int shouldBeDone = (pos  * blockCount) / kBlockSizeHalf;
		if (shouldBeDone > blockCount) shouldBeDone = blockCount;
		if (shouldBeDone > done)
		{
			reverb_float(	setup, result, scratch,
							bufferSignal, filter, done, shouldBeDone, NO);
			done = shouldBeDone;
		}				
	}
	else
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *sig = obj->mInputBuffer.doubleData;
		
		double *rev = obj->mOutputBuffer.doubleData;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		FFTSetupD setup = obj->mFFTSetupD;
		
		while(count--)
		{
			// write and read from second part of blocks (4 5 6 7)
			int off = (pos & 1) ? (kBlockSizeHalf+kBlockSizeQuarter) : kBlockSizeQuarter;
			int bas = pos >> 1;
			int tot = off + bas;
		
			sig[tot] = *i++;
			*o++ = rev[tot];
			
			pos++;
			if (pos >= kBlockSizeHalf)
			{
				// make sure all is done
				reverb_double(	setup, result, scratch,
								bufferSignal, filter, done, blockCount, NO);
			
			
				// do fft on the input
				DSPDoubleSplitComplex sc_i = { input.doubleData, input.doubleData + kBlockSizeHalf };
				DSPDoubleSplitComplex sc_s = { bufferSignal[0].doubleData, bufferSignal[0].doubleData + kBlockSizeHalf };
				vDSP_fft_zropD(setup, &sc_i, 1, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Forward);
				
				// scale input ffft
				double scale = 0.5;
				vDSP_vsmulD(bufferSignal[0].doubleData, 1, &scale, bufferSignal[0].doubleData, 1, kBlockSize);
			
				// do the head
				DSPDoubleSplitComplex sc_o = { output.doubleData, output.doubleData + kBlockSizeHalf };
				convolve_double(bufferSignal[0].doubleData, filter[0].doubleData, output.doubleData);
				vDSP_fft_zripD(setup, &sc_o, 1, kBlockSizeBase2, kFFTDirection_Inverse);
				
				// do tail
				double *op1 = output.doubleData + kBlockSizeQuarter;
				double *op2 = output.doubleData + (kBlockSizeHalf + kBlockSizeQuarter);

				double *rp1 = result.doubleData + kBlockSizeQuarter;
				double *rp2 = result.doubleData + (kBlockSizeHalf + kBlockSizeQuarter);
					
				vDSP_vaddD(rp1, 1, op1, 1, op1, 1, kBlockSizeQuarter);
				vDSP_vaddD(rp2, 1, op2, 1, op2, 1, kBlockSizeQuarter);
				
				// clear result
				memset(rp1, 0, kBlockSizeQuarter * sizeof(double));
				memset(rp2, 0, kBlockSizeQuarter * sizeof(double));

				rotateBuffers(obj->mSignalBuffers, blockCount);

				// scale result
				scale = 1. / kBlockSize;
				vDSP_vsmulD(op1, 1, &scale, op1, 1, kBlockSizeQuarter);
				vDSP_vsmulD(op2, 1, &scale, op2, 1, kBlockSizeQuarter);

				// shift input
				copySignal_double(obj->mInputBuffer);
				pos = 0; done = 1;
			}
		}
		
		int shouldBeDone = (pos  * blockCount) / kBlockSizeHalf;
		if (shouldBeDone > blockCount) shouldBeDone = blockCount;
		if (shouldBeDone > done)
		{
			reverb_double(	setup, result, scratch,
							bufferSignal, filter, done, shouldBeDone, NO);
			done = shouldBeDone;
		}	
	}
	
	obj->mBlockPos = pos;
	obj->mBlockDone = done;
}



//
//
// Conversion utilities
//
//

static inline void float2double(float *f, double *d)
{
	int i;
	for (i = kBlockSize - 1; i >= 0; i--) d[i] = f[i];
}

static inline void double2float(double *d, float *f)
{
	int i;
	for (i = 0; i < kBlockSize; i++) f[i] = d[i];
}

// ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ ------ 

@implementation SBConvolvingReverb

//
//
// Meta data
//
//

+ (SBElementCategory) category
{
	return kMisc;
}

+ (NSString*) name
{
	return @"Convolving reverb";
}

- (NSString*) name
{
	return @"conv revrb";
}

- (NSString*) informations
{
	unsigned long long maxMem;
	
	maxMem = (kBlockMaxCount*2 + kMaxWorkers*2 + 2); // signal + filters, results and scratchs, input and output
	maxMem *= (kBlockSize * sizeof(double));
	
	float maxMemInMb = maxMem / (1024.f * 1024.f);
	
	return	[NSString stringWithFormat:
				@"Convolving reverb, %i samples latency. "
				@"Max reverb length: %i samples. " 
				@"Memory usage at max reverb length: %.1f MBs", 
				kBlockSizeHalf, kBlockMaxCount * kBlockSizeHalf, maxMemInMb];
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx == 1) return kAudioBuffer;
	else return kNormal;
}

//
//
// Element init/dealloc
//
//

- (id) init
{
	LOG("init\n")

	self = [super init];
	if (self != nil)
	{
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"ir"];

		[mOutputNames addObject:@"out"];
		
		#warning "threading stuff"
		mNumberOfWorkers = 0;
//		mNumberOfWorkers = 1; // gNumberOfCPUs;
//		fprintf(stderr, "mNumberOfWorkers: %i\n", mNumberOfWorkers);
		
		if (mNumberOfWorkers > 0) pCalcFunc = privateCalcFunc;
		else pCalcFunc = privateCalcFuncNoWorkers;
		
		#define ALLOCATE(x) \
			x.ptr = malloc(kBlockSize * sizeof(double)); \
			if (!x.ptr) { [self release]; return nil; }
		
		ALLOCATE(mInputBuffer)
		ALLOCATE(mOutputBuffer)

		int i;
		for (i = 0; i < mNumberOfWorkers; i++)
		{
			ALLOCATE(mResultBuffer[i])
			ALLOCATE(mScratchBuffer[i])
			
			mWorkerLock[i] = [[NSConditionLock alloc] initWithCondition:WORKER_DONE];
			if (!mWorkerLock[i]) { [self release]; return nil; }
		}
		
		if (mNumberOfWorkers == 0)
		{
			ALLOCATE(mResultBuffer[0])
			ALLOCATE(mScratchBuffer[0])
		}
		
		#undef ALLOCATE
		
		mFFTSetupD = sb_vDSP_create_fftsetupD(kBlockSizeBase2, kFFTRadix2);
		mFFTSetup = sb_vDSP_create_fftsetup(kBlockSizeBase2, kFFTRadix2);
		
		if (!mFFTSetup || !mFFTSetupD)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	LOG("dealloc\n")

	if (mStarted) [self destroyThreads];

	if (mFFTSetupD) sb_vDSP_destroy_fftsetupD(mFFTSetupD);
	if (mFFTSetup) sb_vDSP_destroy_fftsetup(mFFTSetup);
	
	if (mInputBuffer.ptr) free(mInputBuffer.ptr);
	if (mOutputBuffer.ptr) free(mOutputBuffer.ptr);
	
	int i;
	for (i = 0; i < kMaxWorkers; i++)
	{
		if (mResultBuffer[i].ptr) free(mResultBuffer[i].ptr);
		if (mScratchBuffer[i].ptr) free(mScratchBuffer[i].ptr);
		
		if (mWorkerLock[i]) [mWorkerLock[i] release];
	}

	[self freeBuffers];
	[super dealloc];
}

//
//
// Buffer management
//
//

- (void) allocBuffers:(int)count
{
	int i;
	for (i = 0; i < count; i++)
	{
		mSignalBuffers[i].ptr = malloc(kBlockSize * sizeof(double));
		mFilterBuffers[i].ptr = malloc(kBlockSize * sizeof(double));
		if (!mSignalBuffers[i].ptr || !mFilterBuffers[i].ptr) count = i;
	}
		
	mBlockCount = count;
}

- (void) clearBuffers
{
	if (mBlockCount <= 0) return;
	
	int i;
	for (i = 0; i < mBlockCount; i++)
		memset(mSignalBuffers[i].ptr, 0, kBlockSize * sizeof(double));

	memset(mInputBuffer.ptr, 0, kBlockSize * sizeof(double));
	memset(mOutputBuffer.ptr, 0, kBlockSize * sizeof(double));
}

- (void) freeBuffers
{
	int i;
	for (i = 0; i < kBlockMaxCount; i++)
	{
		if (mSignalBuffers[i].ptr) free(mSignalBuffers[i].ptr);
		if (mFilterBuffers[i].ptr) free(mFilterBuffers[i].ptr);
		mSignalBuffers[i].ptr = nil;
		mFilterBuffers[i].ptr = nil;
	}

	mBlockCount = 0;
}

//
//
// Worker management
//
//

- (void) startThreads
{
	LOG("beg startThreads: workers %i block count %i\n", mNumberOfWorkers, mBlockCount)

	mStop = NO;
	
	pthread_attr_t attr;
	pthread_attr_init(&attr);
	pthread_attr_setdetachstate(&attr, PTHREAD_CREATE_JOINABLE);
  
	int i;
	for (i = 0; i < mNumberOfWorkers; i++)
	{
		mWorkerData[i].obj = self;
		mWorkerData[i].index = i;
	
		LOG("creating working %i\n", i)
	
		pthread_create(mWorkerThread + i, &attr, worker_thread, mWorkerData + i);
	}
	
	pthread_attr_destroy(&attr);
	mStarted = YES;
	
	LOG("end startThreads\n")
}

- (void) destroyThreads
{
	LOG("beg destroyThreads\n")

	mStop = YES;

	int i;
	for (i = 0; i < mNumberOfWorkers; i++)
	{
		[mWorkerLock[i] lockWhenCondition:WORKER_DONE];
		[mWorkerLock[i] unlockWithCondition:START_WORKER];
		pthread_join(mWorkerThread[i], nil);
	}
	
	LOG("end destroyThreads\n")
}

- (void) distributeLoad
{
	int offset = 1;
	int steps = mBlockCount / mNumberOfWorkers;
	
	int i;
	for (i = 0; i < mNumberOfWorkers; i++)
	{
		mWorkerData[i].blockStart = offset;
		
		offset += steps; 
		
		// don't go over max
		if (offset > mBlockCount) offset = mBlockCount;
		
		// for last worker, make sure to process to the end 
		if (i == (mNumberOfWorkers - 1)) offset = mBlockCount;
		
		mWorkerData[i].blockEnd = offset;
		
		LOG("set working load %i, min %i, max %i\n",
				i, mWorkerData[i].blockStart, mWorkerData[i].blockEnd)
	}
}

//
//
// Signal update
//
//

- (void) updateFiltersForBuffer:(float*)buf count:(int)count
{
	LOG("beg updateFiltersForBuffer\n")
	
	int i;
	for (i = 0; i <	mNumberOfWorkers; i++)
		[mWorkerLock[i] lockWhenCondition:WORKER_DONE];
		
	[self freeBuffers];
	
	if (!buf || count <= 0) goto bailOut;
	
	int blockCount = (count + kBlockSizeHalf - 1) / kBlockSizeHalf;
	if (blockCount > kBlockMaxCount) blockCount = kBlockMaxCount;
	else if (blockCount <= 0) goto bailOut;
	
	[self allocBuffers:blockCount];
	[self clearBuffers];
	
	for (i = 0; i < mBlockCount; i++)
		memset(mFilterBuffers[i].ptr, 0, kBlockSize * sizeof(double));

	// spread the data into the filter buffers
	// write in first part of blocks (0 1 2 3)
	int curBlock = 0, curSample = 0;
	if (mPrecision == kFloatPrecision)
	{
		while(count > 0 && curBlock < blockCount)
		{
			int off = (curSample & 1) ? (kBlockSizeHalf) : 0;
			int bas = curSample >> 1;
			float *dst = mFilterBuffers[curBlock].floatData + bas + off;
			*dst = *buf++;
			
			curSample++;
			if (curSample >= kBlockSizeHalf)
			{
				curSample = 0;
				curBlock++;
			}
			
			count--;
		}
		
		// do fft on all filter blocks
		for (i = 0; i < mBlockCount; i++)
		{
			DSPSplitComplex sc_s = { mFilterBuffers[i].floatData, mFilterBuffers[i].floatData + kBlockSizeHalf };
			vDSP_fft_zrip(mFFTSetup, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Forward);
			
			// scale ffft
			float scale = 0.5f;
			vDSP_vsmul(mFilterBuffers[i].floatData, 1, &scale, mFilterBuffers[i].floatData, 1, kBlockSize);
		}
	}
	else if (mPrecision == kDoublePrecision)
	{
		while(count > 0 && curBlock < blockCount)
		{
			int off = (curSample & 1) ? (kBlockSizeHalf) : 0;
			int bas = curSample >> 1;
			double *dst = mFilterBuffers[curBlock].doubleData + bas + off;
			*dst = *buf++;
			
			curSample++;
			if (curSample >= kBlockSizeHalf)
			{
				curSample = 0;
				curBlock++;
			}
			
			count--;
		}
		
		// do fft on all filter blocks
		for (i = 0; i < mBlockCount; i++)
		{
			DSPDoubleSplitComplex sc_s = { mFilterBuffers[i].doubleData, mFilterBuffers[i].doubleData + kBlockSizeHalf };
			vDSP_fft_zripD(mFFTSetupD, &sc_s, 1, kBlockSizeBase2, kFFTDirection_Forward);
			
			// scale ffft
			double scale = 0.5;
			vDSP_vsmulD(mFilterBuffers[i].doubleData, 1, &scale, mFilterBuffers[i].doubleData, 1, kBlockSize);
		}
	}
	
	if (mNumberOfWorkers > 0)
		[self distributeLoad];
	
bailOut:
	
	for (i = 0; i <	mNumberOfWorkers; i++)
		[mWorkerLock[i] unlockWithCondition:WORKER_DONE];
	
	if (mBlockCount > 0 && mNumberOfWorkers > 0 && !mStarted)
		[self startThreads];
	
	LOG("end updateFiltersForBuffer\n")
}

//
//
// Precision conversion
//
//

- (void) changePrecision:(SBPrecision)precision
{
	if (mPrecision == precision) return;
	
	int i;
	for (i = 0; i <	mNumberOfWorkers; i++)
		[mWorkerLock[i] lockWhenCondition:WORKER_DONE];
	LOG("changePrecision acquired locks\n")
	
	if (mBlockCount > 0)
	{
		int i;
		if (mPrecision == kFloatPrecision)
		{
			for (i = 0; i < mBlockCount; i++)
			{
				float2double(mFilterBuffers[i].ptr, mFilterBuffers[i].ptr);
				float2double(mSignalBuffers[i].ptr, mSignalBuffers[i].ptr);
			}
			
			for (i = 0; i <	mNumberOfWorkers; i++)
				float2double(mResultBuffer[i].ptr, mResultBuffer[i].ptr);
				
			float2double(mInputBuffer.ptr, mInputBuffer.ptr);
			float2double(mOutputBuffer.ptr, mOutputBuffer.ptr);
		}
		else
		{
			for (i = 0; i < mBlockCount; i++)
			{
				double2float(mFilterBuffers[i].ptr, mFilterBuffers[i].ptr);
				double2float(mSignalBuffers[i].ptr, mSignalBuffers[i].ptr);
			}
			
			for (i = 0; i <	mNumberOfWorkers; i++)
				double2float(mResultBuffer[i].ptr, mResultBuffer[i].ptr);
				
			double2float(mInputBuffer.ptr, mInputBuffer.ptr);
			double2float(mOutputBuffer.ptr, mOutputBuffer.ptr);
		}
	}
	
	[super changePrecision:precision];
	
	LOG("changePrecision released locks\n")
	for (i = 0; i <	mNumberOfWorkers; i++)
		[mWorkerLock[i] unlockWithCondition:WORKER_DONE];

}

//
//
// State reset
//
//

- (void) reset
{
	mBlockPos = 0;
	mBlockDone = 1;
	
	LOG("reset acquiring locks\n")
	
	int i;
	for (i = 0; i <	mNumberOfWorkers; i++)
		[mWorkerLock[i] lockWhenCondition:WORKER_DONE];
	
	[self clearBuffers];
	
	for (i = 0; i <	mNumberOfWorkers; i++)
	{
		memset(mResultBuffer[i].ptr, 0, kBlockSize * sizeof(double));
		[mWorkerLock[i] unlockWithCondition:WORKER_DONE];
	}
	
	if (mNumberOfWorkers == 0)
	{
		memset(mResultBuffer[0].ptr, 0, kBlockSize * sizeof(double));
	}
	
	LOG("reset released locks\n")
	
	[super reset];
}

@end
