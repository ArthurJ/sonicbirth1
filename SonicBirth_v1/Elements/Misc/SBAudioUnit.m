/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#ifndef COMPILING_CLASSES
#define COMPILING_CLASSES


// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------

#import "SBAudioUnit.h"
#import "SBAudioUnitMidi.h"
#import "SBBooleanCell.h"
#define kMaxAuChannels (8+2) // 8 au channels, 2 for tempo and beat

#import <Carbon/Carbon.h>

static OSStatus getBeatAndTempoCallback ( void*                inHostUserData,
										Float64*             outCurrentBeat, 
										Float64*             outCurrentTempo)
{
	SBAudioUnit *obj = inHostUserData;
	if (!obj) return paramErr;
	
	if (outCurrentTempo) *outCurrentTempo = obj->mTempo;
	if (outCurrentBeat) *outCurrentBeat = obj->mBeat;
	
    return noErr;
}

static OSStatus inputCallback (	void                       *inRefCon, 
								AudioUnitRenderActionFlags      *inActionFlags,
								const AudioTimeStamp            *inTimeStamp, 
								UInt32                          inBusNumber,
								UInt32                          inNumFrames, 
								AudioBufferList                 *ioData)
{
	SBAudioUnit *obj = inRefCon;
	if (!obj) return paramErr;
	
	int inputs = obj->mInputCount;	
	int offset = obj->mCycleOffset;
	int count = obj->mCycleCount;
	int i, c;
	
	if (inBusNumber != 0) goto erase;
	if (inNumFrames != count) goto erase;
	if (ioData->mNumberBuffers != inputs) goto erase;
			
	if (obj->mPrecision == kFloatPrecision)
	{
		for (i = 0; i < inputs; i++)
		{
			float *src = obj->pInputBuffers[2+i].floatData + offset;
			float *dst = (float*)ioData->mBuffers[i].mData;
			memcpy(dst, src, count * sizeof(float));
		}
	}
	else
	{
		for (i = 0; i < inputs; i++)
		{
			double *src = obj->pInputBuffers[2+i].doubleData + offset;
			float *dst = (float*)ioData->mBuffers[i].mData;
			int j;
			for (j = 0; j < count; j++)
				*dst++ = *src++;
		}
	}

	return noErr;
	
	
erase:
	
	c = ioData->mNumberBuffers;
	for (i = 0; i < c; i++)
		memset(ioData->mBuffers[i].mData, 0, ioData->mBuffers[i].mDataByteSize);
	
	return noErr;
}

OSStatus GetAUNameAndManufacturerCStrings(Component inAUComponent, char * outNameString, char * outManufacturerString)
{
	OSStatus error = noErr;
	Handle componentNameHandle;
	ConstStr255Param componentFullNamePString;
	ComponentDescription dummydesc;

	// one input string or the other can be null, but not both
	if ( (inAUComponent == NULL) || ((outNameString == NULL) && (outManufacturerString == NULL)) )
		return paramErr;

	// first we need to create a handle and then try to fetch the Component name string resource into that handle
	componentNameHandle = NewHandle(sizeof(void*));
	if (componentNameHandle == NULL)
		return nilHandleErr;
	error = GetComponentInfo(inAUComponent, &dummydesc, componentNameHandle, NULL, NULL);
	if (error != noErr)
		return error;
	// dereferencing the name resource handle gives us a Pascal string pointer
	HLock(componentNameHandle);
	componentFullNamePString = (ConstStr255Param) (*componentNameHandle);
	if (componentFullNamePString == NULL)
		error = nilHandleErr;
	else
	{
		char * separatorByte;
		// convert the Component name Pascal string to a C string
		char componentFullNameCString[sizeof(Str255)];
		componentFullNameCString[0] = 0;
		
		//CopyPascalStringToC(componentFullNamePString, componentFullNameCString);
		
		CFStringRef s = CFStringCreateWithPascalString(NULL, componentFullNamePString, kCFStringEncodingMacRoman);
		if (s)
		{
			CFStringGetCString(s, componentFullNameCString, sizeof(componentFullNameCString), kCFStringEncodingUTF8);
			CFRelease(s);
		}
		
		// the manufacturer string is everything before the first : character, 
		// and everything after that and any immediately following white space 
		// is the plugin name string
		separatorByte = strchr(componentFullNameCString, ':');
		if (separatorByte == NULL)
			error = internalComponentErr;
		else
		{
			// point to right after the : character for the plugin name string...
			char * pluginNameCString = separatorByte + 1;
			// this will terminate the manufacturer name string right before the : character
			char * manufacturerNameCString = componentFullNameCString;
			separatorByte[0] = 0;
			// ...and then also skip over any white space immediately following the : delimiter
			while ( isspace(*pluginNameCString) )
				pluginNameCString++;

			// copy any of the requested strings for output
			if (outNameString != NULL)
				strcpy(outNameString, pluginNameCString);
			if (outManufacturerString != NULL)
				strcpy(outManufacturerString, manufacturerNameCString);
		}
	}
	DisposeHandle(componentNameHandle);

	return error;
}

// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------

#define CLASSNAME SBAudioUnit
#define CLASS_FUNC SBAudioUnit_privateFunction
#include "SBAudioUnit.m"
#undef CLASS_FUNC
#undef CLASSNAME

