/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include "SonicBirthRuntime.h"

#ifndef DO_COMPILE_CLASSES
#define DO_COMPILE_CLASSES

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
#define SUPER_CLASS_NAME AUEffectBase
#define CLASS_NAME SonicBirthRuntimeEffect
	#include "SonicBirthRuntime.mm"
#undef SUPER_CLASS_NAME
#undef CLASS_NAME

#define USES_MIDI

#define SUPER_CLASS_NAME AUMIDIEffectBase
#define CLASS_NAME SonicBirthRuntimeMidiEffect
	#include "SonicBirthRuntime.mm"
#undef SUPER_CLASS_NAME
#undef CLASS_NAME

#define MUSIC_DEVICE

#define SUPER_CLASS_NAME MusicDeviceBase
#define CLASS_NAME SonicBirthRuntimeMusicDevice
	#include "SonicBirthRuntime.mm"
#undef SUPER_CLASS_NAME
#undef CLASS_NAME

#undef USES_MIDI
#undef MUSIC_DEVICE
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

#else /* DO_COMPILE_CLASSES */

//------------------------------------------------------------------------------------------
CLASS_NAME::CLASS_NAME(AudioUnit component, SBPassedData *passedData)
#ifdef MUSIC_DEVICE
					: SUPER_CLASS_NAME(component, 0, 1, 0)
#else
					: SUPER_CLASS_NAME (component, true)
#endif
{
	LOG("Object create\n")
	mPassedData = passedData;

	frameworkInit(1);

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// set up server
	if (!gElementServer)
	{
		// make sure cocoa is loaded
		// NSApplicationLoad(); // done in framework init
		
		// check for version
		if (getSonicBirthFrameworkVersion() != kCurrentVersion)
		{
			NSRunAlertPanel(@"SonicBirth",
				@"The framework version does not match the plugin version. "
				@"Please update the framework and reexport the plugin.",
				nil, nil, nil);
			[pool release];
			COMPONENT_THROW(-1);
			return;
		}
		
		// allocate buffer
		[[SBElementServer alloc] init];
	}
	
	// check for plogue
	mHostIsPlogue = NO;
	NSBundle *mainBundle = [NSBundle mainBundle];
	if (mainBundle)
		mHostIsPlogue = [[mainBundle bundleIdentifier] isEqual:@"com.plogue.bidule"];

	// create initial circuit
	SBRootCircuit *c = CreateCircuit();
	mCircuits.push_back(c);

	// cache some info
	mChannelInfo.inChannels = [c numberOfRealInputs];
	mChannelInfo.outChannels = [c numberOfOutputs];
	
	LOG("\tmChannelInfo.inChannels: %i\n", mChannelInfo.inChannels)
	LOG("\tmChannelInfo.outChannels: %i\n", mChannelInfo.outChannels)
	
	mHasGui = [c hasCustomGui];
	LOG("\tmHasGui: %i\n", mHasGui)
	
#ifdef MUSIC_DEVICE
	mHasSideChain = false;
	
	// test:
	MusicDeviceBase::HandleNoteOn(-1, -1, -1, -1);
#else
	mHasSideChain = [c hasSideChain];

	if (mHasSideChain)
		//SetBusCount(kAudioUnitScope_Input, 2);
// For this to compile, AUBase.h must be modified. Just change mInitNumInputEls to protected.
		{ mInitNumInputEls = 2; }
#endif
	//SetMaxFramesPerSlice(4096);

	mNeedsTempo = [c needsTempo];
	mHasFeedback = [c hasFeedback];
	mLatency = [c latencyMs];
	mLatencySamples = [c latencySamples];
	mTailTime = [c tailTime];
	mSingleCircuit = ((mChannelInfo.inChannels != 1) || (mChannelInfo.outChannels != 1));
	if (!mSingleCircuit)
	{
		mChannelInfo.inChannels = -1;
		mChannelInfo.outChannels = -1;
	}
	
	// doesn't work in plogue
	if (mChannelInfo.inChannels == 0 && mChannelInfo.outChannels == 1 && !mHostIsPlogue)
		mChannelInfo.outChannels = -1;

	mSilence = NULL;
	mBuffersCount = 0;
	mMutex = &(c->pMutex);
	
	mDefaultPreset = [c currentState];
	if (mDefaultPreset) [mDefaultPreset retain];
	
	// initialize the presets
	mPresetsCount = [c numberOfPresets] + 1;
	mPresets = (AUPreset*) malloc(mPresetsCount * sizeof(AUPreset));
	if (!mPresets) COMPONENT_THROW(-1);
	
	mPresets[0].presetNumber = 0;
	mPresets[0].presetName = (CFStringRef)@"Default";
	for (int i = 1; i < mPresetsCount; i++)
	{
		mPresets[i].presetNumber = i;
		mPresets[i].presetName = (CFStringRef)[[c presetAtIndex:i - 1] name];
	}

	// make the argument maps
	LOG("Argument map:\n")
	int numArguments = [c numberOfArguments];
	for (int i = 0; i < numArguments; i++)
	{
		SBArgument *a = [c argumentAtIndex:i];
		int params = [a numberOfParameters];
		if (params > 0) mArgumentReverseMap[a] = mSubArgumentMap.size();
		for (int j = 0; j < params; j++)
		{
			LOG("%i: %s %i\n", mSubArgumentMap.size(), [[a name] cString], j)
			mArgumentMap.push_back(i);
			mSubArgumentMap.push_back(j);
		}
		
	}
	
	mNumParameters = mSubArgumentMap.size();
	
	// initialize the parameters to their default values
	for (int i = 0; i < mNumParameters; i++)
	{
		AudioUnitParameterInfo paramInfo;
		if (GetParameterInfo(kAudioUnitScope_Global, i, paramInfo) == noErr)
			Globals()->SetParameter(i, paramInfo.defaultValue);
	}
	
	// prepare listener
	mListener = [[SBListenerObjc alloc] init];
	if (!mListener) COMPONENT_THROW(-1);
	
	[mListener setObject:this];
	[mListener registerEventsFromCircuit:c];

	if (pool) [pool release];
}

