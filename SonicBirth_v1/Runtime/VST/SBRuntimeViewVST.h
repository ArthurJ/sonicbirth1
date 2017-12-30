/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef SONICBIRTHRUNTIMEVIEWVST_H
#define SONICBIRTHRUNTIMEVIEWVST_H

//#include "vstplugsmacho.h"

#include "aeffeditor.h"
#include "SonicBirthRuntimeVST.h"
#include <Cocoa/Cocoa.h>
#include <AGL/agl.h>
#import <Carbon/Carbon.h>
#import "SBListenerCarbon.h"

@class SBRuntimeView;

class SBVSTView : public AEffEditor
{
public:

	SBVSTView (SBVST *effect);
	virtual ~SBVSTView();
	
	virtual bool open (void *ptr);
	virtual void close ();
	
	virtual bool getRect (ERect **rect);

public:
	SBVST				*mEffect;
	ERect				mRect;
	ogWrap				*mW;
	AGLContext			mAgl;
	ControlRef			mControl;
	WindowRef			mWindow;
	SBListenerCarbon	*mListener;
	int					mX, mY, mWidth, mHeight, mLock;
};

#endif /* SONICBIRTHRUNTIMEVIEWVST_H */