#define CLASSNAME SBAudioUnitMidi
#define MIDI_STUFF
#define CLASS_FUNC SBAudioUnitMidi_privateFunction
#include "SBAudioUnit.m"
#undef CLASS_FUNC
#undef MIDI_STUFF
#undef CLASSNAME

#else

// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------
// ----------------------------------------------------------------------------------------------



static void CLASS_FUNC(void *inObj, int count, int offset)
{
	CLASSNAME *obj = inObj;
	
	if (!count) return;
	
	AudioUnit au = obj->mAudioUnit;
	if (!au) return;

	int inputs = obj->mInputCount;	
	int outputs = obj->mOutputCount;
	AudioTimeStamp ts = obj->mTimeStamp;
	
	int params = obj->mParameterExportedCount;
	AudioUnitParameterID *paramsList = obj->mParameterExportedList;
	float *mins = obj->mParameterExportedMins;
	float *maxs = obj->mParameterExportedMaxs;
	float *last = obj->mParameterExportedLastValue;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		obj->mTempo = obj->pInputBuffers[0].floatData[offset];
		obj->mBeat = obj->pInputBuffers[1].floatData[offset];
	}
	else
	{
		obj->mTempo = obj->pInputBuffers[0].doubleData[offset];
		obj->mBeat = obj->pInputBuffers[1].doubleData[offset];
	}
			
	while(count > 0)
	{
		int todo = (obj->mMaxPerCycle > count) ? count : obj->mMaxPerCycle;
		
		
		// setup paramters
		int i;
		for (i = 0; i < params; i++)
		{
			float value = obj->pInputBuffers[2 + inputs + i].floatData[offset];
			float min = mins[i], max = maxs[i];
			if (value < min) value = min;
			if (value > max) value = max;
			
			if (value != last[i])
			{
				AudioUnitSetParameter(  au,
										paramsList[i], kAudioUnitScope_Global,
										0, value, 0);
				last[i] = value;
			}
		}
		obj->mCycleOffset = offset;
		obj->mCycleCount = todo;
		
		struct
		{
			UInt32      mNumberBuffers;
			AudioBuffer mBuffers[256];
		} tInBuffer;
		
		memset(&tInBuffer, 0, sizeof(tInBuffer));
		
		tInBuffer.mNumberBuffers = outputs;
		
		for (i = 0; i < outputs; i++)
		{
			tInBuffer.mBuffers[i].mNumberChannels = 1;
			tInBuffer.mBuffers[i].mDataByteSize = todo * sizeof(float);
			tInBuffer.mBuffers[i].mData = nil; //obj->mAudioBuffers[i].floatData + offset;
		}
		
		AudioUnitRenderActionFlags actionFlags = 0;

		ComponentResult err = AudioUnitRender (au, &actionFlags, &ts, 0, todo, (AudioBufferList*)&tInBuffer); 
		if (err == noErr)
		{
			if (obj->mPrecision == kFloatPrecision)
			{
				for (i = 0; i < outputs; i++)
				{
					float *src = tInBuffer.mBuffers[i].mData;
					float *dst = obj->mAudioBuffers[i].floatData + offset;
					memcpy(dst, src, todo * sizeof(float));
				}
			}
			else
			{
				for (i = 0; i < outputs; i++)
				{
					float *src = tInBuffer.mBuffers[i].mData;
					double *dst = obj->mAudioBuffers[i].doubleData + offset;
					int j;
					for (j = 0; j < count; j++)
						*dst++ = *src++;
				}
			}
		}
		else
		{
			if (obj->mPrecision == kFloatPrecision)
			{
				for (i = 0; i < outputs; i++)
				{
					float *dst = obj->mAudioBuffers[i].floatData + offset;
					memset(dst, 0, todo * sizeof(float));
				}
			}
			else
			{
				for (i = 0; i < outputs; i++)
				{
					double *dst = obj->mAudioBuffers[i].doubleData + offset;
					memset(dst, 0, todo * sizeof(double));
				}
			}
		}
		
		ts.mSampleTime += todo;
		count -= todo;
		offset += todo;
	}
	
	obj->mTimeStamp = ts;
}

@implementation CLASSNAME


+ (NSString*) name
{
#ifndef MIDI_STUFF
	return @"AudioUnit";
#else
	return @"AudioUnit (midi)";
#endif
}

- (NSString*) name
{
	return mIntName;
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (NSString*) informations
{
	return	@"Wraps a third party audiounit.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = CLASS_FUNC;
		
		mIntName = [[NSMutableString alloc] initWithString:@"au"];
		if (!mIntName)
		{
			[self release];
			return nil;
		}
#ifdef MIDI_STUFF
		// for simple argument super class
		mNumberOfOutputs = 0;
#endif
	}
	return self;
}

- (void) dealloc
{
	if (mAudioUnit) CloseComponent(mAudioUnit);
	if (mAudioUnitList) [mAudioUnitList release];
	if (mAudioUnitChannelConfig) [mAudioUnitChannelConfig release];
	if (mParameterList) free(mParameterList);
	if (mParameterExportedList) free(mParameterExportedList);
	if (mParameterExportedMins) free(mParameterExportedMins);
	if (mParameterExportedMaxs) free(mParameterExportedMaxs);
	if (mParameterExportedLastValue) free(mParameterExportedLastValue);
	if (mIntName) [mIntName release];
	if (mAuGui) [mAuGui release];
	[super dealloc];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:[self className] owner:self];
		return mSettingsView;
	}
}