//------------------------------------------------------------------------------------------
void CLASS_NAME::PostConstructor()
{
	LOG("PostConstructor\n")

	SUPER_CLASS_NAME::PostConstructor();

#ifndef MUSIC_DEVICE
	if (mChannelInfo.inChannels != mChannelInfo.outChannels)
		SetProcessesInPlace(false);
#endif

	if ( Inputs().GetNumberOfElements() > 0 )
	{
		const CAStreamBasicDescription curInStreamFormat = GetStreamFormat(kAudioUnitScope_Input, (AudioUnitElement)0);
	
		if ( ((UInt32)(mChannelInfo.inChannels) != curInStreamFormat.mChannelsPerFrame) && (mChannelInfo.inChannels >= 0) )
		{
			CAStreamBasicDescription newStreamFormat(curInStreamFormat);
			newStreamFormat.mChannelsPerFrame = (UInt32) (mChannelInfo.inChannels);
			AUBase::ChangeStreamFormat(kAudioUnitScope_Input, (AudioUnitElement)0, curInStreamFormat, newStreamFormat);
					
			LOG("\tChanged input to %i\n", mChannelInfo.inChannels)
		}
	}
	
	const CAStreamBasicDescription curOutStreamFormat = GetStreamFormat(kAudioUnitScope_Output, (AudioUnitElement)0);

	if ( ((UInt32)(mChannelInfo.outChannels) != curOutStreamFormat.mChannelsPerFrame) && (mChannelInfo.outChannels >= 0) )
	{
		CAStreamBasicDescription newStreamFormat = CAStreamBasicDescription(curOutStreamFormat);
		newStreamFormat.mChannelsPerFrame = (UInt32) (mChannelInfo.outChannels);
		AUBase::ChangeStreamFormat(kAudioUnitScope_Output, (AudioUnitElement)0, curOutStreamFormat, newStreamFormat);
			
		LOG("\tChanged output to %i\n", mChannelInfo.outChannels)
	}
}

//------------------------------------------------------------------------------------------
#ifdef MUSIC_DEVICE
bool CLASS_NAME::ValidFormat(AudioUnitScope inScope,
								AudioUnitElement inElement,
								const CAStreamBasicDescription &inNewFormat)
{
	LOG("ValidFormat %i\n", inNewFormat.mChannelsPerFrame)
	if (!AUBase::ValidFormat(inScope, inElement, inNewFormat)) return false;
	if (mChannelInfo.outChannels != -1 && (int)inNewFormat.mChannelsPerFrame != mChannelInfo.outChannels)
			return false;
	LOG("\tyes\n")
	return true;
}
#endif

//------------------------------------------------------------------------------------------
CLASS_NAME::~CLASS_NAME()
{
	LOG("Object Destroy\n")

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	while(mCircuits.size())
	{
		[mCircuits.back() release];
		mCircuits.pop_back();
	}
	
	for (int i = 0; i < mBuffersCount; i++)
		free(mBuffers[i].ptr);
		
	if (mSilence) free(mSilence);
	if (mPresets) free(mPresets);
	if (mListener) [mListener release];
	if (mDefaultPreset) [mDefaultPreset release];
	
	[pool release];
}

//------------------------------------------------------------------------------------------
void CLASS_NAME::beginGesture(SBArgument *a, int i)
{
	int paramBase = mArgumentReverseMap[a];
	int param = paramBase + i;
	
	LOG("beginGesture event name: %s index: %i paramBase: %i paramID: %i \n",
		(a) ? [[a name] cString] : "nil", i, paramBase, param)
		
	AudioUnitEvent myEvent;
	myEvent.mArgument.mParameter.mAudioUnit = GetComponentInstance();
    myEvent.mArgument.mParameter.mParameterID = param;
    myEvent.mArgument.mParameter.mScope = kAudioUnitScope_Global;
    myEvent.mArgument.mParameter.mElement = 0;
	myEvent.mEventType = kAudioUnitEvent_BeginParameterChangeGesture;
	AUEventListenerNotify(NULL, NULL, &myEvent);
}

//------------------------------------------------------------------------------------------
void CLASS_NAME::endGesture(SBArgument *a, int i)
{
	int paramBase = mArgumentReverseMap[a];
	int param = paramBase + i;
	
	LOG("endGesture event name: %s index: %i paramBase: %i paramID: %i \n",
		(a) ? [[a name] cString] : "nil", i, paramBase, param)
		
	AudioUnitEvent myEvent;
	myEvent.mArgument.mParameter.mAudioUnit = GetComponentInstance();
    myEvent.mArgument.mParameter.mParameterID = param;
    myEvent.mArgument.mParameter.mScope = kAudioUnitScope_Global;
    myEvent.mArgument.mParameter.mElement = 0;
	myEvent.mEventType = kAudioUnitEvent_EndParameterChangeGesture;
	AUEventListenerNotify(NULL, NULL, &myEvent);
}

