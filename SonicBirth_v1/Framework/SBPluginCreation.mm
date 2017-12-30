/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include "SBPluginCreation.h"

// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
// vst
#include "SonicBirthRuntimeVST.h"
AEffect *vstCreate(audioMasterCallback audioMaster, SBPassedData *fillBuffer)
{
	frameworkInit(1);
	
	if (!audioMaster)
		return nil;

	// Get VST Version
	if (!audioMaster (0, audioMasterVersion, 0, 0, 0, 0))
		return nil;  // old version

	// Create the AudioEffect
	SBVST* effect = NULL;
	
	try { effect = new SBVST(audioMaster, fillBuffer); }
	catch(...) { return NULL; }
	
	if (!effect) return NULL;

	return effect->getAeffect();
}



// * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * 
// au
#include "SonicBirthRuntime.h"
#include "SBRuntimeViewCarbon.h"


	/*! @class ComponentEntryPoint */
template <class Class>
class SBComponentEntryPoint {
public:
	/*! @method Dispatch */
	static ComponentResult Dispatch(ComponentParameters *params, Class *obj, SBPassedData *fillBuffer)
	{
		ComponentResult result = noErr;
		
		try {
			if (params->what == kComponentOpenSelect) {
#if SUPPORT_AU_VERSION_1
				// solve a host of initialization thread safety issues.
				ComponentInitLocker lock;
#endif
				ComponentInstance ci = (ComponentInstance)(params->params[0]);
				Class *This = new Class(ci, fillBuffer);
				This->PostConstructor();	// allows base class to do additional initialization
											// once the derived class is fully constructed
				
				SetComponentInstanceStorage(ci, (Handle)This);
			} else
				result = Class::ComponentEntryDispatch(params, obj);
		}
		COMPONENT_CATCH
		
		return result;
	}
	
	/*! @method Register */
	static Component Register(OSType compType, OSType subType, OSType manufacturer)
	{
		ComponentDescription	description = {compType, subType, manufacturer, 0, 0};
		Component	component = RegisterComponent(&description, (ComponentRoutineUPP) Dispatch, registerComponentGlobal, NULL, NULL, NULL);
		if (component != NULL) {
			SetDefaultComponent(component, defaultComponentAnyFlagsAnyManufacturerAnySubType);
		}
		return component;
	}
};

ComponentResult SBRuntimeEffectPluginEntry(ComponentParameters *params, void *obj, SBPassedData *fillBuffer)
{
	return SBComponentEntryPoint<SonicBirthRuntimeEffect>::Dispatch(params, (SonicBirthRuntimeEffect*)obj, fillBuffer);
}

ComponentResult SBRuntimeMidiEffectPluginEntry(ComponentParameters *params, void *obj, SBPassedData *fillBuffer)
{
	return SBComponentEntryPoint<SonicBirthRuntimeMidiEffect>::Dispatch(params, (SonicBirthRuntimeMidiEffect*)obj, fillBuffer);
}

ComponentResult SBRuntimeMusicDevicePluginEntry(ComponentParameters *params, void *obj, SBPassedData *fillBuffer)
{
	return SBComponentEntryPoint<SonicBirthRuntimeMusicDevice>::Dispatch(params, (SonicBirthRuntimeMusicDevice*)obj, fillBuffer);
}

ComponentResult SBRuntimeCarbonViewEntry(ComponentParameters *params, void *obj)
{
	return -1;
	//return ComponentEntryPoint<SBRuntimeViewCarbon>::Dispatch(params, (SBRuntimeViewCarbon*)obj);
}