- (void) awakeFromNib
{
	[super awakeFromNib];

	[self ui_listAllAUs];
	[self ui_updateChannelConfig];
}

- (void) ui_listAllAUs
{
	if (mAudioUnitList) return;

	// list all available aus, cache them and set the popUp
	mAudioUnitList = [[NSMutableArray alloc] init];
	assert(mAudioUnitList);

	[mAudioUnitListPopUp removeAllItems];
	[mAudioUnitListPopUp addItemWithTitle:@"None"];

	ComponentDescription desc;
#ifndef MIDI_STUFF
	desc.componentType = kAudioUnitType_Effect;
#else
	desc.componentType = kAudioUnitType_MusicEffect;
#endif
	desc.componentSubType = 0;
	desc.componentManufacturer = 0;
	desc.componentFlags = 0;
	desc.componentFlagsMask = 0;
	
	int selectedAudioUnit = 0, c = 0;
	
	Component theAUComponent;
	
findMore:
	theAUComponent = FindNextComponent (NULL, &desc);
	while (theAUComponent != NULL)
	{
		// now we need to get the information on the found component
		ComponentDescription found;
		GetComponentInfo (theAUComponent, &found, 0, 0, 0);

		if (found.componentManufacturer != 'ScBh')
		{
			char name[512], manuf[512];
			
			OSStatus err = GetAUNameAndManufacturerCStrings(theAUComponent, name, manuf);
			if (err == noErr)
			{
				[mAudioUnitList addObject:[NSNumber numberWithUnsignedInt:found.componentType]];
				[mAudioUnitList addObject:[NSNumber numberWithUnsignedInt:found.componentSubType]];
				[mAudioUnitList addObject:[NSNumber numberWithUnsignedInt:found.componentManufacturer]];
				
				[mAudioUnitListPopUp addItemWithTitle:[NSString stringWithFormat:@"%s :: %s", name, manuf]];
				c++;
				
				if (mType == found.componentType && mSubType == found.componentSubType && mManufacturer == found.componentManufacturer)
					selectedAudioUnit = c;
			}
		}
		
		theAUComponent = FindNextComponent (theAUComponent, &desc);
	}
	if (desc.componentType == kAudioUnitType_Effect)		{ desc.componentType = kAudioUnitType_MusicEffect; goto findMore; }
	if (desc.componentType == kAudioUnitType_MusicEffect)	{ desc.componentType = kAudioUnitType_MusicDevice; goto findMore; }
	
	if (selectedAudioUnit)
		[mAudioUnitListPopUp selectItemAtIndex:selectedAudioUnit];
}

- (void) ui_updateChannelConfig
{
	if (mAudioUnit)
	{
		[mAudioUnitChannelConfigPopUp removeAllItems];
		
		if (!mAudioUnitChannelConfig) mAudioUnitChannelConfig = [[NSMutableArray alloc] init];
		else [mAudioUnitChannelConfig removeAllObjects];
		assert(mAudioUnitList);
		
		int i, j, c = 0, s = 0;
		for (i = 0; i < kMaxAuChannels; i++)
			for(j = 0; j < kMaxAuChannels; j++)
			{
				BOOL isOK = [self setChannelConfigInputs:i outputs: j];
				if (isOK)
				{
					if (mInputCount == i && mOutputCount == j)
						s = c;
				
					[mAudioUnitChannelConfig addObject:[NSNumber numberWithInt:i]];
					[mAudioUnitChannelConfig addObject:[NSNumber numberWithInt:j]];
					[mAudioUnitChannelConfigPopUp addItemWithTitle:[NSString stringWithFormat:@"%i/%i", i, j]]; 
			
					c++;
				}
			}
			
		if (!c)			
			[mAudioUnitChannelConfigPopUp addItemWithTitle:@"N/A"];
		else if (s)
			[mAudioUnitChannelConfigPopUp selectItemAtIndex:s];
	}
	else
	{
		[mAudioUnitChannelConfigPopUp removeAllItems];
		[mAudioUnitChannelConfigPopUp addItemWithTitle:@"N/A"];
	}
}

- (void) showAuGui:(id)sender
{
	if (mAuGui) [mAuGui show];
	else if (mAudioUnit)
	{
		mAuGui = [[SBAudioUnitEditor alloc] initWithAudioUnit:mAudioUnit forceGeneric:NO delegate:self];
		if (!mAuGui) return;
	
		[mAuGui show];
	}
}

- (void) audioUnitEditorClosed:(SBAudioUnitEditor*)auEditor;
{
	if (mAuGui) [mAuGui release];
	mAuGui = nil;
}

- (void) chooseAudioUnit:(id)sender
{
	int idx = [mAudioUnitListPopUp indexOfSelectedItem] - 1, index3 = idx * 3;
	int count = [mAudioUnitList count];
	
	if (idx >= 0 && index3 < count)
	{
		[self openAudioUnitType:[[mAudioUnitList objectAtIndex:index3] unsignedIntValue]
						subType:[[mAudioUnitList objectAtIndex:index3+1] unsignedIntValue]
						  manuf:[[mAudioUnitList objectAtIndex:index3+2] unsignedIntValue]];		
	}
	else
	{
		[self openAudioUnitType:0
						subType:0
						  manuf:0];
	}
	
	[self ui_updateChannelConfig];
	
	if (!mAudioUnit)
		[mAudioUnitListPopUp selectItemAtIndex:0];
		
	[mParameterTable reloadData];
}

