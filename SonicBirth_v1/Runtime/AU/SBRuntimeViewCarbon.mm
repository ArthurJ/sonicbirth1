/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#if 0

#include "SBRuntimeViewCarbon.h"
#import <AudioUnit/AudioUnit.h>

static pascal OSStatus SBEventHandler(EventHandlerCallRef nextHandler, 
										EventRef theEvent, 
										void* userData)
{
    OSStatus result = eventNotHandledErr;

	SBRuntimeViewCarbon *view = (SBRuntimeViewCarbon *)userData;
	SBRootCircuit *circuit = view->mCircuit;
	WindowRef window = view->mWindow;
	NSRect r = { {0,0}, { view->mWidth, view->mHeight } };
	Rect wr = { view->mY, view->mX, view->mY + view->mHeight, view->mX + view->mWidth };
	
	UInt32 clas = GetEventClass (theEvent); 
	UInt32 kind = GetEventKind (theEvent);
	
/*
	if (clas == kEventClassWindow || clas == kEventClassMouse)
	{
		WindowRef w = NULL;
		GetEventParameter(theEvent, kEventParamDirectObject, typeWindowRef, NULL, sizeof(WindowRef), NULL, &w);
		printf("window: %p\n", (void*)w);
		if (clas == kEventClassWindow && kind == kEventWindowUpdate)
		{
			printf("window update\n");
			return CallNextEventHandler(nextHandler, theEvent);
		}
	}
*/
	
	static float lastX = 0, lastY = 0;
	
	//printf("SBEventHandler: %.4s %i\n", (char*)&clas, (int)kind);
	
	switch (clas)
	{
		case kEventClassControl:
			switch (kind)
			{
				case kEventControlDraw:
				
					if (!view->mAgl) break;

					aglSetCurrentContext(view->mAgl);
					
					if (!view->mW) view->mW = ogInit();
					ogBeginDrawing(view->mW);
					
					ogSetShape(0, 0, view->mWidth, view->mHeight);
					
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					ogClearBuffer();
					[circuit drawRect:r];
					ogEndDrawing(1);
					
					//printf("kEventControlDraw\n");
					//#warning "remove printf"
					
					bool constantRefresh = [circuit constantRefresh];
//					printf("constantRefresh = %s, mListener = %p\n", constantRefresh ? "yes" : "no", view->mListener);
					if (constantRefresh && view->mListener)
						[view->mListener delayedRefresh];
						
					if (pool) { [pool release]; pool = nil; }
					
					result = noErr;
					break;
			}
			break;
			
		case kEventClassMouse:
			{
				HIPoint pt;
				
				GetEventParameter(theEvent, kEventParamWindowMouseLocation,
								typeHIPoint, NULL, sizeof(HIPoint), NULL, &pt);
				
				// offset for window bar
				Rect titleBounds;
				GetWindowBounds(window, kWindowTitleBarRgn, &titleBounds);
				
				//printf("t ff: %i %i %i %i\n",
				//					(int)titleBounds.left,
				//					(int)titleBounds.top,
				//					(int)titleBounds.right,
				//					(int)titleBounds.bottom);

				pt.y -= (titleBounds.bottom - titleBounds.top);
			
				switch (kind)
				{
					case kEventMouseDown:
						{				
							if (pt.x < wr.left || pt.x > wr.right || pt.y < wr.top || pt.y > wr.bottom)
							{
								view->mLock = 0;
								return CallNextEventHandler(nextHandler, theEvent);
							}
							
							view->mLock = 1;
							
							UInt32 clickCount;
							GetEventParameter(theEvent, kEventParamClickCount,
												typeUInt32, NULL, sizeof(UInt32), NULL, &clickCount);
												
							pt.x -= wr.left; pt.y -= wr.top;
												
							//printf("md x: %i y: %i\n", (int)pt.x, (int)pt.y);
							NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
							bool ok = [circuit mouseDownX:(int)pt.x Y:(int)pt.y clickCount:clickCount];
							if (ok)
							{
								view->postRedisplay();
							}
											
							// set our window as focused
							if ([circuit selectedElement])
								SetUserFocusWindow(window);
								
							if (pool) { [pool release]; pool = nil; }

							lastX = pt.x;
							lastY = pt.y;

							result = noErr;
						}
						break;
						
					case kEventMouseDragged:
						{
							if (!view->mLock) return CallNextEventHandler(nextHandler, theEvent);
												
							pt.x -= wr.left; pt.y -= wr.top;
												
							NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
							bool ok = [circuit mouseDraggedX:(int)pt.x Y:(int)pt.y lastX:(int)lastX lastY:(int)lastY];
							if (ok)
							{
								view->postRedisplay();
							}
							if (pool) { [pool release]; pool = nil; }
							
							lastX = pt.x;
							lastY = pt.y;

							result = noErr;
						}
						break;
						
					case kEventMouseUp:
						{
							if (!view->mLock) return CallNextEventHandler(nextHandler, theEvent);
												
							pt.x -= wr.left; pt.y -= wr.top;
												
							NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
							bool ok = [circuit mouseUpX:(int)pt.x Y:(int)pt.y];
							if (ok)
							{
								view->postRedisplay();
							}
							if (pool) { [pool release]; pool = nil; }

							result = noErr;
						}
						break;
				
				}
			}
			break;
			
		case kEventClassKeyboard:
			switch (kind)
			{
				case kEventRawKeyDown:
				case kEventRawKeyRepeat:
					{
						if (!view->mLock) return CallNextEventHandler(nextHandler, theEvent);
						
						if (IsUserCancelEventRef(theEvent))
						{
							view->mLock = 0;
							SetUserFocusWindow(kUserFocusAuto);
							return CallNextEventHandler(nextHandler, theEvent);
						}
					
						//UInt32 keyCode = 0;
						//GetEventParameter(inEvent, kEventParamKeyCode, typeUInt32, NULL, sizeof(keyCode), NULL, &keyCode);
						
						char key = 0;
						GetEventParameter(theEvent, kEventParamKeyMacCharCodes, typeChar, NULL, sizeof(char), NULL, &key);
						
						unichar ukey = key;
						switch(ukey)
						{
							case 0x1C: ukey = NSLeftArrowFunctionKey; break; // 0xF702
							case 0x1D: ukey = NSRightArrowFunctionKey; break; // 0xF703
							case 0x8: ukey = 0x7F; break; // delete left
							case 0x7F: ukey = NSDeleteFunctionKey; break; // 0xF728
						}
						
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						BOOL ok = [circuit keyDown:ukey];
						if (ok)
						{
							view->postRedisplay();
						}
						else CallNextEventHandler(nextHandler, theEvent);
						if (pool) { [pool release]; pool = nil; }
						
						result = noErr;
					}
					break;
			}
			break;

	}
	
    return result;
}

