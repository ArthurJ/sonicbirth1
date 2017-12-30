/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#if 0

#include <Carbon/Carbon.h>
#include <AGL/agl.h>

#include "AUCarbonViewBase.h"
#import "SBListenerCarbon.h"
#import "SBRootCircuit.h"

class SBRuntimeViewCarbon : public AUCarbonViewBase
{

public:
	SBRuntimeViewCarbon(AudioUnitCarbonView auv);
	virtual ~SBRuntimeViewCarbon();
	
	// Overqualified -- reformatted below
	
//	virtual ComponentResult	SBRuntimeViewCarbon::CreateCarbonView(AudioUnit inAudioUnit,
//																	WindowRef inWindow,
//																	ControlRef inParentControl,
//																	const Float32Point &inLocation,
//																	const Float32Point &inSize,
//																	ControlRef &outParentControl);

	virtual ComponentResult	CreateCarbonView(AudioUnit inAudioUnit,
											  WindowRef inWindow,
											  ControlRef inParentControl,
											  const Float32Point &inLocation,
											  const Float32Point &inSize,
											  ControlRef &outParentControl);
	
	virtual void WantEventTypes(EventTargetRef target, UInt32 inNumTypes, const EventTypeSpec *inList)
	{
		// disables AUCarbonViewBase event handlers
	}
	
	virtual void postRedisplay()
	{
		if (mCompositWindow && mCarbonPane)
		{
			HIViewSetNeedsDisplay(mCarbonPane, YES);
		}
		else if (mCarbonWindow)
		{
		#if 0
			Rect windowBounds;
			GetWindowPortBounds(mCarbonWindow, &windowBounds);
			InvalWindowRect(mCarbonWindow, &windowBounds);	
		#endif
		}
	}

public:
	ogWrap				*mW;
	AGLContext			mAgl;
	WindowRef			mWindow;
	SBListenerCarbon	*mListener;
	SBRootCircuit		*mCircuit;
	int					mX, mY, mWidth, mHeight, mLock;
};

#endif