//------------------------------------------------------------------------------------------
void CLASS_NAME::parameterUpdated(SBArgument *a, int i)
{
	int paramBase = mArgumentReverseMap[a];
	int param = paramBase + i;
	
	LOG("parameterUpdated event name: %s index: %i paramBase: %i paramID: %i \n",
		(a) ? [[a name] cString] : "nil", i, paramBase, param)
	
	AUBase::SetParameter(param, kAudioUnitScope_Global, (AudioUnitElement)0, [a currentValueForParameter:i], 0);

	AudioUnitEvent myEvent;
    myEvent.mEventType = kAudioUnitEvent_ParameterValueChange;
    myEvent.mArgument.mParameter.mAudioUnit = GetComponentInstance();
    myEvent.mArgument.mParameter.mParameterID = param;
    myEvent.mArgument.mParameter.mScope = kAudioUnitScope_Global;
    myEvent.mArgument.mParameter.mElement = 0;
	AUEventListenerNotify(NULL, NULL, &myEvent);
}

//------------------------------------------------------------------------------------------
SBRootCircuit* CLASS_NAME::CreateCircuit()
{
	LOG("Circuit create\n")

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSString *identifier = [NSString stringWithUTF8String:mPassedData->identifier];
	NSBundle *bundle = [NSBundle bundleWithIdentifier:identifier];
	NSString *resPath = [bundle resourcePath];
	NSString *circuitPath = [resPath stringByAppendingPathComponent:@"model.sbc"];
	
	LOG("path: %s\n", [circuitPath cString])
	
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
	
	LOG("CreateCircuit failed!\n")

	[pool release];
	COMPONENT_THROW(-1);
	return nil;
}

