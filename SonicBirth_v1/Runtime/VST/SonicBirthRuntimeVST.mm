/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include "SonicBirthRuntimeVST.h"
#include "SBRuntimeViewVST.h"

#import "SBRootCircuit.h"
#import "SBArgument.h"
#import "SBSlider.h"
#import "SBBoolean.h"
#import "SBIndexed.h"

#import "SBElementServer.h"

#ifdef LOG
#undef LOG
#endif

//#define DO_LOG_STUFF 
#ifndef DO_LOG_STUFF
	#define LOG(args...) do { } while(0)
#else
	#define LOG(args...) do { fprintf(stderr, "SonicBirth: " args); fflush(stderr); } while(0)
	#warning "vst logging enabled."
#endif

static void mstrcpy(char *dst, const char *src, int len)
{
	len--;
	int i = 0;
	while(*src && i++ < len)
		*dst++ = *src++;
	*dst = 0;
}

static int maxChars(double val)
{
	int max = 0;
	if (val < 0.) max = 1;

	val = sabs(val);
	if (val < 9.) return max + 1;
	else return max + (int)(ceil(log(val)/log(10.)));
}

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------



//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
SBVST::SBVST (audioMasterCallback audioMaster, SBPassedData* passedData)
	: AudioEffectX (audioMaster, 1, 1)	// 1 program, 1 parameter only
{
	LOG("Object create\n");
	mPassedData = passedData;
	
	mPlugInput = nil;
	mPlugOutput = nil;
	
	//frameworkInit(1); // called in main_macho entry point

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// set up server
	if (!gElementServer)
	{
		// make sure cocoa is loaded
		//NSApplicationLoad(); // done in framework init
		
		// check for version
		if (getSonicBirthFrameworkVersion() != kCurrentVersion)
		{
			NSRunAlertPanel(@"SonicBirth",
				@"The framework version does not match the plugin version. "
				@"Please update the framework and reexport the plugin.",
				nil, nil, nil);
			throw(-1);
		}
		
		// allocate buffer
		[[SBElementServer alloc] init];
	}

	mSampleRate = 0;

	// create initial circuit
	SBRootCircuit *c = createCircuit();
	mCircuits.push_back(c);

	// cache some info
	mChannelInputs = [c numberOfRealInputs];
	mChannelOutputs = [c numberOfOutputs];
	
	mHasFeedback = [c hasFeedback];
	mLatency = [c latencyMs];
	mLatencySamples = [c latencySamples];
	mTailTime = [c tailTime];
	mSingleCircuit = ((mChannelInputs != 1) || (mChannelOutputs != 1));
	if (!mSingleCircuit)
	{
		mChannelInputs = 2;
		mChannelOutputs = 2;
	}
	
	mHasSideChain = [c hasSideChain];
	mNeedsTempo = [c needsTempo];

	mBuffersCount = 0;
	mMutex = &(c->pMutex);
	
	// make the argument maps
	LOG("Argument map:\n");
	int numArguments = [c numberOfArguments];
	for (int i = 0; i < numArguments; i++)
	{
		SBArgument *a = [c argumentAtIndex:i];
		int params = [a numberOfParameters];
		if (params > 0) mArgumentReverseMap[a] = mSubArgumentMap.size();
		for (int j = 0; j < params; j++)
		{
			LOG("%i: %s %i\n", (int)mSubArgumentMap.size(), [[a name] cString], j);
			mArgumentMap.push_back(i);
			mSubArgumentMap.push_back(j);
		}
	}
	
	mNumParameters = mSubArgumentMap.size();
	mUsesMidi = [c hasMidiArguments];
	mIsSynth = mUsesMidi && (mChannelInputs == 0);
	mHasGui = [c hasCustomGui];
	
	unsigned int uniqueID;
	memcpy(&uniqueID, [c subType], 4);
	setUniqueID(uniqueID);

	// override the real number of params - see AudioEffect.cpp constructor
	this->numParams   = mNumParameters;
	cEffect.numParams = mNumParameters;
	
	// override the real number of presets - see AudioEffect.cpp constructor
	mNumPresets = [c numberOfPresets];	
	this->numPrograms   = 2 + mNumPresets;
	cEffect.numPrograms = 2 + mNumPresets;
	
	//#warning "sidechain notify ?"
	int declaredInput = (mHasSideChain) ? (mChannelInputs*2) : (mChannelInputs);
	
	setNumInputs(declaredInput);
	setNumOutputs(mChannelOutputs);
	
	VstInt32 inputType;
	switch(declaredInput)
	{
		/*case 0: inputType = kSpeakerArrEmpty; break;
		case 1: inputType = kSpeakerArrMono; break;
		case 2: inputType = kSpeakerArrStereo; break;
		case 3: inputType = kSpeakerArr30Cine; break;
		case 4: inputType = kSpeakerArr31Cine; break;
		case 5: inputType = kSpeakerArr50; break;
		case 6: inputType = kSpeakerArr60Cine; break;
		case 7: inputType = kSpeakerArr70Cine; break;
		case 8: inputType = kSpeakerArr80Cine; break;
		case 9: inputType = kSpeakerArr81Cine; break;
		case 12: inputType = kSpeakerArr102; break;*/
		default: inputType = kSpeakerArrUserDefined; break;
	}
	allocateArrangement (&mPlugInput, declaredInput);
	mPlugInput->type = inputType;
	
	VstInt32 outputType;
	switch(mChannelOutputs)
	{
		/*case 0: outputType = kSpeakerArrEmpty; break;
		case 1: outputType = kSpeakerArrMono; break;
		case 2: outputType = kSpeakerArrStereo; break;
		case 3: outputType = kSpeakerArr30Cine; break;
		case 4: outputType = kSpeakerArr31Cine; break;
		case 5: outputType = kSpeakerArr50; break;
		case 6: outputType = kSpeakerArr60Cine; break;
		case 7: outputType = kSpeakerArr70Cine; break;
		case 8: outputType = kSpeakerArr80Cine; break;
		case 9: outputType = kSpeakerArr81Cine; break;
		case 12: outputType = kSpeakerArr102; break;*/
		default: outputType = kSpeakerArrUserDefined; break;
	}
	allocateArrangement (&mPlugOutput, mChannelOutputs);
	mPlugOutput->type = outputType;
	
	
	if (mHasGui)
	{
		//AEffEditor *ed = new SBVSTView(this);
		//if (ed) setEditor(ed);
		//LOG("alloc editor: %p\n", ed);
	}
	LOG("editor: %p\n", editor);
	
	if (mIsSynth) isSynth();
	
	// makes sense to feed both inputs with the same signal
	#warning fixme
//	if (mChannelInputs == 2 && mChannelOutputs == 2) canMono();
										
	canProcessReplacing();
	programsAreChunks(true);
	
	// prepare listener
	mListener = [[SBListenerObjc alloc] init];
	if (!mListener) throw(-1);
	
	[mListener setVSTObject:this];
	[mListener registerEventsFromCircuit:c];
	
	mChunk = NULL;
	
	mDefaultPreset = [c currentState];
	mUserPreset = [c currentState];
	if (mDefaultPreset) [mDefaultPreset retain];
	if (mUserPreset) [mUserPreset retain];
	
	if (pool) [pool release];
}