- (void) chooseChannelConfig:(id)sender
{
	int idx = [mAudioUnitChannelConfigPopUp indexOfSelectedItem], index2 = idx * 2;
	int count = [mAudioUnitChannelConfig count];
	
	if (idx >= 0 && index2 < count)
	{
		int inputs = [[mAudioUnitChannelConfig objectAtIndex:index2] intValue];
		int outputs = [[mAudioUnitChannelConfig objectAtIndex:index2+1] intValue];
		BOOL isOK = [self setChannelConfigInputs:	inputs
										outputs: outputs];
		
		[self willChangeAudio];
		
		if (isOK) { mInputCount = inputs; mOutputCount = outputs; }
		else { mInputCount = 0; mOutputCount = 0; }
		
		// output count may have change, recall prepareOnOurselves
		[self prepareForSamplingRate:mSampleRate
						 sampleCount:mSampleCount
						   precision:mPrecision
					   interpolation:mInterpolation];
		
		[self didChangeConnections];
		[self didChangeAudio];
		[self didChangeGlobalView];
	}
}

- (void) reset
{
	mTempo = mBeat = 0;
	mTimeStamp.mSampleTime = 0;
    mTimeStamp.mFlags = kAudioTimeStampSampleTimeValid;
	if (mAudioUnit) AudioUnitReset(mAudioUnit, kAudioUnitScope_Global, 0);
	
	//
	int i, ec = mParameterExportedCount;
	for (i = 0; i < ec; i++)
	{
		float value = 0;
		ComponentResult err = AudioUnitGetParameter(	mAudioUnit,
														mParameterExportedList[i], kAudioUnitScope_Global,
														0, &value);
														
		if (err == noErr) mParameterExportedLastValue[i] = value;
		else mParameterExportedLastValue[i] = -1e20; // fake invalid value
	}
	//
	
	
	[super reset];
}


- (void) openAudioUnitType:(OSType)type subType:(OSType)subType manuf:(OSType)manuf
{
	[self willChangeAudio];
	
	if (mAudioUnit) CloseComponent(mAudioUnit);
	mAudioUnit = nil;
	mInputCount = 0;
	mOutputCount = 0;
	mType = 0;
	mSubType = 0;
	mManufacturer = 0;
	if (mParameterList) free(mParameterList); mParameterList = nil;
	if (mParameterExportedList) free(mParameterExportedList); mParameterExportedList = nil;
	if (mParameterExportedMins) free(mParameterExportedMins); mParameterExportedMins = nil;
	if (mParameterExportedMaxs) free(mParameterExportedMaxs); mParameterExportedMaxs = nil;
	if (mParameterExportedLastValue) free(mParameterExportedLastValue); mParameterExportedLastValue = nil;
	mParameterCount = 0; mParameterExportedCount = 0;
	if (mAuGui) [mAuGui release]; mAuGui = nil;
	[mIntName setString:@"au"];
	
	if (type && subType && manuf)
	{
		ComponentDescription desc;
		desc.componentType = type;
		desc.componentSubType = subType;
		desc.componentManufacturer = manuf;
		desc.componentFlags = 0;
		desc.componentFlagsMask = 0;
		
		Component auComp = FindNextComponent (NULL, &desc);
		if (auComp)
		{
			OSErr result = OpenAComponent (auComp, &mAudioUnit);
			if (result != noErr) mAudioUnit = nil;
		}
	}
	
	if (mAudioUnit)
	{
		AURenderCallbackStruct callback;
		callback.inputProc = inputCallback;
		callback.inputProcRefCon = self;

		ComponentResult err;
		
		// ignore error (music devices)
		AudioUnitSetProperty(	mAudioUnit, 
								kAudioUnitProperty_SetRenderCallback,
								kAudioUnitScope_Input,
								0, &callback, sizeof (callback));
								
		err = AudioUnitInitialize(mAudioUnit);
			
		if (err == noErr)
		{
			mMaxPerCycle = 64;
			
			UInt32 max, size = sizeof(max);
			err = AudioUnitGetProperty(	mAudioUnit,
										kAudioUnitProperty_MaximumFramesPerSlice,
										kAudioUnitScope_Global,
										0,
										&max,
										&size);
			if (err == noErr)
				mMaxPerCycle = (max > 1024) ? 1024 : max;
		}
		
		if (err == noErr)
			[self setUpParameterList];
			
		if (err == noErr)
		{
			char name[512], manufstr[512];
			
			OSStatus errVar = GetAUNameAndManufacturerCStrings((Component)mAudioUnit, name, manufstr);
			if (errVar == noErr)
				[mIntName setString:[NSString stringWithFormat:@"%s :: %s", name, manufstr]];
			else
				[mIntName setString:@"au"];
		}
		
		
		if (err == noErr)
		{
		    HostCallbackInfo info; memset (&info, 0, sizeof (HostCallbackInfo));
			info.hostUserData = self;
			info.beatAndTempoProc = getBeatAndTempoCallback;
						
			//ignore result of this - don't care if the property isn't supported
			AudioUnitSetProperty (mAudioUnit, 
									kAudioUnitProperty_HostCallbacks, 
									kAudioUnitScope_Global, 
									0, &info, sizeof (HostCallbackInfo));
		}
		
		// do last
		if (err == noErr)
		{
			mType = type;
			mSubType = subType;
			mManufacturer = manuf;
		}
		
		if (err != noErr)
		{
			CloseComponent(mAudioUnit);
			mAudioUnit = nil;
			[mIntName setString:@"au"];
		}
	}
	
	[self didChangeConnections];
	[self didChangeAudio];
	[self didChangeGlobalView];
}

