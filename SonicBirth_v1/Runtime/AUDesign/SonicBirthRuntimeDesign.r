
#include "FrameworkSettings.h"

#define RES_ID			10000
#define COMP_TYPE		kAudioUnitType_Effect
#define COMP_SUBTYPE	'S_d1'
#define COMP_MANUF		'ScBh'
#define VERSION			kCurrentVersion
#define NAME			"SonicBirth: Effect design"
#define DESCRIPTION		"In host plugin SonicBirth design"
#define ENTRY_POINT		"SonicBirthRuntimeDesignEffectEntry"

#include "ExportResources.r"

#define RES_ID			10010
#define COMP_TYPE		kAudioUnitType_MusicEffect
#define COMP_SUBTYPE	'S_d2'
#define COMP_MANUF		'ScBh'
#define VERSION			kCurrentVersion
#define NAME			"SonicBirth: Music effect design"
#define DESCRIPTION		"In host plugin SonicBirth design"
#define ENTRY_POINT		"SonicBirthRuntimeDesignMidiEffectEntry"

#include "ExportResources.r"

#define RES_ID			10020
#define COMP_TYPE		kAudioUnitType_MusicDevice
#define COMP_SUBTYPE	'S_d3'
#define COMP_MANUF		'ScBh'
#define VERSION			kCurrentVersion
#define NAME			"SonicBirth: Music device design"
#define DESCRIPTION		"In host plugin SonicBirth design"
#define ENTRY_POINT		"SonicBirthRuntimeDesignMusicDeviceEntry"

#include "ExportResources.r"