//------------------------------------------------------------------------------------------
void CLASS_NAME::MaintainCircuits()
{
	LOG("Maintain circuits\n")

	if (mSingleCircuit) return;
	
	unsigned int channels = (unsigned int)GetOutput(0)->GetStreamFormat().mChannelsPerFrame;
	if (channels < 1) channels = 1;
	
	LOG("\tchannels: %i\n", channels)
	
	while(mCircuits.size() > channels)
	{
		[mCircuits.back() release];
		mCircuits.pop_back();
	}
	
	while(mCircuits.size() < channels)
	{
		SBRootCircuit *c = CreateCircuit();
		mCircuits.push_back(c);
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
			[c shareArgumentsFrom:mCircuits[0] shareCount:channels]; // share? share!
		[pool release];
	}
	
	int c = mCircuits.size(), i;
	for (i = 0; i < c; i++)
		[mCircuits[i] setLastCircuit:(i == c - 1)];
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::Reset(AudioUnitScope inScope, AudioUnitElement inElement)
{
	LOG("Reset\n")
	
	pthread_mutex_lock(mMutex);
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int c = mCircuits.size(), i;
	for (i = 0; i < c; i++)
		[mCircuits[i] reset];

	[pool release];
	
	pthread_mutex_unlock(mMutex);
	
	return noErr;
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::GetPropertyInfo(AudioUnitPropertyID inID,
													AudioUnitScope inScope,
													AudioUnitElement inElement,
													UInt32 &outDataSize,
													Boolean	&outWritable )
{
	LOG("GetPropertyInfo\n")
	if (inScope == kAudioUnitScope_Global)
	{
		switch (inID)
		{
			case kAudioUnitProperty_ParameterStringFromValue:
				outWritable = false;
				outDataSize = sizeof (AudioUnitParameterStringFromValue);
				return noErr;
            
			case kAudioUnitProperty_ParameterValueFromString:
				outWritable = false;
				outDataSize = sizeof (AudioUnitParameterValueFromString);
				return noErr;
				
			 case kAudioUnitProperty_IconLocation:
                outWritable = false;
                outDataSize = sizeof (CFURLRef);
                return noErr;
				
			case kAudioUnitProperty_CocoaUI:
			if (mHasGui)
			{
				LOG("GetPropertyInfo: kAudioUnitProperty_CocoaUI <- noErr\n")
			
				outWritable = false;
				outDataSize = sizeof (AudioUnitCocoaViewInfo);
				
				return noErr;
			}
			else
				break;
				
			case kCircuitID:
				outWritable = false;
				outDataSize = sizeof (SBRootCircuit*);
				return noErr;
				
			case kLockID:
			case kUnlockID:
			case kResyncID:
				outWritable = false;
				outDataSize = 4;
				return noErr;
		}
	}
	return SUPER_CLASS_NAME::GetPropertyInfo (inID, inScope, inElement, outDataSize, outWritable);
}

//------------------------------------------------------------------------------------------
#define kMinInf (-120.)
ComponentResult CLASS_NAME::GetProperty(AudioUnitPropertyID inID,
												AudioUnitScope inScope,
												AudioUnitElement inElement,
												void *outData)
{
	LOG("GetProperty\n")
	if (inScope == kAudioUnitScope_Global)
	{
		switch (inID)
		{            
			case kAudioUnitProperty_ParameterValueFromString:
			{
                OSStatus retVal = kAudioUnitErr_InvalidPropertyValue;
				AudioUnitParameterValueFromString &name = *(AudioUnitParameterValueFromString*)outData;
				
				int argIndex = mArgumentMap[name.inParamID];
				if (argIndex < 0)
					return kAudioUnitErr_InvalidParameter;
					
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				SBRootCircuit *c = mCircuits[0];
				SBArgument *a = [c argumentAtIndex:argIndex];
				if (!a) COMPONENT_THROW(-1);
				if (![a isKindOfClass:[SBSlider class]])
				{
					[pool release];
					return kAudioUnitErr_InvalidParameter;
				}
				
				SBParameterType type = [(SBSlider*)a type];
				[pool release];
					
				if (type != kParameterUnit_Decibels)
					return kAudioUnitErr_InvalidParameter;
					
				if (name.inString == NULL)
                    return kAudioUnitErr_InvalidPropertyValue;
                
                UniChar chars[2];
                chars[0] = '-';
                chars[1] = 0x221e; // this is the unicode symbol for infinity
                CFStringRef comparisonString = CFStringCreateWithCharacters (NULL, chars, 2);
                
                if ( CFStringCompare(comparisonString, name.inString, 0) == kCFCompareEqualTo )
				{
                    name.outValue = kMinInf;
                    retVal = noErr;
                }
                
                if (comparisonString) CFRelease(comparisonString);
                
				return retVal;
			}
			
			case kAudioUnitProperty_ParameterStringFromValue:
			{
				AudioUnitParameterStringFromValue &name = *(AudioUnitParameterStringFromValue*)outData;
				
				int argIndex = mArgumentMap[name.inParamID];
				if (argIndex < 0)
					return kAudioUnitErr_InvalidParameter;
					
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
				SBRootCircuit *c = mCircuits[0];
				SBArgument *a = [c argumentAtIndex:argIndex];
				if (!a) COMPONENT_THROW(-1);
				if (![a isKindOfClass:[SBSlider class]])
				{
					[pool release];
					return kAudioUnitErr_InvalidParameter;
				}
				
				SBParameterType type = [(SBSlider*)a type];
				[pool release];
					
				if (type != kParameterUnit_Decibels)
					return kAudioUnitErr_InvalidParameter;
				
				Float32 paramValue = (name.inValue == NULL
										? Globals()->GetParameter (name.inParamID)
										: *(name.inValue));
										
				// for this usage only values <= -120 dB (the min value) have
				// a special name "-infinity"
				if (paramValue <= kMinInf)
				{
					UniChar chars[2];
					chars[0] = '-';
					chars[1] = 0x221e; // this is the unicode symbol for infinity
					name.outString = CFStringCreateWithCharacters (NULL, chars, 2);
				}
				else
					name.outString = NULL;

				return noErr;
			}
			
			case kAudioUnitProperty_IconLocation:
            {			
				NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					NSString *identifier = [NSString stringWithUTF8String:mPassedData->identifier];
					CFBundleRef bundle = CFBundleGetBundleWithIdentifier((CFStringRef)identifier);
				[pool release];
				
				if (bundle == NULL) return fnfErr;
                                
				CFURLRef bundleURL = CFBundleCopyResourceURL( bundle, 
                    CFSTR("plugin"), 
                    CFSTR("icns"), 
                    NULL);
                if (bundleURL == NULL) return fnfErr;
                
                (*(CFURLRef *)outData) = bundleURL;

                return noErr;
            }
			
			case kAudioUnitProperty_CocoaUI:
			if (mHasGui)
			{
				LOG("GetProperty: kAudioUnitProperty_CocoaUI\n")
			
				// Look for a resource in the main bundle by name and type.
				CFBundleRef bundle = CFBundleGetBundleWithIdentifier( CFSTR("com.sonicbirth.framework") );
				if (bundle == NULL) return fnfErr;
                
				CFURLRef bundleURL = CFBundleCopyBundleURL( bundle );
                if (bundleURL == NULL) return fnfErr;
				
				CFStringRef className = CFStringCreateCopy(NULL, CFSTR("SBRuntimeViewFactory"));
				AudioUnitCocoaViewInfo cocoaInfo = { bundleURL, { className } };
				*((AudioUnitCocoaViewInfo *)outData) = cocoaInfo;
				
				NSLog(@"sonicbirth bundleURL: %@ class: %@", bundleURL, className);
				
				LOG("\treturns noErr\n")
				return noErr;
			}
			else
				break;
			
			case kCircuitID:
				(*(SBRootCircuit**)outData) = mCircuits[0];
				return noErr;
			
			case kLockID:
				guiLock();
				return noErr;
				
			case kUnlockID:
				guiUnlock();
				return noErr;
				
			case kResyncID:
				guiResync();
				return noErr;
		}
	}
	return SUPER_CLASS_NAME::GetProperty (inID, inScope, inElement, outData);
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::GetParameterValueStrings(AudioUnitScope inScope,
															AudioUnitParameterID inParameterID,
															CFArrayRef *outStrings)
{
	LOG("GetParameterValueStrings\n")
	if (inScope != kAudioUnitScope_Global)
		return kAudioUnitErr_InvalidScope;
		
	int argIndex = mArgumentMap[inParameterID];
		
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a) COMPONENT_THROW(-1);
	
	NSArray *names = [a indexedNamesForParameter:mSubArgumentMap[inParameterID]];
	if (names)
	{
		if (outStrings)
			*outStrings = (CFArrayRef) [names retain];
		
		[pool release];
		return noErr;
	}
	
	[pool release];

	return kAudioUnitErr_InvalidProperty;
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::GetParameterInfo(AudioUnitScope inScope,
													AudioUnitParameterID inParameterID,
													AudioUnitParameterInfo & outParameterInfo)
{
	LOG("GetParameterInfo\n")

	if (inScope != kAudioUnitScope_Global)
		return kAudioUnitErr_InvalidScope;
		
	if ((int)inParameterID < 0 || (int)inParameterID >= mNumParameters)
		return kAudioUnitErr_InvalidParameter;
		
	ComponentResult result = noErr;

	outParameterInfo.clumpID = 0;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	SBRootCircuit *c = mCircuits[0];

	int argIndex = mArgumentMap[inParameterID];

	int subArgIndex = mSubArgumentMap[inParameterID];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		COMPONENT_THROW(-1);
	}
	
	outParameterInfo.flags = kAudioUnitParameterFlag_IsHighResolution;
	if ([a readFlagForParameter:subArgIndex]) outParameterInfo.flags |= kAudioUnitParameterFlag_IsReadable;
	if ([a writeFlagForParameter:subArgIndex]) outParameterInfo.flags |= kAudioUnitParameterFlag_IsWritable;
	
	AUBase::FillInParameterName(outParameterInfo, (CFStringRef)[[a nameForParameter:subArgIndex] retain], true);

	if (![a realtimeForParameter:subArgIndex])
		outParameterInfo.flags |= kAudioUnitParameterFlag_NonRealTime;
	
	if ([a logarithmicForParameter:subArgIndex])
		outParameterInfo.flags |= kAudioUnitParameterFlag_DisplayLogarithmic;

	outParameterInfo.unit = [a typeForParameter:subArgIndex];
	outParameterInfo.minValue = [a minValueForParameter:subArgIndex];
	outParameterInfo.maxValue = [a maxValueForParameter:subArgIndex];
	outParameterInfo.defaultValue = [a currentValueForParameter:subArgIndex];
		
	if (outParameterInfo.unit == kAudioUnitParameterUnit_Decibels && outParameterInfo.minValue <= kMinInf)
		outParameterInfo.flags |= kAudioUnitParameterFlag_ValuesHaveStrings;

	[pool release];
	
	return result;
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::SetParameter(AudioUnitParameterID inID,
												AudioUnitScope inScope,
												AudioUnitElement inElement,
												Float32 inValue,
												UInt32 inBufferOffsetInFrames)
{
	LOG("SetParameter id: %i value: %f offset: %i\n", inID, inValue, inBufferOffsetInFrames)
	
	ComponentResult result = AUBase::SetParameter(inID, inScope, inElement, inValue, inBufferOffsetInFrames);
	if ((result != noErr) || (inScope != kAudioUnitScope_Global)) return result;
	
	if ((int)inID < 0 || (int)inID >= mNumParameters)
		return kAudioUnitErr_InvalidParameter;
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int argIndex = mArgumentMap[inID];
	int subArgIndex = mSubArgumentMap[inID];
	
	// if share arguments:
	SBRootCircuit *c = mCircuits[0];
	SBArgument *a = [c argumentAtIndex:argIndex];
	if (!a)
	{
		COMPONENT_THROW(-1);
	}
	
	[a takeValue:inValue offsetToChange:inBufferOffsetInFrames forParameter:subArgIndex];
	[c didChangeView];
	
	/*
	// if don't share arguments:
	int c = mCircuits.size(), i;
	for (i = 0; i < c; i++)
	{
		SBArgument *a = [mCircuits[i] argumentAtIndex:argIndex];
		if (!a)
		{
			COMPONENT_THROW(-1);
		}
		
		[a takeValue:inValue offsetToChange:inBufferOffsetInFrames forParameter:subArgIndex];
	}
	*/

	[pool release];

	return noErr;
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::GetPresets (CFArrayRef * outData) const
{
	if (mPresetsCount == 0) return SUPER_CLASS_NAME::GetPresets(outData);

	if (outData == NULL) return noErr;
	
	CFMutableArrayRef ma = CFArrayCreateMutable (NULL, mPresetsCount, NULL);
	
	for (int i = 0; i < mPresetsCount; i++)
		CFArrayAppendValue (ma, mPresets+i);

	*outData = (CFArrayRef)ma;
	return noErr;
}

//------------------------------------------------------------------------------------------
OSStatus CLASS_NAME::NewFactoryPresetSet (const AUPreset & inNewFactoryPreset)
{
	if (mPresetsCount == 0) return SUPER_CLASS_NAME::NewFactoryPresetSet(inNewFactoryPreset);

	LOG("NewFactoryPresetSet\n")

	SInt32 chosenPreset = inNewFactoryPreset.presetNumber;
	if (chosenPreset < 0 || chosenPreset>= mPresetsCount)
		return kAudioUnitErr_InvalidPropertyValue;
	
	SBRootCircuit *c = mCircuits[0];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		//pthread_mutex_lock(mMutex);
		if (chosenPreset == 0)
		{
			if (mDefaultPreset) [c loadState:mDefaultPreset];
		}
		else
		{
			[c setPreset:chosenPreset - 1];
		}
		//pthread_mutex_unlock(mMutex);
	[pool release];
	
	SetAFactoryPresetAsCurrent (mPresets[chosenPreset]);
	for (int i = 0; i < mNumParameters; i++)
	{
		SBArgument *a = [c argumentAtIndex:mArgumentMap[i]];
		AUBase::SetParameter(i, kAudioUnitScope_Global, (AudioUnitElement)0, [a currentValueForParameter:mSubArgumentMap[i]], 0);
		
		AudioUnitEvent myEvent;
		myEvent.mEventType = kAudioUnitEvent_ParameterValueChange;
		myEvent.mArgument.mParameter.mAudioUnit = GetComponentInstance();
		myEvent.mArgument.mParameter.mParameterID = i;
		myEvent.mArgument.mParameter.mScope = kAudioUnitScope_Global;
		myEvent.mArgument.mParameter.mElement = 0;
		AUEventListenerNotify(NULL, NULL, &myEvent);
	}
	
	return noErr;
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::SaveState( CFPropertyListRef * outData)
{
	LOG("SaveState\n")

	ComponentResult result = AUBase::SaveState(outData);
	if (result != noErr)
		return result;

	CFMutableDictionaryRef dict = (CFMutableDictionaryRef) *outData; // AUBAse made a mutable dict

	SBRootCircuit *c = mCircuits[0];
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		CFDictionarySetValue(dict, @"SonicBirthData", [c currentState]);
	[pool release];
	
	*outData = dict; // not needed ? anyway doesn't hurt...

	return noErr;
}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::RestoreState( CFPropertyListRef	inData)
{
	LOG("RestoreState\n")

	ComponentResult result = AUBase::RestoreState(inData);
	if (result != noErr)
		return result;

	NSData *data = (NSData *)(CFDictionaryGetValue((CFDictionaryRef)inData, @"SonicBirthData"));
	if (!data)
		return kAudioUnitErr_InvalidPropertyValue;

	// if share
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		[mCircuits[0] loadState:data];
	[pool release];

	/*
	// if don't share:
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		int c = mCircuits.size(), i;
		for (i = 0; i < c; i++)
			[mCircuits[i] loadState:data];
	[pool release];
	*/
	return noErr;
}

//------------------------------------------------------------------------------------------
UInt32 CLASS_NAME::SupportedNumChannels(const AUChannelInfo ** outInfo)
{
	LOG("SupportedNumChannels\n")

	if (outInfo != NULL)
		*outInfo = &mChannelInfo;

	return 1;

}

//------------------------------------------------------------------------------------------
ComponentResult CLASS_NAME::Initialize()
{
	LOG("Initialize\n")

	#ifdef MUSIC_DEVICE
		int auNumOutputs = GetStreamFormat(kAudioUnitScope_Output, (AudioUnitElement)0).mChannelsPerFrame;
		LOG("\tauNumOutputs: %i, outChannels: %i\n", auNumOutputs, mChannelInfo.outChannels)
		if (mChannelInfo.outChannels != -1 && auNumOutputs != mChannelInfo.outChannels)
			return kAudioUnitErr_FormatNotSupported;
	#else
		ComponentResult result = SUPER_CLASS_NAME::Initialize();
		if (result != noErr) return result;
	#endif
	
	pthread_mutex_lock(mMutex);

	mSampleRate = (int)(GetOutput(0)->GetStreamFormat().mSampleRate);
	// PropertyChanged(kAudioUnitProperty_Latency, kAudioUnitScope_Global, (AudioUnitElement)0);
	
	mCalculatingOffset = 0;
	mMinFeedbackTime = (int)(mSampleRate * kMinFeedbackTime);
	
	MaintainCircuits();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	int c = mCircuits.size(), i;
	for (i = 0; i < c; i++)
		[mCircuits[i]	prepareForSamplingRate:mSampleRate
						sampleCount:kSamplesPerCycle
						precision:[mCircuits[0] precision]
						interpolation:[mCircuits[0] interpolation]];
				
	[pool release];
	
	// temps buffers
	if (mSilence) free(mSilence);
	for (i = 0; i < mBuffersCount; i++)
		free(mBuffers[i].ptr);

	if (mSingleCircuit) mBuffersCount = mChannelInfo.inChannels;
	else mBuffersCount = c;
	
	if (mHasSideChain) mBuffersCount *= 2;
	if (mNeedsTempo) mBuffersCount += 2;
	
	for (i = 0; i < mBuffersCount; i++)
	{
		int size = kSamplesPerCycle * sizeof(double);
		mBuffers[i].ptr = malloc(size);
		if (!mBuffers[i].ptr) COMPONENT_THROW(-1);
		memset(mBuffers[i].ptr, 0, size);
	}
	
	int size = kSamplesPerCycle * sizeof(float);
	mSilence = (float*)malloc(size);
	if (!mSilence) COMPONENT_THROW(-1);
	memset(mSilence, 0, size);
	
	pthread_mutex_unlock(mMutex);
	
	// since hosts aren't required to trigger Reset between Initializing and starting audio processing, 
	// it's a good idea to do it ourselves here
	//Reset(kAudioUnitScope_Global, (AudioUnitElement)0);
	// BUT since [circuit reset] is currently implied by [circuit prepare...]
	// it isn't needed
	
	return noErr;
}

#ifndef MUSIC_DEVICE
ComponentResult CLASS_NAME::Render(	AudioUnitRenderActionFlags &ioActionFlags,
										const AudioTimeStamp &		inTimeStamp,
										UInt32						nFrames)
{
	if (mHasSideChain)
	{
		if (HasInput(1))
		{			
			AUInputElement *theInput = GetInput(1);
			ComponentResult result = theInput->PullInput(ioActionFlags, inTimeStamp, 1 /* element */, nFrames);
			
			if (result != noErr) return result;
			
			LOG("pulled sidechain\n")
		}
	}

	return SUPER_CLASS_NAME::Render(ioActionFlags, inTimeStamp, nFrames);
}
#endif
//------------------------------------------------------------------------------------------
OSStatus CLASS_NAME::ProcessBufferLists(AudioUnitRenderActionFlags & ioActionFlags, 
												const AudioBufferList & oInBuffer,
												AudioBufferList & outBuffer, 
												UInt32 inFramesToProcess)
{
	int done = 0;
	
#ifdef MUSIC_DEVICE
	int inputs = 0;
#else
	int inputs = GetInput(0)->GetStreamFormat().mChannelsPerFrame;
#endif

	int outputs = GetOutput(0)->GetStreamFormat().mChannelsPerFrame;
	int realOutputs = outputs;

	// we do not support interleaved data
	if (((int)oInBuffer.mNumberBuffers < inputs) || ((int)outBuffer.mNumberBuffers < outputs))
		return kAudioUnitErr_FormatNotSupported;

	struct
	{
		 UInt32      mNumberBuffers;
		 AudioBuffer mBuffers[256];
	} tInBuffer;
	tInBuffer.mNumberBuffers = (mHasSideChain) ? (inputs * 2) : inputs;
	
	for (int i = 0; i < inputs; i++)
		tInBuffer.mBuffers[i] = oInBuffer.mBuffers[i];
		
	if (mHasSideChain)
	{
		if (HasInput(1))
		{
			LOG("Connected sidechain\n")
			const AudioBufferList & sideInBuffer = GetInput(1)->GetBufferList();
			
			LOG("\tqte: %i\n", sideInBuffer.mNumberBuffers)
			LOG("\tsize: %i\n", (sideInBuffer.mNumberBuffers > 0) ? sideInBuffer.mBuffers[0].mDataByteSize/sizeof(float) : 0)
			LOG("\texpected: %i\n", oInBuffer.mBuffers[0].mDataByteSize/sizeof(float))
			
			if ((int)sideInBuffer.mNumberBuffers != inputs)
				return kAudioUnitErr_FormatNotSupported;
				
			AudioBufferList &inputBufferList = GetInput(0)->GetBufferList();
			int offset = (char*)oInBuffer.mBuffers[0].mData - (char*)inputBufferList.mBuffers[0].mData;
			
			LOG("\toffset: %i\n", offset)
			
			for (int i = 0, j = inputs; i < inputs; i++, j++)
			{
				tInBuffer.mBuffers[j].mNumberChannels = 1;
				tInBuffer.mBuffers[j].mDataByteSize = inFramesToProcess * sizeof(float);
				tInBuffer.mBuffers[j].mData = (void*)((char*)sideInBuffer.mBuffers[i].mData + offset);
			}
			
			#ifdef DO_LOG_STUFF
			for (int i = 0; i < inputs; i++) LOG("real in %i : %p\n", i, inputBufferList.mBuffers[i].mData)
			for (int i = 0; i < inputs; i++) LOG("side in %i : %p\n", i, sideInBuffer.mBuffers[i].mData)
			for (int i = 0; i < inputs*2; i++) LOG("temp in %i : %p\n", i, tInBuffer.mBuffers[i].mData)
			#endif
		}
		else
		{
			LOG("Silence sidechain\n")
			for (int i = 0, j = inputs; i < inputs; i++, j++)
			{
				tInBuffer.mBuffers[j].mNumberChannels = 1;
				tInBuffer.mBuffers[j].mDataByteSize = inFramesToProcess * sizeof(float);
				tInBuffer.mBuffers[j].mData = (void*)mSilence;
			}
		}

		inputs *= 2;
	}
	
	AudioBufferList &inBuffer = *((AudioBufferList*) &tInBuffer);

	if (mChannelInfo.inChannels == 0 && mChannelInfo.outChannels == -1)
		outputs = 1;

	pthread_mutex_lock(mMutex);
	//LOG("Enter critial\n")
	
	SBPrecision precision = mCircuits[0]->pPrecision;
	
	int i, j, k, c = mCircuits.size();
	int frameToProcess = inFramesToProcess;

	// if inputs == 0 <==> mSingleCircuit == YES

	// init inputs
	// do tempo first
	int bufOffset = 0;
	if (mNeedsTempo)
	{
		Float64 beat, tempo;
		OSStatus result = CallHostBeatAndTempo (&beat, &tempo);
		if (result != noErr)
		{
			beat = 0;
			tempo = 0;
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
		LOG("tempo %p\n", mBuffers[0].ptr)
		LOG("beat %p\n", mBuffers[1].ptr)
		#endif
		
		bufOffset = 2;
	}
	
	if (precision == kFloatPrecision)
	{
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			for (i = 0, j = bufOffset; i < inputs; i++, j++)
				circuit->pInputBuffers[j].floatData = (float*)(inBuffer.mBuffers[i].mData);
		}
		else
		{
			for (j = 0; j < c; j++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[bufOffset].floatData = (float*)(inBuffer.mBuffers[j].mData);
				if (mHasSideChain) circuit->pInputBuffers[bufOffset+1].floatData = (float*)(inBuffer.mBuffers[j+c].mData);
			}
			
						
			#ifdef DO_LOG_STUFF
			for (j = 0; j < c; j++)
			{
				int max = bufOffset + ((mHasSideChain) ? 2 : 1);
				SBRootCircuit *circuit = mCircuits[j];
				for (int i = 0; i < max; i++) LOG("circ %i input %i : %p\n", j, i, circuit->pInputBuffers[i].floatData)
			}
			#endif
		}
	}
	else
	{
		for (i = 0, k = bufOffset; i < inputs; i++, k++)
			for(j = 0; j < frameToProcess; j++)
				mBuffers[k].doubleData[j] = ((float*)(inBuffer.mBuffers[i].mData))[j];
				
		if (mSingleCircuit)
		{
			SBRootCircuit *circuit = mCircuits[0];
			for (i = 0, j = bufOffset; i < inputs; i++, j++)
				circuit->pInputBuffers[j].doubleData = mBuffers[j].doubleData;
		}
		else
		{
			for (j = 0, k = bufOffset; j < c; j++, k++)
			{
				SBRootCircuit *circuit = mCircuits[j];
				circuit->pInputBuffers[bufOffset].doubleData = mBuffers[k].doubleData;
				if (mHasSideChain) circuit->pInputBuffers[bufOffset+1].doubleData = mBuffers[k+c].doubleData;
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
					float *dst = ((float*)outBuffer.mBuffers[i].mData) + done;
					
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
					float *dst = ((float*)outBuffer.mBuffers[i].mData) + done;
					
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
					if (mNeedsTempo)
					{
						circuit->pInputBuffers[1].floatData -= offset;
						circuit->pInputBuffers[2].floatData -= offset;
					}
					
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
				
					// forward inputs
					circuit->pInputBuffers[0].floatData += offset + todo;
					if (mNeedsTempo)
					{
						circuit->pInputBuffers[1].floatData += offset + todo;
						circuit->pInputBuffers[2].floatData += offset + todo;
					}
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
					float *dst = ((float*)outBuffer.mBuffers[j].mData) + done;
						
					memcpy(dst, src, todo * sizeof(float));
				}
			}
			else
			{
				for (j = 0; j < c; j++)
				{
					SBRootCircuit *circuit = mCircuits[j];

					// backward inputs
					/*circuit->pInputBuffers[0].doubleData -= offset;
					if (mNeedsTempo)
					{
						circuit->pInputBuffers[1].doubleData -= offset;
						circuit->pInputBuffers[2].doubleData -= offset;
					}
					
					// calculate
					(circuit->pCalcFunc)(circuit, todo, offset);
				
					// forward inputs
					circuit->pInputBuffers[0].doubleData += offset + todo;
					if (mNeedsTempo)
					{
						circuit->pInputBuffers[1].doubleData += offset + todo;
						circuit->pInputBuffers[2].doubleData += offset + todo;
					}*/
					
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
					float *dst = ((float*)outBuffer.mBuffers[j].mData) + done;
					
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
		float *src = (float*)outBuffer.mBuffers[0].mData;
					
		for (int idx = 1; idx < realOutputs; idx++)
		{
			float *dst = (float*)outBuffer.mBuffers[idx].mData;
			memcpy(dst, src, inFramesToProcess * sizeof(float));
		}
	}
	
	// output is silence ? no? then:
	ioActionFlags &= ~kAudioUnitRenderAction_OutputIsSilence;
		
	//LOG("Exit critial\n")
	pthread_mutex_unlock(mMutex);
	
	return noErr;
}

//------------------------------------------------------------------------------------------
#ifdef MUSIC_DEVICE
ComponentResult CLASS_NAME::Render(AudioUnitRenderActionFlags & ioActionFlags, 
									const AudioTimeStamp & inTimeStamp,
									UInt32 inFramesToProcess)
{
        // get the output element
        AUOutputElement * theOutput = GetOutput(0);     // throws if there's an error
        AudioBufferList & outBuffers = theOutput->GetBufferList();
		
		AudioBufferList inBuffers;
		inBuffers.mNumberBuffers = 0;

        return ProcessBufferLists(ioActionFlags, inBuffers, outBuffers, inFramesToProcess);
}
#endif

//------------------------------------------------------------------------------------------
#ifdef USES_MIDI
OSStatus CLASS_NAME::HandleMidiEvent(UInt8 inStatus,
										UInt8 inChannel,
										UInt8 inData1,
										UInt8 inData2,
										UInt32 inStartFrame)
{
	OSStatus result = AUMIDIBase::HandleMidiEvent(inStatus, inChannel, inData1, inData2, inStartFrame);
	if (result != noErr)
	{
		LOG("AUMIDIBase error")
		return result;
	}
	
	LOG("status: %i channel: %i inData1: %i inData2: %i offset: %i\n",
		(int)inStatus, (int)inChannel, (int)inData1, (int)inData2, (int)inStartFrame)

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

	SBRootCircuit *c = mCircuits[0];
	[c dispatchMidiEvent:inStatus channel:inChannel data1:inData1 data2:inData2 offsetToChange:inStartFrame];
	
	[pool release];
	
	return result;
}
#endif

void CLASS_NAME::guiLock()
{
	LOG("guiLock\n")
	if (mSingleCircuit) return;
	if (mCircuits.size() <= 1) return;
	
	pthread_mutex_lock(mMutex);
}

void CLASS_NAME::guiUnlock()
{
	LOG("guiUnlock\n")
	if (mSingleCircuit) return;
	if (mCircuits.size() <= 1) return;
	
	pthread_mutex_unlock(mMutex);
}

void CLASS_NAME::guiResync()
{
	LOG("guiResync\n")
	if (mSingleCircuit) return;
	if (mCircuits.size() <= 1) return;
	
	// resync...
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSData *dt = [mCircuits[0] currentState];
	
	int c = mCircuits.size(), i;
	for (i = 1; i < c; i++)
		[mCircuits[i] loadState:dt];
	
	[pool release];
}

#endif /* DO_COMPILE_CLASSES */

