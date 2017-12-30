/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef SONICBIRTHRUNTIME_H
#define SONICBIRTHRUNTIME_H

#include "CAStreamBasicDescription.h"
#include "AUEffectBase.h"
#include "AUMIDIEffectBase.h"
#include "MusicDeviceBase.h"

#import "SBRootCircuit.h"
#import "SBArgument.h"
#import "SBSlider.h"
#import "SBBoolean.h"
#import "SBIndexed.h"

#import "SBElementServer.h"

#import "FrameworkVersion.h"

#include <pthread.h>
#include <vector>

//#define DO_LOG_STUFF 
#ifndef DO_LOG_STUFF
#define LOG(args...)
#else
#define LOG(args...) \
	{ \
		struct timeval tp; memset(&tp, 0, sizeof(tp)); \
		gettimeofday(&tp, 0); \
		fprintf(stderr, "SonicBirth (%f): ", (tp.tv_sec + (tp.tv_usec / 1000000.))); \
		fprintf(stderr, args); \
	}
#warning "au logging enabled."
#endif

#import "SBListener.h"

#include <AudioToolbox/AudioUnitUtilities.h>	// for AUEventListenerNotify

// -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
#define SUPER_CLASS_NAME AUEffectBase
#define CLASS_NAME SonicBirthRuntimeEffect
	#include "SonicBirthRuntimeInternal.h"
#undef SUPER_CLASS_NAME
#undef CLASS_NAME

#define USES_MIDI

#define SUPER_CLASS_NAME AUMIDIEffectBase
#define CLASS_NAME SonicBirthRuntimeMidiEffect
	#include "SonicBirthRuntimeInternal.h"
#undef SUPER_CLASS_NAME
#undef CLASS_NAME

#define MUSIC_DEVICE

#define SUPER_CLASS_NAME MusicDeviceBase
#define CLASS_NAME SonicBirthRuntimeMusicDevice
	#include "SonicBirthRuntimeInternal.h"
#undef SUPER_CLASS_NAME
#undef CLASS_NAME

#undef USES_MIDI
#undef MUSIC_DEVICE
// -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

#endif /* SONICBIRTHRUNTIME_H */

