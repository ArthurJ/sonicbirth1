
#include <AudioUnit/AudioUnit.r>

#define RES_ID			10000
#define COMP_TYPE		kAudioUnitType_Effect
#define COMP_SUBTYPE	'Test'
#define COMP_MANUF		'ScBh'
#define VERSION			0x00010000
#define NAME			"SonicBirth: SuperHuperReverb"
#define DESCRIPTION		"SonicBirth's test audio effect"
#define ENTRY_POINT		"SonicBirthRuntimeEntry"

#include "AUResources.r"
