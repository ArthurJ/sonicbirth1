/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef SONICBIRTHRUNTIMEVIEWVST_H
#define SONICBIRTHRUNTIMEVIEWVST_H

//#include "vstplugsmacho.h"

//#include "aeffeditor.h"
#include "SonicBirthRuntimeVST.h"
#include <Cocoa/Cocoa.h>
#include <AGL/agl.h>
#import <Carbon/Carbon.h>
#import "SBListenerCarbon.h"

@class SBRuntimeView;

namespace Steinberg {
namespace Vst {

class SBVSTView : public EditController
{
public:
	SBVSTView (SBVST *effect);
	virtual ~SBVSTView();
	
	virtual IPlugView* PLUGIN_API createView (FIDString /*name*/);
	
private:
	SBVST *mEffect;
};

class SBVSTView_l2 : public EditorView
{
	virtual tresult PLUGIN_API attached (void* parent, FIDString type);
	virtual tresult PLUGIN_API removed ();
};

} // namespace Vst
} // namespace Steinberg

#endif /* SONICBIRTHRUNTIMEVIEWVST_H */