- (BOOL) setChannelConfigInputs:(int)inputs outputs:(int)outputs
{
	if (!mAudioUnit) return NO;
	
	BOOL success = YES;
	
	[self willChangeAudio];
	
	// base desc
	AudioStreamBasicDescription desc;
	UInt32 size = sizeof(AudioStreamBasicDescription);
	desc.mSampleRate = 44100;
	desc.mFormatID = kAudioFormatLinearPCM;
	desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	desc.mFramesPerPacket = 1;
	desc.mBitsPerChannel = 8 * sizeof(float);
	desc.mBytesPerPacket = desc.mBytesPerFrame = sizeof(float);
	
	// set input
	desc.mChannelsPerFrame = inputs;
	ComponentResult err = AudioUnitSetProperty(	mAudioUnit,
												kAudioUnitProperty_StreamFormat,
												kAudioUnitScope_Input,
												0, &desc, size);
	if (err != noErr && inputs) success = NO;
	else
	{
		// set output
		desc.mChannelsPerFrame = outputs;
		err = AudioUnitSetProperty(	mAudioUnit,
									kAudioUnitProperty_StreamFormat,
									kAudioUnitScope_Output,
									0, &desc, size);
		if (err != noErr && outputs) success = NO;
	}
	
	[self didChangeAudio];
	
	return success;
}

- (void) setUpParameterList
{
	if (!mAudioUnit)
	{
		if (mParameterList) free(mParameterList); mParameterList = nil;
		if (mParameterExportedList) free(mParameterExportedList); mParameterExportedList = nil;
		if (mParameterExportedMins) free(mParameterExportedMins); mParameterExportedMins = nil;
		if (mParameterExportedMaxs) free(mParameterExportedMaxs); mParameterExportedMaxs = nil;
		if (mParameterExportedLastValue) free(mParameterExportedLastValue); mParameterExportedLastValue = nil;
		mParameterCount = 0; mParameterExportedCount = 0;
		return;
	}
	
	if (!mParameterList)
	{
		ComponentResult err;
	
		// get number of parameters
		mParameterCount = 0;
		UInt32 size = 0;
		err = AudioUnitGetProperty(	mAudioUnit,
									kAudioUnitProperty_ParameterList,
									kAudioUnitScope_Global,
									0,
									nil,
									&size);
		if (err == noErr && size > 0)
		{
			mParameterList = (AudioUnitParameterID*)malloc(size);
			mParameterCount = size / sizeof(AudioUnitParameterID);
			
			mParameterExportedList =  (AudioUnitParameterID*)malloc(size);
			mParameterExportedMins =  (float*)malloc(mParameterCount * sizeof(float));
			mParameterExportedMaxs =  (float*)malloc(mParameterCount * sizeof(float));
			mParameterExportedLastValue =  (float*)malloc(mParameterCount * sizeof(float));
			mParameterExportedCount = 0;
			memset(mParameterExportedList, 0, size);
		}	
		if (mParameterList && mParameterExportedList)
		{
			UInt32 size2 = size;
			err = AudioUnitGetProperty(	mAudioUnit,
										kAudioUnitProperty_ParameterList,
										kAudioUnitScope_Global,
										0,
										mParameterList,
										&size2);
		}

		
		if (err != noErr)
		{
			if (mParameterList) free(mParameterList); mParameterList = nil;
			if (mParameterExportedList) free(mParameterExportedList); mParameterExportedList = nil;
			if (mParameterExportedMins) free(mParameterExportedMins); mParameterExportedMins = nil;
			if (mParameterExportedMaxs) free(mParameterExportedMaxs); mParameterExportedMaxs = nil;
			if (mParameterExportedLastValue) free(mParameterExportedLastValue); mParameterExportedLastValue = nil;
			mParameterCount = 0; mParameterExportedCount = 0;
		}
	}
}

- (int) numberOfInputs
{
	return 2 + mInputCount + mParameterExportedCount;
}

- (int) numberOfOutputs
{
	return mOutputCount;
}

