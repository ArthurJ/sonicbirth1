/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include "FillBuffer.h"
#include "SBPluginCreation.h"

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
extern "C" ComponentResult SonicBirthRuntimeEffectPluginEntry(ComponentParameters *params, void *obj);
extern "C" ComponentResult SonicBirthRuntimeEffectPluginEntry(ComponentParameters *params, void *obj)
{
	ComponentResult r = SBRuntimeEffectPluginEntry(params, obj, (SBPassedData*)gFillBuffer);
	//fprintf(stderr, "SonicBirthRuntimeEffectPluginEntry params %p what %d -> %d\n", params, params ? params->what : -1, r);
	return r;
}

extern "C" ComponentResult SonicBirthRuntimeMidiEffectPluginEntry(ComponentParameters *params, void *obj);
extern "C" ComponentResult SonicBirthRuntimeMidiEffectPluginEntry(ComponentParameters *params, void *obj)
{
	//fprintf(stderr, "SonicBirthRuntimeMidiEffectPluginEntry\n");
	return SBRuntimeMidiEffectPluginEntry(params, obj, (SBPassedData*)gFillBuffer);
}

extern "C" ComponentResult SonicBirthRuntimeMusicDevicePluginEntry(ComponentParameters *params, void *obj);
extern "C" ComponentResult SonicBirthRuntimeMusicDevicePluginEntry(ComponentParameters *params, void *obj)
{
	//fprintf(stderr, "SonicBirthRuntimeMusicDevicePluginEntry\n");
	return SBRuntimeMusicDevicePluginEntry(params, obj, (SBPassedData*)gFillBuffer);
}

extern "C" ComponentResult SonicBirthRuntimeCarbonViewEntry(ComponentParameters *params, void *obj);
extern "C" ComponentResult SonicBirthRuntimeCarbonViewEntry(ComponentParameters *params, void *obj)
{
	//fprintf(stderr, "SonicBirthRuntimeCarbonViewEntry\n");
	return SBRuntimeCarbonViewEntry(params, obj);
}