//-------------------------------------------------------------------------------------------------------
SBVST::~SBVST ()
{
	LOG("Object Destroy\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while(mCircuits.size())
	{
		[mCircuits.back() release];
		mCircuits.pop_back();
	}
	
	for (int i = 0; i < mBuffersCount; i++)
		free(mBuffers[i].ptr);
		
	if (mListener) [mListener release];
	
	if (mChunk) [mChunk release];
	if (mDefaultPreset) [mDefaultPreset release];
	if (mUserPreset) [mUserPreset release];
	
	[pool release];
}


//------------------------------------------------------------------------
bool SBVST::getSpeakerArrangement(VstSpeakerArrangement** pluginInput, VstSpeakerArrangement** pluginOutput)
{
	LOG("getSpeakerArrangement\n");

	*pluginInput  = mPlugInput;
	*pluginOutput = mPlugOutput;
	return true;
}

//------------------------------------------------------------------------
bool SBVST::setSpeakerArrangement(VstSpeakerArrangement* pluginInput, VstSpeakerArrangement* pluginOutput)
{
	LOG("setSpeakerArrangement\n");

	if (!pluginOutput || !pluginInput)
		return false;

	bool result = true;
	int declaredInput = (mHasSideChain) ? (mChannelInputs*2) : (mChannelInputs);
	
	// inputs
	if (pluginInput->numChannels != declaredInput)
	{
		result = false;
		VstInt32 inputType;
		switch(declaredInput)
		{
			/*case 0: inputType = kSpeakerArrEmpty; break;
			case 1: inputType = kSpeakerArrMono; break;
			case 2: inputType = kSpeakerArrStereo; break;
			case 3: inputType = kSpeakerArr30Cine; break;
			case 4: inputType = kSpeakerArr31Cine; break;
			case 5: inputType = kSpeakerArr50; break;
			case 6: inputType = kSpeakerArr60Cine; break;
			case 7: inputType = kSpeakerArr70Cine; break;
			case 8: inputType = kSpeakerArr80Cine; break;
			case 9: inputType = kSpeakerArr81Cine; break;
			case 12: inputType = kSpeakerArr102; break;*/
			default: inputType = kSpeakerArrUserDefined; break;
		}
		allocateArrangement (&mPlugInput, declaredInput);
		mPlugInput->type = inputType;
	}
	else
	{
		matchArrangement (&mPlugInput, pluginInput);
	}
	
	// outputs
	if (pluginOutput->numChannels != mChannelOutputs)
	{
		result = false;
		VstInt32 outputType;
		switch(mChannelOutputs)
		{
			/*case 0: outputType = kSpeakerArrEmpty; break;
			case 1: outputType = kSpeakerArrMono; break;
			case 2: outputType = kSpeakerArrStereo; break;
			case 3: outputType = kSpeakerArr30Cine; break;
			case 4: outputType = kSpeakerArr31Cine; break;
			case 5: outputType = kSpeakerArr50; break;
			case 6: outputType = kSpeakerArr60Cine; break;
			case 7: outputType = kSpeakerArr70Cine; break;
			case 8: outputType = kSpeakerArr80Cine; break;
			case 9: outputType = kSpeakerArr81Cine; break;
			case 12: outputType = kSpeakerArr102; break;*/
			default: outputType = kSpeakerArrUserDefined; break;
		}
		allocateArrangement (&mPlugOutput, mChannelOutputs);
		mPlugOutput->type = outputType;
	}
	else
	{
		matchArrangement (&mPlugOutput, pluginOutput);
	}

	return result;
}

//------------------------------------------------------------------------------------------
void SBVST::setSampleRate(float sampleRate)
{
	LOG("setSampleRate\n");

	this->sampleRate = sampleRate;
	
	setInitialDelay((int)(mLatency*sampleRate/1000.f + mLatencySamples)); // in samples!
	
	//fprintf(stderr, "sr %f latency %f latencySamples %f\n", sampleRate, mLatency, mLatencySamples);
	ioChanged();
}

//------------------------------------------------------------------------------------------
SBRootCircuit* SBVST::createCircuit()
{
	LOG("Circuit create\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *identifier = [NSString stringWithUTF8String:mPassedData->identifier];
	NSBundle *bundle = [NSBundle bundleWithIdentifier:identifier];
	NSString *resPath = [bundle resourcePath];
	NSString *circuitPath = [resPath stringByAppendingPathComponent:@"model.sbc"];
	
	LOG("path: %s\n", [circuitPath cString]);
	
	NSData *data = [NSData dataWithContentsOfFile:circuitPath];
	if (data)
	{
		NSMutableData *mdata = [NSMutableData dataWithData:data];
		unsigned char *mb = (unsigned char *)[mdata mutableBytes];
		int l = [mdata length];
		for (int i = 0; i < l; i++)
			*mb++ ^= mPassedData->xorKey[i % kFillBufferXORKeySize];
		data = mdata;

		NSString *error = nil;
		NSDictionary *d = [NSPropertyListSerialization
								propertyListFromData:data
								mutabilityOption:NSPropertyListImmutable
								format:nil
								errorDescription:&error];
		if (d && !error)
		{
			SBRootCircuit *c = [[SBRootCircuit alloc] init];
			if (c)
			{
				if ([c loadData:d])
				{
					[c trimDebug];
					[pool release];
					return c;
				}
				else [c release];
			}
		}
	}
	
	LOG("CreateCircuit failed!\n");

	[pool release];
	throw(-1);
	return nil;
}

//------------------------------------------------------------------------------------------
void SBVST::maintainCircuits()
{
	LOG("Maintain circuits\n");

	if (mSingleCircuit) return;
	
	unsigned int channels = mChannelInputs;
	if (channels < 1) channels = 1;
	
	LOG("\tchannels: %i\n", channels);
	
	while(mCircuits.size() > channels)
	{
		[mCircuits.back() release];
		mCircuits.pop_back();
	}
	
	while(mCircuits.size() < channels)
	{
		SBRootCircuit *c = createCircuit();
		mCircuits.push_back(c);
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[c shareArgumentsFrom:mCircuits[0] shareCount:channels]; // share? share!
		[pool release];
	}
	
	int c = mCircuits.size(), i;
	for (i = 0; i < c; i++)
		[mCircuits[i] setLastCircuit:(i == c - 1)];
}


//-------------------------------------------------------------------------------------------------------
// max 24 chars
void SBVST::setProgram(VstInt32 program)
{
	LOG("setProgram %i\n", program);
	if (curProgram == 0 && program == 0) return;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	if (curProgram == 0 && program != 0)
	{
		if (mUserPreset) [mUserPreset release];
		
		mUserPreset = [c currentState];
		if (mUserPreset) [mUserPreset retain];
	}

	curProgram = program;
	if (curProgram == 0)
	{
		if (mUserPreset) [c loadState:mUserPreset];
	}
	else if (curProgram == 1)
	{
		if (mDefaultPreset) [c loadState:mDefaultPreset];
	}
	else
	{
		[c setPreset:curProgram - 2];
	}
	
	[pool release];
}

//-----------------------------------------------------------------------------------------
// max 24 chars
void SBVST::getProgramName (char *dstName)
{
	LOG("getProgramName\n");
	if (curProgram == 0)
	{
		mstrcpy(dstName, "User", kVstMaxProgNameLen);
		return;
	}
	
	if (curProgram == 1)
	{
		mstrcpy(dstName, "Default", kVstMaxProgNameLen);
		return;
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
		
	mstrcpy(dstName, [[[c presetAtIndex:curProgram - 2] name] cString], kVstMaxProgNameLen);
		
	[pool release];
}

//-----------------------------------------------------------------------------------------
void SBVST::setParameter (VstInt32 index, float value)
{
	LOG("setParameter\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	int argIndex = mArgumentMap[index];
	int subArgIndex = mSubArgumentMap[index];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		[pool release];
		return;
	}
	
	float min = [a minValueForParameter:subArgIndex];
	float max = [a maxValueForParameter:subArgIndex];
	float dlt = max - min;
	
	[a takeValue:min + value * dlt offsetToChange:0 forParameter:subArgIndex];
	[c didChangeView];
	
	[pool release];
}

//-----------------------------------------------------------------------------------------
float SBVST::getParameter (VstInt32 index)
{
	LOG("getParameter %i\n", index);

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	int argIndex = mArgumentMap[index];
	int subArgIndex = mSubArgumentMap[index];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		[pool release];
		return 0;
	}
	
	float min = [a minValueForParameter:subArgIndex];
	float max = [a maxValueForParameter:subArgIndex];
	float cur = [a currentValueForParameter:subArgIndex];
	
	[pool release];

	return (cur-min)/(max-min);
}

//-----------------------------------------------------------------------------------------
// max 8 chars
void SBVST::getParameterName (VstInt32 index, char *label)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	
	LOG("getParameterName %i\n", index);

	int argIndex = mArgumentMap[index];
	int subArgIndex = mSubArgumentMap[index];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		LOG("getParameterName %i INVALID\n", index);
	
		[pool release];
		return;
	}
	
	// ok the standard says 8 chars
	// but nobody seems to care
	// lets hope every hosts support 32 chars
	//mstrcpy(label, [[a nameForParameter:subArgIndex] cString], kVstMaxParamStrLen);
	#warning "non standard lenght used"
	mstrcpy(label, [[a nameForParameter:subArgIndex] cString], 32);
	
	
	LOG("getParameterName %i name is %s\n", index, label);
	
	[pool release];
}