- (NSString*) nameOfInputAtIndex:(int)idx
{
	if (idx < 0) return @"";
	if (idx == 0) return @"tempo";
	if (idx == 1) return @"beat";
	idx -= 2;
	
	if (idx < mInputCount) return [NSString stringWithFormat:@"i%i",idx];
	idx -= mInputCount;
	
	if (idx < mParameterExportedCount)
	{
		AudioUnitParameterID pid = mParameterExportedList[idx];
		
		AudioUnitParameterInfo pinfo; memset(&pinfo, 0, sizeof(pinfo));
		UInt32 size = sizeof(pinfo);
		
		ComponentResult err = AudioUnitGetProperty(	mAudioUnit,
													kAudioUnitProperty_ParameterInfo,
													kAudioUnitScope_Global,
													pid,
													&pinfo,
													&size);
		if (err == noErr)
		{
			if (pinfo.flags & kAudioUnitParameterFlag_HasCFNameString)
			{
				if (pinfo.flags & kAudioUnitParameterFlag_CFNameRelease)
					return [(NSString*)pinfo.cfNameString autorelease];
				else
					return (NSString*)pinfo.cfNameString;
			}
			else
				 return [NSString stringWithCString:pinfo.name];
		}
		else
			return [NSString stringWithFormat:@"err %i", err];
	}
	
	 return @"";
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *sd = [super saveData];
	if (!sd) sd = [[[NSMutableDictionary alloc] init] autorelease];
	
	if (mAudioUnit && sd)
	{
		[sd setObject:[NSNumber numberWithUnsignedInt:mType] forKey:@"type"];
		[sd setObject:[NSNumber numberWithUnsignedInt:mSubType] forKey:@"subtype"];
		[sd setObject:[NSNumber numberWithUnsignedInt:mManufacturer] forKey:@"manuf"];
		
		[sd setObject:[NSNumber numberWithInt:mInputCount] forKey:@"inputs"];
		[sd setObject:[NSNumber numberWithInt:mOutputCount] forKey:@"outputs"];
		
		NSMutableArray *a = [[NSMutableArray alloc] init];
		
		int i, c = mParameterCount;
		for (i = 0; i < c; i++)
		{
			
			// pid
			AudioUnitParameterID pid = mParameterList[i];
			[a addObject:[NSNumber numberWithUnsignedInt:pid]];
			
			// value
			float value = 0;
			ComponentResult err = AudioUnitGetParameter(	mAudioUnit,
															pid, kAudioUnitScope_Global,
															0, &value);
			if (err != noErr) value = 0;
			[a addObject:[NSNumber numberWithFloat:value]];
			
			
			// exported
			BOOL exported = NO;
			int j, c2 = mParameterExportedCount;
			for (j = 0; j < c2; j++)
				if (mParameterExportedList[j] == pid)
					exported = YES;
					
			[a addObject:[NSNumber numberWithInt:(exported) ? 2 : 1]];
		}
		[sd setObject:a forKey:@"params"];
		[a release];
	}
	
	return sd;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;
	if (![super loadData:data]) return NO;
	
	NSNumber *type, *subType, *manufacturer, *inputCount, *outputCount;
	NSArray *params;
	
	type = [data objectForKey:@"type"];
	subType = [data objectForKey:@"subtype"];
	manufacturer = [data objectForKey:@"manuf"];
	inputCount = [data objectForKey:@"inputs"];
	outputCount = [data objectForKey:@"outputs"];
	params = [data objectForKey:@"params"];
	
	if (!type || !subType || !manufacturer || !inputCount || !outputCount || !params)
		return NO;
		
	[self openAudioUnitType:[type unsignedIntValue]
					subType:[subType unsignedIntValue]
					  manuf:[manufacturer unsignedIntValue]];

	if (mAudioUnit)
	{
		int inputs = [inputCount intValue];
		int outputs = [outputCount intValue];
		BOOL isOK = [self setChannelConfigInputs:	inputs
										outputs: outputs];
		
		if (isOK) { mInputCount = inputs; mOutputCount = outputs; }
		else { mInputCount = 0; mOutputCount = 0; }
		
		
		mParameterExportedCount = 0;
		int i, c = [params count];
		if (c == mParameterCount*3)
			for (i = 0; i < c - 2; i += 3)
			{

				AudioUnitParameterID pid = [[params objectAtIndex:i] unsignedIntValue];
				float value = [[params objectAtIndex:i+1] floatValue];
				BOOL exported = ([[params objectAtIndex:i+2] intValue] == 2);
				
				AudioUnitSetParameter(  mAudioUnit,
								pid, kAudioUnitScope_Global,
								0, value, 0);
								
				if (exported)
					mParameterExportedList[mParameterExportedCount++] = pid;
			}
			
		[self reorderExportedList];
	}
	
	return YES;
}

- (void) reorderExportedList
{
	int ec = mParameterExportedCount;
	if (ec <= 0) return;

	// create temp mem
	AudioUnitParameterID *temp = (AudioUnitParameterID*)malloc(ec * sizeof(AudioUnitParameterID));
	if (!temp) return;
	
	int tc = 0;
	
	int pc = mParameterCount;
	int i, j;
	for (i = 0; i < ec; i++)
		for (j = 0; j < pc; j++)
		{
			if (mParameterList[j] == mParameterExportedList[i])
			{
				temp[tc++] = mParameterExportedList[i];
				break;
			}
		}

	if (tc == ec)
		memcpy(mParameterExportedList, temp, ec * sizeof(AudioUnitParameterID));
		
	free(temp);
	
	if (!mAudioUnit) return;
	
	for (i = 0; i < ec; i++)
	{
		AudioUnitParameterInfo pinfo; memset(&pinfo, 0, sizeof(pinfo));
		UInt32 size = sizeof(pinfo);
		
		ComponentResult err = AudioUnitGetProperty(	mAudioUnit,
													kAudioUnitProperty_ParameterInfo,
													kAudioUnitScope_Global,
													mParameterExportedList[i],
													&pinfo,
													&size);
		if (err == noErr)
		{
			mParameterExportedMins[i] = pinfo.minValue;
			mParameterExportedMaxs[i] = pinfo.maxValue;
		}
		else
		{
			mParameterExportedMins[i] = 0;
			mParameterExportedMaxs[i] = 0;
		}
	}

}

