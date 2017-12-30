/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


#ifndef SBPLUGINCREATION_H
#define SBPLUGINCREATION_H

#include "ComponentBase.h"



#ifdef __cplusplus
#include "AEffect.h"
extern "C" {
#else
typedef struct AEffect AEffect;

#endif

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
// vst
//#include "vstplugsmacho.h"
AEffect *vstCreate(audioMasterCallback audioMaster, SBPassedData *fillBuffer);


// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
// au
ComponentResult SBRuntimeEffectPluginEntry(ComponentParameters *params, void *obj, SBPassedData *fillBuffer);
ComponentResult SBRuntimeMidiEffectPluginEntry(ComponentParameters *params, void *obj, SBPassedData *fillBuffer);
ComponentResult SBRuntimeMusicDevicePluginEntry(ComponentParameters *params, void *obj, SBPassedData *fillBuffer);
ComponentResult SBRuntimeCarbonViewEntry(ComponentParameters *params, void *obj);

#ifdef __cplusplus
}
#endif


#endif /* SBPLUGINCREATION_H */