//-----------------------------------------------------------------------------------------
// max not documented, 8 ?
void SBVST::getParameterDisplay (VstInt32 index, char *text)
{
	LOG("getParameterDisplay %i\n", index);
// kVstMaxParamStrLen
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	int argIndex = mArgumentMap[index];
	int subArgIndex = mSubArgumentMap[index];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		[pool release];
		return;
	}
	
	SBParameterType type = [a typeForParameter:subArgIndex];
	float val = [a currentValueForParameter:subArgIndex];
	
	if (type == kParameterUnit_Indexed)
	{
		int i = (int)val;
		NSArray *names = [a indexedNamesForParameter:subArgIndex];
		if (names)
		{
			int c = [names count];
			if (i < 0) i = 0; else if (i >= c) i = c - 1;

			//mstrcpy(text, [[names objectAtIndex:i] cString], 8);
			mstrcpy(text, [[names objectAtIndex:i] cString], kVstMaxParamStrLen);
			[pool release];
			return;
		}
	}
	
	[pool release];
	
	if (type == kParameterUnit_Boolean)
	{
		int i = (int)val;
		if (i) mstrcpy(text, "On", 8);
		else mstrcpy(text, "Off", 8);
		return;
	}
	
	char string[256];
	int max = maxChars(val);
		 if (max <= 1) snprintf(string, 256, "%.7f", val);
	else if (max == 2) snprintf(string, 256, "%.6f", val);
	else if (max == 3) snprintf(string, 256, "%.5f", val);
	else if (max == 4) snprintf(string, 256, "%.4f", val);
	else if (max == 5) snprintf(string, 256, "%.3f", val);
	else if (max == 6) snprintf(string, 256, "%.2f", val);
	else if (max == 7) snprintf(string, 256, "%d", (int)(val + 0.5f));
	else if (max == 8) snprintf(string, 256, "%d", (int)(val + 0.5f));
	else snprintf(string, 256, "%.0e", val);
	mstrcpy(text, string, 8);
}

