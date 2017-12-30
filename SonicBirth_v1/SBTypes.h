/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#ifndef SBTYPES_H
#define SBTYPES_H

typedef unsigned long long SBTimeStamp;

typedef struct
{
	int size;
	int offset;
} SBFFTSyncData;

typedef struct
{
	SBTimeStamp time;
	float *data;
	int count;
} SBAudioBuffer;

#define kMaxNumberOfPoints (200)
typedef struct
{
	int type; // 0 step, 1 linear, 2 spline
	int count;
	double x[kMaxNumberOfPoints];
	double y[kMaxNumberOfPoints];
	char move[kMaxNumberOfPoints]; // 0 yes, 1 y only, 2 no
	
	// spline cached stuff
	double y2[kMaxNumberOfPoints];
	double hi[kMaxNumberOfPoints];
	double h2[kMaxNumberOfPoints];
} SBPointsBuffer;

typedef enum
{
	kCircuitID = 70000,
	kLockID,
	kUnlockID,
	kResyncID
} SBPropertyID;

typedef enum
{
	kFloatPrecision = 1,
	kDoublePrecision
} SBPrecision;

typedef union
{
	void *ptr;
	float *floatData;
	double *doubleData;
	SBPointsBuffer *pointsData;
	SBAudioBuffer *audioData;
	SBFFTSyncData *fftSyncData;
} SBBuffer;

typedef enum
{
	kNoInterpolation = 0,
	kInterpolationLinear,
} SBInterpolation;

typedef enum
{
	kCircuitDesign = 0,
	kGuiDesign,
	kRuntime
} SBGuiMode;

typedef void (*SBCalculateFuncPtr)(void *inObj, int count, int offset);

#define kMaxChannels (256)
#define kMinFeedbackTime (0.01)
#define kSamplesPerCycle (4096)

#define kFillBufferSize (1024)
#define kFillBufferSignatureSize (64)
#define kFillBufferXORKeySize (128)
#define kFillBufferIdentifierSize (kFillBufferSize - kFillBufferSignatureSize - kFillBufferXORKeySize)

typedef struct
{
	char identifier[kFillBufferIdentifierSize];
	unsigned char signature[kFillBufferSignatureSize];
	unsigned char xorKey[kFillBufferXORKeySize];
} SBPassedData;

// copied from AudioUnitProperties.h
typedef enum
{
	kParameterUnit_Generic				= 0,	/* untyped value generally between 0.0 and 1.0 */
	kParameterUnit_Indexed				= 1,	/* takes an integer value (good for menu selections) */
	kParameterUnit_Boolean				= 2,	/* 0.0 means FALSE, non-zero means TRUE */
	kParameterUnit_Percent				= 3,	/* usually from 0 -> 100, sometimes -50 -> +50 */
	kParameterUnit_Seconds				= 4,	/* absolute or relative time */
	kParameterUnit_SampleFrames			= 5,	/* one sample frame equals (1.0/sampleRate) seconds */
	kParameterUnit_Phase				= 6,	/* -180 to 180 degrees */
	kParameterUnit_Rate					= 7,	/* rate multiplier, for playback speed, etc. (e.g. 2.0 == twice as fast) */
	kParameterUnit_Hertz				= 8,	/* absolute frequency/pitch in cycles/second */
	kParameterUnit_Cents				= 9,	/* unit of relative pitch */
	kParameterUnit_RelativeSemiTones	= 10,	/* useful for coarse detuning */
	kParameterUnit_MIDINoteNumber		= 11,	/* absolute pitch as defined in the MIDI spec (exact freq may depend on tuning table) */
	kParameterUnit_MIDIController		= 12,	/* a generic MIDI controller value from 0 -> 127 */
	kParameterUnit_Decibels				= 13,	/* logarithmic relative gain */
	kParameterUnit_LinearGain			= 14,	/* linear relative gain */
	kParameterUnit_Degrees				= 15,	/* -180 to 180 degrees, similar to phase but more general (good for 3D coord system) */
	kParameterUnit_EqualPowerCrossfade	= 16,	/* 0 -> 100, crossfade mix two sources according to sqrt(x) and sqrt(1.0 - x) */
	kParameterUnit_MixerFaderCurve1		= 17,	/* 0.0 -> 1.0, pow(x, 3.0) -> linear gain to simulate a reasonable mixer channel fader response */
	kParameterUnit_Pan					= 18,	/* standard left to right mixer pan */
	kParameterUnit_Meters				= 19,	/* distance measured in meters */
	kParameterUnit_AbsoluteCents		= 20,	/* absolute frequency measurement : if f is freq in hertz then 	*/
                                                        /* absoluteCents = 1200 * log2(f / 440) + 6900					*/
	kParameterUnit_Octaves				= 21,	/* octaves in relative pitch where a value of 1 is equal to 1200 cents*/
	kParameterUnit_BPM					= 22,	/* beats per minute, ie tempo */
    kParameterUnit_Beats				= 23,	/* time relative to tempo, ie. 1.0 at 120 BPM would equal 1/2 a second */
	kParameterUnit_Milliseconds			= 24,	/* parameter is expressed in milliseconds */
	kParameterUnit_Ratio				= 25	/* for compression, expansion ratio, etc. */
} SBParameterType;

#endif /* SBTYPES_H */
