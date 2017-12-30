/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include <AudioUnit/AudioUnitCarbonView.h>

//------------------------------------------------------------------------------------------
class CLASS_NAME : public SUPER_CLASS_NAME , public SBListenerCpp
{
public:
	CLASS_NAME (AudioUnit component, SBPassedData *passedData);
	virtual ~ CLASS_NAME ();
	
	virtual void PostConstructor();


	virtual ComponentResult GetParameterInfo(AudioUnitScope inScope, 
												AudioUnitParameterID inParameterID, 
												AudioUnitParameterInfo & outParameterInfo);
	virtual ComponentResult SetParameter(AudioUnitParameterID inID, AudioUnitScope inScope,
											AudioUnitElement inElement,
											Float32 inValue,
											UInt32 inBufferOffsetInFrames);
											
	virtual	ComponentResult GetParameterValueStrings(AudioUnitScope inScope,
														AudioUnitParameterID inParameterID,
														CFArrayRef *outStrings);
														
	virtual ComponentResult GetPropertyInfo(AudioUnitPropertyID inID,
												AudioUnitScope inScope,
												AudioUnitElement inElement,
												UInt32 &outDataSize,
												Boolean	&outWritable );

	virtual ComponentResult GetProperty(AudioUnitPropertyID inID,
											AudioUnitScope inScope,
											AudioUnitElement inElement,
											void *outData);

	virtual UInt32 SupportedNumChannels(const AUChannelInfo ** outInfo);
	virtual ComponentResult	Version() {	return kCurrentVersion;	}

	virtual ComponentResult Initialize();
	virtual ComponentResult Reset(AudioUnitScope inScope, AudioUnitElement inElement);
	virtual OSStatus ProcessBufferLists( AudioUnitRenderActionFlags & ioActionFlags,
											const AudioBufferList & inBuffer,
											AudioBufferList & outBuffer,
											UInt32 inFramesToProcess );
											
    virtual Float64				GetLatency()
								{ return	(mLatency/1000.) +
											((mSampleRate > 0) ? (mLatencySamples / (double)mSampleRate) : 0); } // in seconds
    virtual Float64				GetTailTime() { return mTailTime/1000.; }
	virtual	bool				SupportsTail () { return true; }
	
	virtual SBRootCircuit*		CreateCircuit();
	virtual void				MaintainCircuits();
	
	virtual ComponentResult		SaveState( CFPropertyListRef * outData);
	virtual ComponentResult		RestoreState( CFPropertyListRef	inData);
	virtual ComponentResult		GetPresets (CFArrayRef * outData) const;
	virtual OSStatus			NewFactoryPresetSet (const AUPreset & inNewFactoryPreset);
	
	virtual void				beginGesture(SBArgument *a, int i);
	virtual void				parameterUpdated(SBArgument *a, int i);
	virtual void				endGesture(SBArgument *a, int i);
	
#ifdef USES_MIDI
	virtual OSStatus	HandleMidiEvent(UInt8 inStatus,
										UInt8 inChannel,
										UInt8 inData1,
										UInt8 inData2,
										UInt32 inStartFrame);
#endif
#ifdef MUSIC_DEVICE
	//using SUPER_CLASS_NAME::HandleNoteOn;
	
	/*
	virtual OSStatus			HandleNoteOn(	UInt8 	inChannel,
												UInt8 	inNoteNumber,
												UInt8 	inVelocity,
												UInt32 	inStartFrame)
								{ return SUPER_CLASS_NAME::HandleNoteOn(inChannel, inNoteNumber, inVelocity, inStartFrame); }
	*/

	virtual ComponentResult		PrepareInstrument(MusicDeviceInstrumentID inInstrument) { return noErr; }

	virtual ComponentResult		ReleaseInstrument(MusicDeviceInstrumentID inInstrument) { return noErr; }


	

	virtual ComponentResult		StartNote(		MusicDeviceInstrumentID 	inInstrument, 
												MusicDeviceGroupID 			inGroupID, 
												NoteInstanceID *			outNoteInstanceID, 
												UInt32 						inOffsetSampleFrame, 
												const MusicDeviceNoteParams &inParams) 
										{ return noErr; }

	virtual ComponentResult		StartNote(		MusicDeviceInstrumentID 	inInstrument, 
												MusicDeviceGroupID 			inGroupID, 
												NoteInstanceID 				&outNoteInstanceID, 
												UInt32 						inOffsetSampleFrame, 
												const MusicDeviceNoteParams &inParams) { return noErr; }

	virtual ComponentResult		StopNote(		MusicDeviceGroupID 			inGroupID, 
												NoteInstanceID 				inNoteInstanceID, 
												UInt32 						inOffsetSampleFrame) { return noErr; }
												
	virtual bool StreamFormatWritable(AudioUnitScope scope, AudioUnitElement element)
										{ return IsInitialized() ? false : true; }
										
	virtual ComponentResult Render(AudioUnitRenderActionFlags & ioActionFlags, 
									const AudioTimeStamp & inTimeStamp,
									UInt32 inFramesToProcess);
									
	virtual bool ValidFormat(AudioUnitScope inScope,
								AudioUnitElement inElement,
								const CAStreamBasicDescription &inNewFormat);
#else
	virtual ComponentResult 	Render(AudioUnitRenderActionFlags &		ioActionFlags,
										const AudioTimeStamp &			inTimeStamp,
										UInt32							inNumberFrames);
#endif


	virtual int		GetNumCustomUIComponents () { return (mHasGui) ? 1 : 0; }
	
	virtual void	GetUIComponentDescs (ComponentDescription* inDescArray)
	{
		if (inDescArray)
		{
			memset(inDescArray, 0, sizeof(ComponentDescription));
			if (!mHasGui) return;
			
			ComponentDescription desc;
			OSStatus err = GetComponentInfo((Component)GetComponentInstance(), &desc, NULL, NULL, NULL);
			if (err) return;
		
			inDescArray[0].componentType = kAudioUnitCarbonViewComponentType;
			inDescArray[0].componentSubType = desc.componentSubType;
			inDescArray[0].componentManufacturer = desc.componentManufacturer;
			inDescArray[0].componentFlags = 0;
			inDescArray[0].componentFlagsMask = 0;
		}
	}

private:
	BOOL					mHostIsPlogue;

	BOOL						mSingleCircuit;
	std::vector<SBRootCircuit*>	mCircuits;
	
	AUChannelInfo			mChannelInfo;
	SBBuffer				mBuffers[kMaxChannels];
	int						mBuffersCount;
	int						mCalculatingOffset;
	int						mSampleRate;
	int						mMinFeedbackTime;
	bool					mHasFeedback;
	double					mLatency, mLatencySamples;
	double					mTailTime;
	pthread_mutex_t			*mMutex;
	AUPreset				*mPresets;
	NSData					*mDefaultPreset;
	int						mPresetsCount;
	int						mNumParameters;
	std::vector<int>		mArgumentMap;
	std::vector<int>		mSubArgumentMap;
	SBListenerObjc			*mListener;
	std::map<SBArgument*, int>	mArgumentReverseMap;
	bool					mHasGui;
	bool					mHasSideChain;
	bool					mNeedsTempo;
	
	float					*mSilence;
	
	SBPassedData			*mPassedData;
	
	void	guiLock();
	void	guiUnlock();
	void	guiResync();
};
