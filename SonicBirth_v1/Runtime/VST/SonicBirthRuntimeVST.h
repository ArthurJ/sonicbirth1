/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef SONICBIRTHRUNTIMEVST_H
#define SONICBIRTHRUNTIMEVST_H

//#include "vstplugsmacho.h"

class SBVST;
@class SBListenerObjc;

#import "FrameworkVersion.h"
#import "SBListener.h"

#include <map>
#include <vector>
#include <pthread.h>

//#include "audioeffectx.h"
#include "public.sdk/source/vst/vstaudioeffect.h"
#include "public.sdk/source/vst/vsteditcontroller.h"
#include "public.sdk/source/main/pluginfactoryvst3.h"
#include "pluginterfaces/vst/ivstparameterchanges.h"
#include "public.sdk/source/vst/vst2wrapper/vst2wrapper.h"
#include "pluginterfaces/base/futils.h"

class SBRuntimeViewVST;
@class SBRootCircuit;
@class SBArgument;


class SBVST : public AudioEffectX //, public SBListenerCpp
{
public:
	SBVST (audioMasterCallback audioMaster, SBPassedData* passedData);
	virtual ~SBVST ();

	// Processes
	virtual void process (float **inputs, float **outputs, VstInt32 sampleFrames);
	virtual void processReplacing (float **inputs, float **outputs, VstInt32 sampleFrames);

	// Program
	virtual void setProgram(VstInt32 program);
	virtual void getProgramName (char *dstName);

	// Parameters
	virtual void setParameter (VstInt32 index, float value);
	virtual float getParameter (VstInt32 index);
	virtual void getParameterLabel (VstInt32 index, char *label);
	virtual void getParameterDisplay (VstInt32 index, char *text);
	virtual void getParameterName (VstInt32 index, char *text);

	virtual bool getEffectName (char* name);
	virtual bool getVendorString (char* text);
	virtual bool getProductString (char* text);
	virtual VstInt32 getVendorVersion () { return kCurrentVersion; }
	
	virtual VstInt32 canDo (char* text);
	virtual VstInt32 processEvents (VstEvents* events);
	
	virtual VstPlugCategory getPlugCategory ()
	{ return mIsSynth ? kPlugCategSynth : kPlugCategEffect; }
	
	virtual void setSampleRate (float inSampleRate);
	virtual void resume();
	
	// sonicbirth specific stuff
	virtual SBRootCircuit*		mainCircuit() { return mCircuits[0]; }
	virtual SBRootCircuit*		createCircuit();
	virtual void				maintainCircuits();
	
	virtual void setParameterAutomated (VstInt32 index, float value);
	virtual void parameterUpdated(SBArgument *a, int i);
	
	virtual VstInt32 getChunk (void** data, bool isPreset = false);
	virtual VstInt32 setChunk (void* data, VstInt32 byteSize, bool isPreset = false);
	
	virtual bool getSpeakerArrangement(VstSpeakerArrangement** pluginInput, VstSpeakerArrangement** pluginOutput);
	virtual bool setSpeakerArrangement(VstSpeakerArrangement* pluginInput, VstSpeakerArrangement* pluginOutput);

protected:
	//char programName[24];
	int mNumPresets;
	NSData					*mUserPreset;
	NSData					*mDefaultPreset;


	BOOL						mSingleCircuit;
	std::vector<SBRootCircuit*>	mCircuits;
	
	//unsigned int			mUniqueID;
	SBListenerObjc			*mListener;
	
	int						mChannelInputs;
	int						mChannelOutputs;
	
	SBBuffer				mBuffers[kMaxChannels];
	int						mBuffersCount;
	int						mCalculatingOffset;
	int						mSampleRate;
	int						mMinFeedbackTime;
	bool					mHasFeedback;
	double					mLatency, mLatencySamples;
	double					mTailTime;
	pthread_mutex_t			*mMutex;

	int						mNumParameters;
	std::vector<int>		mArgumentMap;
	std::vector<int>		mSubArgumentMap;
	std::map<SBArgument*, int>	mArgumentReverseMap;
	
	bool					mUsesMidi, mIsSynth, mHasGui;
	bool					mHasSideChain;
	bool					mNeedsTempo;
	
	SBPassedData			*mPassedData;
	
	NSData					*mChunk;
	
	VstSpeakerArrangement*	mPlugInput;
	VstSpeakerArrangement*	mPlugOutput;
};

#endif /* SONICBIRTHRUNTIMEVST_H */

