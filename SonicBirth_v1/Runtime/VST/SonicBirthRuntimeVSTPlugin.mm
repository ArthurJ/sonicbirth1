/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include "FillBuffer.h"
#include "SBPluginCreation.h"

//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
extern "C" AEffect *VSTPluginMain (audioMasterCallback audioMaster);
extern "C" AEffect *VSTPluginMain (audioMasterCallback audioMaster)
{
//	fprintf(stderr, "SonicBirth: VSTPluginMain called\n");
	return vstCreate(audioMaster, (SBPassedData*)gFillBuffer);
}


//-------------------------------------------------------------------------------------------------------
//-------------------------------------------------------------------------------------------------------
extern "C" AEffect *main_macho (audioMasterCallback audioMaster);
extern "C" AEffect *main_macho (audioMasterCallback audioMaster)
{
//	fprintf(stderr, "SonicBirth: main_macho called\n");
	return vstCreate(audioMaster, (SBPassedData*)gFillBuffer);
}