//-----------------------------------------------------------------------------------------
// max 8 chars
void SBVST::getParameterLabel(VstInt32 index, char *label)
{
	LOG("getParameterLabel %i\n", index);

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	int argIndex = mArgumentMap[index];
	int subArgIndex = mSubArgumentMap[index];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		[pool release];
		return;
	}
	
	SBParameterType type = [a typeForParameter:subArgIndex];
	[pool release];
	
	switch(type)
	{
		case kParameterUnit_Generic:			mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Indexed:			mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Boolean:			mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Percent:			mstrcpy(label, "%", kVstMaxParamStrLen);		break;
		case kParameterUnit_Seconds:			mstrcpy(label, "sec.", kVstMaxParamStrLen);		break;
		case kParameterUnit_SampleFrames:		mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Phase:				mstrcpy(label, "dgr.", kVstMaxParamStrLen);		break;
		case kParameterUnit_Rate:				mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Hertz:				mstrcpy(label, "Hz", kVstMaxParamStrLen);		break;
		case kParameterUnit_Cents:				mstrcpy(label, "Cnts", kVstMaxParamStrLen);		break;
		case kParameterUnit_RelativeSemiTones:	mstrcpy(label, "SmTn", kVstMaxParamStrLen);		break;
		case kParameterUnit_MIDINoteNumber:		mstrcpy(label, "MdNt", kVstMaxParamStrLen);		break;
		case kParameterUnit_MIDIController:		mstrcpy(label, "MdCt", kVstMaxParamStrLen);		break;
		case kParameterUnit_Decibels:			mstrcpy(label, "Db", kVstMaxParamStrLen);		break;
		case kParameterUnit_LinearGain:			mstrcpy(label, "LnGn", kVstMaxParamStrLen);		break;
		case kParameterUnit_Degrees:			mstrcpy(label, "dgr.", kVstMaxParamStrLen);		break;
		case kParameterUnit_EqualPowerCrossfade:mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_MixerFaderCurve1:	mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Pan:				mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Meters:				mstrcpy(label, "m", kVstMaxParamStrLen);		break;
		case kParameterUnit_AbsoluteCents:		mstrcpy(label, "", kVstMaxParamStrLen);			break;
		case kParameterUnit_Octaves:			mstrcpy(label, "oct.", kVstMaxParamStrLen);		break;
		case kParameterUnit_BPM:				mstrcpy(label, "bpm", kVstMaxParamStrLen);		break;
		case kParameterUnit_Beats:				mstrcpy(label, "beats", kVstMaxParamStrLen);	break;
		case kParameterUnit_Milliseconds:		mstrcpy(label, "ms", kVstMaxParamStrLen);		break;
		case kParameterUnit_Ratio:				mstrcpy(label, "", kVstMaxParamStrLen);			break;
		default: mstrcpy(label, "", kVstMaxParamStrLen); break;
	}
}