SBRuntimeViewCarbon::SBRuntimeViewCarbon(AudioUnitCarbonView auv) : AUCarbonViewBase(auv) 
{ 
	mListener = nil;
	mAgl = nil;
	mWindow = nil;
	mW = nil;
	mCircuit = nil;
}

ComponentResult	SBRuntimeViewCarbon::CreateCarbonView(AudioUnit inAudioUnit,
														WindowRef inWindow,
														ControlRef inParentControl,
														const Float32Point &inLocation,
														const Float32Point &inSize,
														ControlRef &outParentControl)
{
	//printf("CreateCarbonView w: %p\n", inWindow);
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	// in case this gets called twice
	if (mListener) [mListener release];
	ogRelease(mW);
	if (mAgl) aglDestroyContext(mAgl);
	
	mListener = nil;
	mAgl = nil;
	mWindow = nil;
	mW = nil;
	mCircuit = nil;

	// get the main circuit
	SBRootCircuit *circuit;
	UInt32 size = sizeof(SBRootCircuit*);
	AudioUnitGetProperty(inAudioUnit, kCircuitID, kAudioUnitScope_Global, 0, &circuit, &size);
	assert(circuit);
	
	mCircuit = circuit;
	mListener = [[SBListenerCarbon alloc] initWithCircuit:circuit];
	
	NSSize csize = [circuit circuitMinSize];
	mWidth = (int)csize.width;
	mHeight = (int)csize.height;
	
	[circuit setGuiMode:kRuntime];
	[circuit setActsAsCircuit:YES];
	[circuit setCircuitSize:csize];
	
	if (pool) { [pool release]; pool = nil; }
	
	// the host will want a controlRef
	// create a dummy user pane
	// let the super class have fun
	
	ComponentResult err = AUCarbonViewBase::CreateCarbonView(inAudioUnit, inWindow, inParentControl, inLocation, inSize, outParentControl);
	if (err) return err;
	
	SizeControl(mCarbonPane, mWidth, mHeight);
	
	//printf("composite: %i\n", (int)IsCompositWindow());
	
	mWindow = inWindow;
	mX = (int)mXOffset;
	mY = (int)mYOffset; 
	
	if (!mAgl)
	{
		GLint attr[] = { AGL_RGBA, AGL_NONE };
		AGLPixelFormat pf = aglChoosePixelFormat(nil, 0, attr);
		if (!pf)
		{
			printf("bad pixel format\n");
			return -1;
		}
		
		mAgl = aglCreateContext(pf, nil);
		aglDestroyPixelFormat(pf);
		if (!mAgl)
		{
			printf("cant create context\n");
			return -1;
		}
	}
	
	GLboolean ok = aglSetDrawable(mAgl, GetWindowPort(mWindow));
	if (!ok)
	{
		printf("cant set drawable\n");
		return -1;
	}
	
	Rect bounds ;
    GetWindowPortBounds(mWindow, &bounds);
	
	GLint bufferRect[4] = 
	{
		mX,
		(bounds.bottom - bounds.top) - ( mY + mHeight ),
		mWidth,
		mHeight
	};
	
	//printf("coords: %i %i %i %i\n", mX, mY, mWidth, mHeight);
	
	ok = aglSetInteger(mAgl, AGL_BUFFER_RECT, bufferRect);
	if (!ok)
	{
		printf("cant set buffer rect\n");
		return -1;
	}
	
	ok = aglEnable(mAgl, AGL_BUFFER_RECT);
	if (!ok)
	{
		printf("cant enable buffer rect\n");
		return -1;
	}
	
	ok = aglUpdateContext(mAgl);
	if (!ok)
	{
		printf("cant update context\n");
		return -1;
	}
	
	if (mListener)
	{
		WindowAttributes attributes;
		GetWindowAttributes(mWindow, &attributes);
		
		if (attributes & kWindowCompositingAttribute)
			[mListener setControl:mCarbonPane];
		else
			[mListener setWindow:mWindow];
			
		[mListener delayedRefresh];
	}
	
	EventTypeSpec eventList[] = {
									{ kEventClassControl, kEventControlDraw }
								};  
								 
	EventHandlerUPP handler = NewEventHandlerUPP(SBEventHandler);
	InstallControlEventHandler(mCarbonPane,
								handler,
								GetEventTypeCount(eventList),
								eventList, this, NULL);
	
	EventTypeSpec eventList2[] = {
									{ kEventClassMouse, kEventMouseDown },
									{ kEventClassMouse, kEventMouseDragged },
									{ kEventClassMouse, kEventMouseUp },
									{ kEventClassKeyboard, kEventRawKeyDown }, 
									{ kEventClassKeyboard, kEventRawKeyRepeat }
								};  

	InstallWindowEventHandler(mWindow,
								handler,
								GetEventTypeCount(eventList2),
								eventList2, this, NULL);
	
	return 0;
}


SBRuntimeViewCarbon::~SBRuntimeViewCarbon()
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (mListener) [mListener release];
	if (pool) { [pool release]; pool = nil; }
	ogRelease(mW);
	if (mAgl) aglDestroyContext(mAgl);
}

#endif

