
#import "SBFreeverb.h"
#import "SBFormant.h"
#import "SBGranulate.h"
#import "SBEquation.h"
#import "SBConstant.h"

// ----------------------------------------------------------------------------
void SBFreeverbPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers);
void SBFreeverbPrivateCalcFunc(void *inObj, int count, int offset)
{
	SBFreeverb *obj = inObj;
	if (count <= 0) return;
	
	SBFreeverbPrivateCalcFuncImpl(count, offset,
									obj->mModel, obj->mPrecision,
									obj->pInputBuffers,
									obj->mAudioBuffers);
}

// ----------------------------------------------------------------------------
void SBFormantPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers);
void SBFormantPrivateCalcFunc(void *inObj, int count, int offset)
{
	SBFormant *obj = inObj;
	
	if (count <= 0) return;
	
	SBFormantPrivateCalcFuncImpl(count, offset,
									obj->mImp, obj->mPrecision,
									obj->pInputBuffers,
									obj->mAudioBuffers);
}

// ----------------------------------------------------------------------------
void SBGranulatePrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers);
void SBGranulatePrivateCalcFunc(void *inObj, int count, int offset)
{
	SBGranulate *obj = inObj;
	
	if (count <= 0) return;
	
	SBGranulatePrivateCalcFuncImpl(count, offset,
									obj->mImp, obj->mPrecision,
									obj->pInputBuffers,
									obj->mAudioBuffers);
}

// ----------------------------------------------------------------------------
void SBGranulatePicthPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers);
void SBGranulatePicthPrivateCalcFunc(void *inObj, int count, int offset)
{
	SBGranulatePicth *obj = inObj;
	
	if (count <= 0) return;
	
	SBGranulatePicthPrivateCalcFuncImpl(count, offset,
									obj->mImp, obj->mPrecision,
									obj->pInputBuffers,
									obj->mAudioBuffers);
}

// ----------------------------------------------------------------------------
void SBEquationPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers,
									SBBuffer *mBuffers,
									BOOL *mUpdateBuffer,
									int mSampleCount);
void SBEquationPrivateCalcFunc(void *inObj, int count, int offset)
{
	SBEquation *obj = inObj;
	
	if (count <= 0) return;
	
	SBEquationPrivateCalcFuncImpl(count, offset,
									obj->mEquationState, obj->mPrecision,
									obj->pInputBuffers,
									obj->mAudioBuffers,
									obj->mBuffers,
									&obj->mUpdateBuffer,
									obj->mSampleCount);
}

// ----------------------------------------------------------------------------
void SBConstantPrivateCalcFuncImpl(int count, int offset,
									SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers,
									BOOL *mUpdateBuffer,
									int mSampleCount,
									double mValue);
void SBConstantPrivateCalcFunc(void *inObj, int count, int offset)
{
	SBConstant *obj = inObj;
	
	if (count <= 0) return;
	
	SBConstantPrivateCalcFuncImpl(count, offset,
									obj->mPrecision,
									obj->pInputBuffers,
									obj->mAudioBuffers,
									&obj->mUpdateBuffer,
									obj->mSampleCount,
									obj->mValue);
}