//------------------------------------------------------------------------
void SBVST::setParameterAutomated (VstInt32 index, float value)
{
	LOG("setParameterAutomated\n");

	if (audioMaster)
		audioMaster (&cEffect, audioMasterAutomate, index, 0, 0, value);	// value is in opt
}

//------------------------------------------------------------------------------------------
void SBVST::parameterUpdated(SBArgument *a, int i)
{
	int paramBase = mArgumentReverseMap[a];
	int param = paramBase + i;
	
	LOG("parameterUpdated event name: %s index: %i paramBase: %i paramID: %i \n",
		(a) ? [[a name] cString] : "nil", i, paramBase, param);
	
	//AUBase::SetParameter(param, kAudioUnitScope_Global, (AudioUnitElement)0, [a currentValueForParameter:i], 0);
	this->setParameterAutomated(param, this->getParameter(param));
}

//------------------------------------------------------------------------
// max 32 chars
bool SBVST::getEffectName (char* name)
{
	LOG("getEffectName\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	mstrcpy (name, [[c name] cString], kVstMaxEffectNameLen);
	[pool release];

	return true;
}

//------------------------------------------------------------------------
// max 64 chars
bool SBVST::getProductString (char* text)
{
	LOG("getProductString\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	mstrcpy (text, [[c name] cString], kVstMaxProductStrLen);
	[pool release];
	
	return true;
}

//------------------------------------------------------------------------
// max 64 chars
bool SBVST::getVendorString (char* text)
{
	LOG("getVendorString\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	mstrcpy (text, [[c company] cString], kVstMaxProductStrLen);
	[pool release];
	
	return true;
}

//-----------------------------------------------------------------------------------------
void SBVST::resume()
{
	LOG("resume\n");

	pthread_mutex_lock(mMutex);

	mSampleRate = (int)getSampleRate();
	
	mCalculatingOffset = 0;
	mMinFeedbackTime = (int)(mSampleRate * kMinFeedbackTime);
	
	maintainCircuits();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int c = mCircuits.size(), i;
	for (i = 0; i < c; i++)
		[mCircuits[i]	prepareForSamplingRate:mSampleRate
						sampleCount:kSamplesPerCycle
						precision:[mCircuits[0] precision]
						interpolation:[mCircuits[0] interpolation]];
				
	[pool release];
	
	// temps buffers
	for (i = 0; i < mBuffersCount; i++)
		free(mBuffers[i].ptr);

	if (mSingleCircuit) mBuffersCount = mChannelInputs;
	else mBuffersCount = c;
	
	LOG("resume mBuffersCount %i\n", mBuffersCount);
	
	if (mHasSideChain) mBuffersCount *= 2;
	if (mNeedsTempo) mBuffersCount += 2;
	
	for (i = 0; i < mBuffersCount; i++)
	{
		int size = kSamplesPerCycle * sizeof(double);
		mBuffers[i].ptr = malloc(size);
		if (!mBuffers[i].ptr) throw(-1);
		memset(mBuffers[i].ptr, 0, size);
	}
	
	pthread_mutex_unlock(mMutex);
	
	// since hosts aren't required to trigger Reset between Initializing and starting audio processing, 
	// it's a good idea to do it ourselves here
	//Reset(kAudioUnitScope_Global, (AudioUnitElement)0);
	// BUT since [circuit reset] is currently implied by [circuit prepare...]
	// it isn't needed
}

//-----------------------------------------------------------------------------------------
// accumulate
void SBVST::process (float **inBufs, float **outBufs, VstInt32 inFramesToProcess)
{
//	LOG("process\n");

	int done = 0;
	int inputs = (mHasSideChain) ? (mChannelInputs*2) : (mChannelInputs);
	int outputs = mChannelOutputs;
	int realOutputs = outputs;

	pthread_mutex_lock(mMutex);
	//LOG("Enter critial\n")
	
	SBPrecision precision = mCircuits[0]->pPrecision;
	
	int i, j, c = mCircuits.size();
	int frameToProcess = inFramesToProcess;

	// if inputs == 0 <==> mSingleCircuit == YES

	// init inputs
	// do tempo first
	int bufOffset = 0;
	if (mNeedsTempo)
	{
		VstTimeInfo* tinfo = getTimeInfo(kVstTempoValid | kVstBarsValid);
		double beat, tempo;
		if (!tinfo)
		{
			beat = 0;
			tempo = 0;
		}
		else
		{
			if (!(tinfo->flags & kVstTempoValid)) tempo = 0;
			else tempo = tinfo->tempo;
			
			if (!(tinfo->flags & kVstBarsValid)) beat = 0;
			else beat = tinfo->barStartPos;
		}
		
		//LOG("tempo: %f beat_start: %f beat_end: %f\n", tempo, beat, beat + (inFramesToProcess * tempo / (mSampleRate * 60)))
		
		if (precision == kFloatPrecision)
		{
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[0].floatData[i] = tempo;
				
			float scale = tempo / (mSampleRate * 60);
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[1].floatData[i] = beat + (i * scale);
		}
		else
		{
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[0].doubleData[i] = tempo;
				
			double scale = tempo / (mSampleRate * 60);
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[1].doubleData[i] = beat + (i * scale);
		}
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			circuit->pInputBuffers[0].ptr = mBuffers[0].ptr;
			circuit->pInputBuffers[1].ptr = mBuffers[1].ptr;
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[0].ptr = mBuffers[0].ptr;
				circuit->pInputBuffers[1].ptr = mBuffers[1].ptr;
			}
		}
		
		#ifdef DO_LOG_STUFF
		LOG("tempo %p\n", mBuffers[0].ptr);
		LOG("beat %p\n", mBuffers[1].ptr);
		#endif
		
		bufOffset = 2;
	}
	
	
	if (precision == kFloatPrecision)
	{
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			for (i = 0, j = bufOffset; i < inputs; i++, j++)
				circuit->pInputBuffers[j].floatData = inBufs[i];
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[bufOffset].floatData = inBufs[j];
				if (mHasSideChain) circuit->pInputBuffers[bufOffset+1].floatData = inBufs[j+c];
			}
		}
	}
	else
	{
		for (i = 0; i < inputs; i++)
			for(j = 0; j < frameToProcess; j++)
				mBuffers[bufOffset+i].doubleData[j] = inBufs[i][j];
				
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			for (i = 0, j = bufOffset; i < inputs; i++, j++)
				circuit->pInputBuffers[j].doubleData = mBuffers[j].doubleData;
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[bufOffset].doubleData = mBuffers[bufOffset+j].doubleData;
				if (mHasSideChain) circuit->pInputBuffers[bufOffset+1].doubleData = mBuffers[bufOffset+j+c].doubleData;
			}
		}
	}

	
	// process data
	inputs += bufOffset;
	while(frameToProcess > 0)
	{
		// wrap calculating offset
		if (mCalculatingOffset >= kSamplesPerCycle) mCalculatingOffset = 0;
		int offset = mCalculatingOffset;
	
		// how much should we do this iteration ?
		int todo = frameToProcess, place = kSamplesPerCycle - offset;
		if (todo > place) todo = place; 
		if (mHasFeedback && (todo > mMinFeedbackTime)) todo = mMinFeedbackTime;
		
		// process circuit
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			
			if (precision == kFloatPrecision)
			{
				// backward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].floatData -= offset;
					
				// calculate
				(circuit->pCalcFunc)(circuit, todo, offset);
				
				// forward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].floatData += offset + todo;
				
				// copy back data
				for (i = 0; i < outputs; i++)
				{
					float *src = circuit->pOutputBuffers[i].floatData + offset;
					float *dst = outBufs[i] + done;
					
					for(int h = 0; h < todo; h++) *dst++ += *src++; // accumulate
				}
				
				if (outputs == 1 && realOutputs > 1)
				{
					float *src = circuit->pOutputBuffers[i].floatData + offset;
								
					for (int i = 1; i < realOutputs; i++)
					{
						float *dst = outBufs[i] + done;
						for(int h = 0; h < todo; h++) *dst++ += *src++; // accumulate
					}
				}
			}
			else
			{
				// backward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].doubleData -= offset;
					
				// calculate
				(circuit->pCalcFunc)(circuit, todo, offset);
				
				// forward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].doubleData += offset + todo;
				
				// copy back data
				for (i = 0; i < outputs; i++)
				{
					double *src = circuit->pOutputBuffers[i].doubleData + offset;
					float *dst = outBufs[i] + done;
					
					for(int h = 0; h < todo; h++) *dst++ += *src++; // accumulate
				}
				
				
				if (outputs == 1 && realOutputs > 1)
				{
					double *src = circuit->pOutputBuffers[i].doubleData + offset;
								
					for (int i = 1; i < realOutputs; i++)
					{
						float *dst = outBufs[i] + done;
						for(int h = 0; h < todo; h++) *dst++ += *src++; // accumulate
					}
				}
			}
			
		}
		else
		{
			int max = 1 + ((mNeedsTempo) ? 2 : 0) + ((mHasSideChain) ? 1 : 0);
			if (precision == kFloatPrecision)
			{
				for (j = 0; j < c; j++)
				{
					SBRootCircuit *circuit = mCircuits[j];

					/*
					// backward inputs
					circuit->pInputBuffers[0].floatData -= offset;
					
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
				
					// forward inputs
					circuit->pInputBuffers[0].floatData += offset + todo;
					*/
					
					// backward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].floatData -= offset;
						
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
					
					// forward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].floatData += offset + todo;
					
					// copy back data
					float *src = circuit->pOutputBuffers[0].floatData + offset;
					float *dst = outBufs[j] + done;
						
					for(int h = 0; h < todo; h++) *dst++ += *src++; // accumulate
				}
			}
			else
			{
				for (j = 0; j < c; j++)
				{
					SBRootCircuit *circuit = mCircuits[j];
					
					/*
					// backward inputs
					circuit->pInputBuffers[0].doubleData -= offset;
					
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
				
					// forward inputs
					circuit->pInputBuffers[0].doubleData += offset + todo;
					*/
					
					// backward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].doubleData -= offset;
						
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
					
					// forward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].doubleData += offset + todo;
						
					// copy back data
					double *src = circuit->pOutputBuffers[0].doubleData + offset;
					float *dst = outBufs[j] + done;
					
					for(int h = 0; h < todo; h++) *dst++ += *src++; // accumulate
				}
			}
		}
		
		frameToProcess -= todo;
		mCalculatingOffset += todo;
		done += todo;
	}
	
	/*
	if (outputs == 1 && realOutputs > 1)
	{
		float *src = outBufs[0];
					
		for (int i = 1; i < realOutputs; i++)
		{
			float *dst = outBufs[i];
			memcpy(dst, src, inFramesToProcess * sizeof(float));
		}
	}
	*/
		
	//LOG("Exit critial\n")
	pthread_mutex_unlock(mMutex);
}