- (NSString*) nameOfOutputAtIndex:(int)idx
{
	return [NSString stringWithFormat:@"o%i",idx];
}

- (int)numberOfRowsInTableView:(NSTableView *)aTableView
{	
	return mParameterCount;
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex < 0 ||rowIndex >= mParameterCount) return nil;
	NSString *ident = [aTableColumn identifier];
	
	AudioUnitParameterID pid = mParameterList[rowIndex];
	
	if ([ident isEqual:@"export"])
	{
		int i, c = mParameterExportedCount;
		for (i = 0; i < c; i++) if (mParameterExportedList[i] == pid) return [NSNumber numberWithInt:1];
		return [NSNumber numberWithInt:0];
	}
	
	if ([ident isEqual:@"id"]) return [NSString stringWithFormat:@"%i", pid];
	else if ([ident isEqual:@"value"])
	{
		float value = 0;
		ComponentResult err = AudioUnitGetParameter(	mAudioUnit,
														pid, kAudioUnitScope_Global,
														0, &value);
		if (err == noErr) return [NSString stringWithFormat:@"%f", value];
	}
			
	AudioUnitParameterInfo pinfo; memset(&pinfo, 0, sizeof(pinfo));
	UInt32 size = sizeof(pinfo);
	
	ComponentResult err = AudioUnitGetProperty(	mAudioUnit,
												kAudioUnitProperty_ParameterInfo,
												kAudioUnitScope_Global,
												pid,
												&pinfo,
												&size);
	if (err == noErr)
	{

		if ([ident isEqual:@"name"])	
		{
			if (pinfo.flags & kAudioUnitParameterFlag_HasCFNameString)
			{
				if (pinfo.flags & kAudioUnitParameterFlag_CFNameRelease)
					return [(NSString*)pinfo.cfNameString autorelease];
				else
					return (NSString*)pinfo.cfNameString;
			}
			else
				 return [NSString stringWithCString:pinfo.name];
		}
		else if ([ident isEqual:@"unit"])
		{
			//return [NSString stringWithFormat:@"%i", pinfo.unit];
			switch(pinfo.unit)
			{
				  case kAudioUnitParameterUnit_Generic: return @"Generic";
				  case kAudioUnitParameterUnit_Indexed: return @"Indexed";
				  case kAudioUnitParameterUnit_Boolean: return @"Boolean";
				  case kAudioUnitParameterUnit_Percent: return @"Percent";
				  case kAudioUnitParameterUnit_Seconds: return @"Seconds";
				  case kAudioUnitParameterUnit_SampleFrames: return @"SampleFrames";
				  case kAudioUnitParameterUnit_Phase: return @"Phase";
				  case kAudioUnitParameterUnit_Rate: return @"Rate";
				  case kAudioUnitParameterUnit_Hertz: return @"Hertz";
				  case kAudioUnitParameterUnit_Cents: return @"Cents";
				  case kAudioUnitParameterUnit_RelativeSemiTones: return @"RelativeSemiTones";
				  case kAudioUnitParameterUnit_MIDINoteNumber: return @"MIDINoteNumber";
				  case kAudioUnitParameterUnit_MIDIController: return @"MIDIController";
				  case kAudioUnitParameterUnit_Decibels: return @"Decibels";
				  case kAudioUnitParameterUnit_LinearGain: return @"LinearGain";
				  case kAudioUnitParameterUnit_Degrees: return @"Degrees";
				  case kAudioUnitParameterUnit_EqualPowerCrossfade: return @"EqualPowerCrossfade";
				  case kAudioUnitParameterUnit_MixerFaderCurve1: return @"MixerFaderCurve1";
				  case kAudioUnitParameterUnit_Pan: return @"Pan";
				  case kAudioUnitParameterUnit_Meters: return @"Meters";
				  case kAudioUnitParameterUnit_AbsoluteCents: return @"AbsoluteCents";
			
			}
		}
		else if ([ident isEqual:@"min"])
			return [NSString stringWithFormat:@"%f", pinfo.minValue];
		else if ([ident isEqual:@"max"])
			return [NSString stringWithFormat:@"%f", pinfo.maxValue];
		else if ([ident isEqual:@"read"])
			return (pinfo.flags & kAudioUnitParameterFlag_IsReadable) ? @"Yes" : @"No";
		else if ([ident isEqual:@"write"])
			return (pinfo.flags & kAudioUnitParameterFlag_IsWritable) ? @"Yes" : @"No";
	}
	else
		return [NSString stringWithFormat:@"err %i", err];
		
	return nil;
}