//-----------------------------------------------------------------------------------------
void SBVST::processReplacing (float **inBufs, float **outBufs, VstInt32 inFramesToProcess)
{
//	LOG("processReplacing\n");

	int done = 0;
	int inputs = mChannelInputs;
	int outputs = mChannelOutputs;
	int realOutputs = outputs;

	pthread_mutex_lock(mMutex);
	//LOG("Enter critial\n")
	
	SBPrecision precision = mCircuits[0]->pPrecision;
	
	int i, j, c = mCircuits.size();
	int frameToProcess = inFramesToProcess;

	// if inputs == 0 <==> mSingleCircuit == YES

	// init inputs
	// do tempo first
	int bufOffset = 0;
	if (mNeedsTempo)
	{
		VstTimeInfo* tinfo = getTimeInfo(kVstTempoValid | kVstBarsValid);
		double beat, tempo;
		if (!tinfo)
		{
			beat = 0;
			tempo = 0;
		}
		else
		{
			if (!(tinfo->flags & kVstTempoValid)) tempo = 0;
			else tempo = tinfo->tempo;
			
			if (!(tinfo->flags & kVstBarsValid)) beat = 0;
			else beat = tinfo->barStartPos;
		}
		
		//LOG("tempo: %f beat_start: %f beat_end: %f\n", tempo, beat, beat + (inFramesToProcess * tempo / (mSampleRate * 60)))
		
		if (precision == kFloatPrecision)
		{
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[0].floatData[i] = tempo;
				
			float scale = tempo / (mSampleRate * 60);
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[1].floatData[i] = beat + (i * scale);
		}
		else
		{
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[0].doubleData[i] = tempo;
				
			double scale = tempo / (mSampleRate * 60);
			for (i = 0; i < (int)inFramesToProcess; i++) mBuffers[1].doubleData[i] = beat + (i * scale);
		}
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			circuit->pInputBuffers[0].ptr = mBuffers[0].ptr;
			circuit->pInputBuffers[1].ptr = mBuffers[1].ptr;
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[0].ptr = mBuffers[0].ptr;
				circuit->pInputBuffers[1].ptr = mBuffers[1].ptr;
			}
		}
		
		#ifdef DO_LOG_STUFF
		LOG("tempo %p\n", mBuffers[0].ptr);
		LOG("beat %p\n", mBuffers[1].ptr);
		#endif
		
		bufOffset = 2;
	}
	
	
	if (precision == kFloatPrecision)
	{
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			for (i = 0, j = bufOffset; i < inputs; i++, j++)
				circuit->pInputBuffers[j].floatData = inBufs[i];
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[bufOffset].floatData = inBufs[j];
				if (mHasSideChain) circuit->pInputBuffers[bufOffset+1].floatData = inBufs[j+c];
			}
		}
	}
	else
	{
		for (i = 0; i < inputs; i++)
			for(j = 0; j < frameToProcess; j++)
				mBuffers[bufOffset+i].doubleData[j] = inBufs[i][j];
				
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			for (i = 0, j = bufOffset; i < inputs; i++, j++)
				circuit->pInputBuffers[j].doubleData = mBuffers[j].doubleData;
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[bufOffset].doubleData = mBuffers[bufOffset+j].doubleData;
				if (mHasSideChain) circuit->pInputBuffers[bufOffset+1].doubleData = mBuffers[bufOffset+j+c].doubleData;
			}
		}
	}
	
	// process data
	inputs += bufOffset;
	while(frameToProcess > 0)
	{
		// wrap calculating offset
		if (mCalculatingOffset >= kSamplesPerCycle) mCalculatingOffset = 0;
		int offset = mCalculatingOffset;
	
		// how much should we do this iteration ?
		int todo = frameToProcess, place = kSamplesPerCycle - offset;
		if (todo > place) todo = place; 
		if (mHasFeedback && (todo > mMinFeedbackTime)) todo = mMinFeedbackTime;
		
		// process circuit
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			
			if (precision == kFloatPrecision)
			{
				// backward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].floatData -= offset;
					
				// calculate
				(circuit->pCalcFunc)(circuit, todo, offset);
				
				// forward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].floatData += offset + todo;
				
				// copy back data
				for (i = 0; i < outputs; i++)
				{
					float *src = circuit->pOutputBuffers[i].floatData + offset;
					float *dst = outBufs[i] + done;
					
					memcpy(dst, src, todo * sizeof(float));
				}
			}
			else
			{
				// backward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].doubleData -= offset;
					
				// calculate
				(circuit->pCalcFunc)(circuit, todo, offset);
				
				// forward inputs
				for (i = 0; i < inputs; i++)
					circuit->pInputBuffers[i].doubleData += offset + todo;
				
				// copy back data
				for (i = 0; i < outputs; i++)
				{
					double *src = circuit->pOutputBuffers[i].doubleData + offset;
					float *dst = outBufs[i] + done;
					
					for(int h = 0; h < todo; h++) *dst++ = *src++;
				}
			}
			
		}
		else
		{
			int max = 1 + ((mNeedsTempo) ? 2 : 0) + ((mHasSideChain) ? 1 : 0);
			if (precision == kFloatPrecision)
			{
				for (j = 0; j < c; j++)
				{
					SBRootCircuit *circuit = mCircuits[j];

					/*
					// backward inputs
					circuit->pInputBuffers[0].floatData -= offset;
					
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
				
					// forward inputs
					circuit->pInputBuffers[0].floatData += offset + todo;
					*/
					
					// backward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].floatData -= offset;
						
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
					
					// forward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].floatData += offset + todo;
						
					// copy back data
					float *src = circuit->pOutputBuffers[0].floatData + offset;
					float *dst = outBufs[j] + done;
						
					memcpy(dst, src, todo * sizeof(float));
				}
			}
			else
			{
				for (j = 0; j < c; j++)
				{
					SBRootCircuit *circuit = mCircuits[j];

					/*
					// backward inputs
					circuit->pInputBuffers[0].doubleData -= offset;
					
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
				
					// forward inputs
					circuit->pInputBuffers[0].doubleData += offset + todo;
					*/
					
					// backward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].doubleData -= offset;
						
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
					
					// forward inputs
					for (i = 0; i < max; i++)
						circuit->pInputBuffers[i].doubleData += offset + todo;
						
					// copy back data
					double *src = circuit->pOutputBuffers[0].doubleData + offset;
					float *dst = outBufs[j] + done;
					
					for(int h = 0; h < todo; h++) *dst++ = *src++;
				}
			}
		}
		
		frameToProcess -= todo;
		mCalculatingOffset += todo;
		done += todo;
	}
	
	if (outputs == 1 && realOutputs > 1)
	{
		float *src = outBufs[0];
					
		for (int i = 1; i < realOutputs; i++)
		{
			float *dst = outBufs[i];
			memcpy(dst, src, inFramesToProcess * sizeof(float));
		}
	}
		
	//LOG("Exit critial\n")
	pthread_mutex_unlock(mMutex);
}

//-----------------------------------------------------------------------------------------
VstInt32 SBVST::canDo (char* text)
{
	LOG("canDo %s\n", (text) ? text : "null");

	if (!text) return -1;
	if (!mUsesMidi) return -1;

	if (!strcmp (text, "receiveVstEvents"))		return 1;
	if (!strcmp (text, "receiveVstMidiEvent"))  return 1;

	return -1;	// explicitly can't do; 0 => don't know
}

//-----------------------------------------------------------------------------------------
VstInt32 SBVST::processEvents (VstEvents* ev)
{
	LOG("processEvents\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	for (int i = 0; i < ev->numEvents; i++)
	{
		if ((ev->events[i])->type != kVstMidiType) continue;
		
		VstMidiEvent* event = (VstMidiEvent*)ev->events[i];
		unsigned char* midiData = (unsigned char*)event->midiData;
		int inStartFrame = event->deltaFrames;
		
	
		int inStatus = midiData[0] & 0xF0;
		int inChannel = midiData[0] & 0x0F;
		
		int inData1 = midiData[1];
		int inData2 = midiData[2];
		
		if (inStatus & 0x80)
		{
			LOG("status: %i channel: %i inData1: %i inData2: %i offset: %i\n",
				(int)inStatus, (int)inChannel, (int)inData1, (int)inData2, (int)inStartFrame);

			[c dispatchMidiEvent:inStatus channel:inChannel data1:inData1 data2:inData2 offsetToChange:inStartFrame];
		}
	}
	
	[pool release];
	
	return 1;	// want more
}

//-----------------------------------------------------------------------------------------
// returns lenght of data
VstInt32 SBVST::getChunk (void** data, bool isPreset)
{
	LOG("getChunk\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	
	if (mChunk) [mChunk release];
	mChunk = [c currentState];
	int length;
	if (mChunk)
	{
		[mChunk retain];
		*data = (void*)[mChunk bytes];
		length = [mChunk length];
	}
	else
	{
		*data = NULL;
		length = 0;
	}
	
	[pool release];
	return length;
}

//-----------------------------------------------------------------------------------------
// return 1 on success, 0 on failure
VstInt32 SBVST::setChunk (void* data, VstInt32 byteSize, bool isPreset)
{
	LOG("setChunk\n");

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	
	bool success = false;
	if (data && byteSize > 0)
	{
		NSData *dt = [NSData dataWithBytesNoCopy:data length:byteSize freeWhenDone:NO];
		if (dt)
		{
			[c loadState:dt];
			success = true;
		}
	}
	
	[pool release];
	return (success) ? 1 : 0;	
}