- (void)tableView:(NSTableView *)aTableView setObjectValue:(id)anObject forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	if (rowIndex < 0 || rowIndex >= mParameterCount) return;
	NSString *ident = [aTableColumn identifier];
	AudioUnitParameterID pid = mParameterList[rowIndex];
	
	if ([ident isEqual:@"value"])
	{
		AudioUnitSetParameter(  mAudioUnit,
								pid, kAudioUnitScope_Global,
								0, [anObject floatValue], 0);
	}
	else if ([ident isEqual:@"export"])
	{
		BOOL should = [anObject intValue];


		AudioUnitParameterInfo pinfo; memset(&pinfo, 0, sizeof(pinfo));
		UInt32 size = sizeof(pinfo);
			
		ComponentResult err = AudioUnitGetProperty(	mAudioUnit,
													kAudioUnitProperty_ParameterInfo,
													kAudioUnitScope_Global,
													pid,
													&pinfo,
													&size);
		if (err == noErr && (pinfo.flags & kAudioUnitParameterFlag_IsWritable))
		{

			int i, c = mParameterExportedCount;
			for (i = 0; i < c; i++)
				if (mParameterExportedList[i] == pid)
				{
					if (should) return;
					else
					{
						// remove from list
						
						if (mParameterExportedCount < kMaxChannels - kMaxAuChannels)
						{
							[self willChangeAudio];
							
							c--; mParameterExportedCount--;
							for(; i < c; i++)
								mParameterExportedList[i] = mParameterExportedList[i+1];
							[self reorderExportedList];
													
							
							[self didChangeConnections];
							[self didChangeAudio];
							[self didChangeGlobalView];
						}
						
						break;
					}
				}
				
			if (should)
			{
				[self willChangeAudio];
			
				// add to list
				mParameterExportedList[mParameterExportedCount++] = pid;
				[self reorderExportedList];
				
				[self didChangeConnections];
				[self didChangeAudio];
				[self didChangeGlobalView];
			}

		}

	}
}

- (void)tableView:(NSTableView *)aTableView willDisplayCell:(id)aCell forTableColumn:(NSTableColumn *)aTableColumn row:(int)rowIndex
{
	return;
	// doesn't work correctly...

	if (rowIndex < 0 || rowIndex >= mParameterCount) return;
	NSString *ident = [aTableColumn identifier];
	AudioUnitParameterID pid = mParameterList[rowIndex];
	
	if ([ident isEqual:@"value"])
	{
		NSCell *cell = nil;
		
		AudioUnitParameterInfo pinfo; memset(&pinfo, 0, sizeof(pinfo));
		UInt32 size = sizeof(pinfo);
		ComponentResult err = AudioUnitGetProperty(	mAudioUnit,
													kAudioUnitProperty_ParameterInfo,
													kAudioUnitScope_Global,
													pid,
													&pinfo,
													&size);
		if (err == noErr)
		{
			if (pinfo.unit == kAudioUnitParameterUnit_Boolean)
				cell = [[[NSButtonCell alloc] init] autorelease];
			
			if (pinfo.unit == kAudioUnitParameterUnit_Indexed)
			{
				NSPopUpButtonCell *pcell = [[[NSPopUpButtonCell alloc] init] autorelease]; cell = pcell;
				[pcell removeAllItems];

				NSArray *a = nil;
				size = sizeof(NSArray *);
				err = AudioUnitGetProperty(	mAudioUnit,
												kAudioUnitProperty_ParameterValueStrings,
												kAudioUnitScope_Global,
												pid, &a, &size);
											
				if (err == noErr && a)
				{
					[pcell addItemsWithTitles:a];
					[a release];
				}
			}
			
			if (!cell)
			{
				NSSliderCell *scell = [[[NSSliderCell alloc] init] autorelease]; cell = scell;
				[scell setMinValue:pinfo.minValue];
				[scell setMaxValue:pinfo.maxValue];
			}
		}
			
		if (!cell)
			cell = [[[NSTextFieldCell alloc] init] autorelease];
			
		[aTableColumn setDataCell:cell];
	}
}

- (SBCell*) createCell
{
	SBBooleanCell *cell = [[SBBooleanCell alloc] init];
	if (cell) [cell setArgument:self parameter:0];
	return cell;
}

- (void) takeValue:(double)preset offsetToChange:(int)offset forParameter:(int)i
{
	[self showAuGui:nil];
}

#ifdef MIDI_STUFF

- (void) handleMidiEvent:(int)status channel:(int)channel data1:(int)data1 data2:(int)data2 offsetToChange:(int)offsetToChange
{
	if (!mAudioUnit) return;
	if (mChannel < 0) return;

	if (!mChannel || (mChannel - 1 == channel))
	{
		MusicDeviceMIDIEvent( (MusicDeviceComponent)  mAudioUnit,
								status, data1, data2, offsetToChange );
	}
}

// disable any gui
/*
- (void) drawContent
{
	if (mGuiMode != kCircuitDesign) return;
	[super drawContent];
}

- (BOOL) hitTestX:(int)x Y:(int)y
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super hitTestX:x Y:y];
}

- (BOOL) mouseDownX:(int)x Y:(int)y clickCount:(int)clickCount
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseDownX:x Y:y clickCount:clickCount];
}

- (BOOL) mouseDraggedX:(int)x Y:(int)y lastX:(int)lx lastY:(int)ly
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseDraggedX:x Y:y lastX:lx lastY:ly];
}

- (BOOL) mouseUpX:(int)x Y:(int)y
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super mouseUpX:x Y:y];
}

- (BOOL) keyDown:(unichar)ukey
{
	if (mGuiMode != kCircuitDesign) return NO;
	return [super keyDown:ukey];
}
*/
#endif

@end

#endif


