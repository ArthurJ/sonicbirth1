/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include <Carbon/Carbon.h>
#include "SBRuntimeViewVST.h"
#import "SBRuntimeView.h"
#import <OpenGL/OpenGL.h>
#import "SBRootCircuit.h"

//#define DO_LOG_STUFF 
#ifndef DO_LOG_STUFF
	#define LOG(args...)
#else
	#define LOG(args...) fprintf(stderr, "SonicBirthView: " args);
	#warning "vst logging enabled."
#endif

namespace Steinberg {
namespace Vst {

SBVSTView::SBVSTView (SBVST *effect)
:
	mEffect(effect)
{


}

SBVSTView::~SBVSTView()
{


}

IPlugView* SBVSTView::createView (FIDString /*name*/)
{
	return 0;
}
	
} // namespace Vst
} // namespace Steinberg

#if 0

//-----------------------------------------------------------------------------
/*
void SBVSTView::draw(ERect* rect)
{
	SBVSTView *view = this;
	SBRootCircuit *circuit = view->mEffect->mainCircuit();
	NSRect r = { {0,0}, { view->mWidth, view->mHeight } };
	
	if (!view->mAgl) return;

	aglSetCurrentContext(view->mAgl);
					
	if (!view->mW) view->mW = ogInit();
	ogBeginDrawing(view->mW);
					
	ogSetShape(0, 0, view->mWidth, view->mHeight);
				
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
	ogClearBuffer();
	[circuit drawRect:r];
	ogEndDrawing(1);
					
	bool constantRefresh = [circuit constantRefresh];
//	printf("constantRefresh = %s, mListener = %p\n", constantRefresh ? "yes" : "no", view->mListener);
	if (constantRefresh && view->mListener)
		[view->mListener delayedRefresh];
						
	if (pool) { [pool release]; pool = nil; }	
}
*/

//-----------------------------------------------------------------------------
static pascal OSStatus SBEventHandler(EventHandlerCallRef nextHandler, 
										EventRef theEvent, 
										void* userData)
{
    OSStatus result = eventNotHandledErr;
#if 0
	SBVSTView *view = (SBVSTView *)userData;
	SBRootCircuit *circuit = view->mEffect->mainCircuit();
	WindowRef window = view->mWindow;
	NSRect r = { {0,0}, { view->mWidth, view->mHeight } };
	Rect wr = { view->mY, view->mX, view->mY + view->mHeight, view->mX + view->mWidth };
	
	UInt32 clas = GetEventClass (theEvent); 
	UInt32 kind = GetEventKind (theEvent);
	
	static float lastX = 0, lastY = 0;
	
	LOG("SBEventHandler: %.4s %i\n", (char*)&clas, (int)kind);
	
	/*{
		HIRect r;
		HIViewGetBounds (view->mControl, &r);
		LOG("HIViewGetBounds: %f %f %f %f\n", r.origin.x, r.origin.y, r.size.width, r.size.height);
	}*/
	
	switch (clas)
	{
		case kEventClassControl:
		case kEventClassWindow:
			switch (kind)
			{
				case kEventControlDraw:
				case kEventWindowUpdate:
				
					if (!view->mAgl) break;

					aglSetCurrentContext(view->mAgl);
					
					if (!view->mW) view->mW = ogInit();
					ogBeginDrawing(view->mW);
					
					ogSetShape(0, 0, view->mWidth, view->mHeight);
					
					NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
					
					ogClearBuffer();
					[circuit drawRect:r];
					ogEndDrawing(1);
					
					bool constantRefresh = [circuit constantRefresh];
//					printf("constantRefresh = %s, mListener = %p\n", constantRefresh ? "yes" : "no", view->mListener);
					if (constantRefresh && view->mListener)
						[view->mListener delayedRefresh];
						
					if (pool) { [pool release]; pool = nil; }
					
					CallNextEventHandler(nextHandler, theEvent);
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
								[view->mListener update:nil];
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
								[view->mListener update:nil];
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
								[view->mListener update:nil];
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
						
						LOG("key down/repeat: 0x%X -> 0x%X\n", key, ukey); // 27 is esc
						
						
						NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
						BOOL ok = [circuit keyDown:ukey];
						if (ok)
						{
							[view->mListener update:nil];
						}
						else CallNextEventHandler(nextHandler, theEvent);
						if (pool) { [pool release]; pool = nil; }
						
						result = noErr;
					}
					break;
			}
			break;

	}
#endif
    return result;
}
	
//-----------------------------------------------------------------------------
bool SBVSTView::open(void *ptr)
{
	LOG("SBVSTView open (%p).\n", ptr);

#if 1
	return false;
#else
	if (!ptr) return false;
	
	AEffEditor::open(ptr);
	mWindow = (WindowRef)ptr;

	if (!mAgl)
	{
		GLint attr[] = { AGL_RGBA, AGL_NONE };
		AGLPixelFormat pf = aglChoosePixelFormat(nil, 0, attr);
		if (!pf)
		{
			printf("bad pixel format\n");
			return false;
		}
		
		mAgl = aglCreateContext(pf, nil);
		aglDestroyPixelFormat(pf);
		if (!mAgl)
		{
			printf("cant create context\n");
			return false;
		}
	}
	
	GLboolean ok = aglSetDrawable(mAgl, GetWindowPort(mWindow));
	if (!ok)
	{
		printf("cant set drawable\n");
		return false;
	}
	
	Rect bounds;
    GetWindowPortBounds(mWindow, &bounds);
	
	Rect contentBounds;
	GetWindowBounds (mWindow, kWindowContentRgn, &contentBounds);
	
	// this assumes any host controls are top/left...
	mX = (contentBounds.right - contentBounds.left) - mWidth; if (mX < 0) mX = 0;
	mY = (contentBounds.bottom - contentBounds.top) - mHeight; if (mY < 0) mY = 0;
	
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
		return false;
	}
	
	ok = aglEnable(mAgl, AGL_BUFFER_RECT);
	if (!ok)
	{
		printf("cant enable buffer rect\n");
		return false;
	}
	
	ok = aglUpdateContext(mAgl);
	if (!ok)
	{
		printf("cant update context\n");
		return false;
	}
	
	ControlRef contentView = nil;
	
	Rect area;
	area.left = short(0);
	area.top = short(0);
	area.right = short(area.left + mWidth);
	area.bottom = short(area.top + mHeight);
	OSStatus err = ::CreateUserPaneControl(mWindow, &area, kControlSupportsEmbedding, &contentView);
	if (err)
	{
		printf("CreateUserPaneControl err %i\n", (int)err);
		return false;
	}
	mControl = contentView;
	
	WindowAttributes attributes;
	GetWindowAttributes (mWindow, &attributes);
	if (attributes & kWindowCompositingAttribute) 
	{
		ControlRef mainContentView = nil;
		HIViewRef rootView = HIViewGetRoot(mWindow);
		if (HIViewFindByID(rootView, kHIViewWindowContentID, &mainContentView) != noErr)
			mainContentView = rootView;
			
		::HIViewAddSubview(mainContentView, contentView);
			
		LOG("kWindowCompositingAttribute is on (contentView %p)\n", contentView);
	}
	else
	{
		ControlRef rootControl;
		GetRootControl (mWindow, &rootControl);
		if (rootControl == NULL) CreateRootControl (mWindow, &rootControl);
	
		EmbedControl(contentView, rootControl);
	
		LOG("kWindowCompositingAttribute is off\n");
	}
	
	{
		HIRect r;
		HIViewGetBounds (contentView, &r);
	
		LOG("HIViewGetBounds: %f %f %f %f\n", r.origin.x, r.origin.y, r.size.width, r.size.height);
		
	}
				 			 
	EventHandlerUPP handler = NewEventHandlerUPP(SBEventHandler);
	if (contentView)
	{		
		EventTypeSpec eventList[] = {
										{ kEventClassControl, kEventControlDraw }
									};  
		OSStatus err = InstallControlEventHandler(contentView,
													handler,
													GetEventTypeCount(eventList),
													eventList, this, NULL);
		if (err)
		{
			printf("InstallControlEventHandler err %i\n", (int)err);
			return false;
		}
		
		EventTypeSpec eventList2[] = {
										{ kEventClassMouse, kEventMouseDown },
										{ kEventClassMouse, kEventMouseDragged },
										{ kEventClassMouse, kEventMouseUp },
										{ kEventClassKeyboard, kEventRawKeyDown }, 
										{ kEventClassKeyboard, kEventRawKeyRepeat }
									};  

		err = InstallWindowEventHandler(mWindow,
										handler,
										GetEventTypeCount(eventList2),
										eventList2, this, NULL);
		if (err)
		{
			printf("InstallWindowEventHandler err %i\n", (int)err);
			return false;
		}
	}
	else
	{
		EventTypeSpec eventList[] = {
										{ kEventClassWindow, kEventWindowUpdate },
										{ kEventClassMouse, kEventMouseDown },
										{ kEventClassMouse, kEventMouseDragged },
										{ kEventClassMouse, kEventMouseUp },
										{ kEventClassKeyboard, kEventRawKeyDown }, 
										{ kEventClassKeyboard, kEventRawKeyRepeat }
									};  

		OSStatus err = InstallWindowEventHandler(mWindow,
												handler,
												GetEventTypeCount(eventList),
												eventList, this, NULL);
		
		if (err)
		{
			printf("InstallWindowEventHandler err %i\n", (int)err);
			return false;
		}
	}
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (mListener)
	{
		if (contentView)
			[mListener setControl:contentView];
		else
			[mListener setWindow:mWindow];
		
		[mListener update:nil];
		[mListener delayedRefresh];
	}
	if (pool) { [pool release]; pool = nil; }
	
	LOG("SBVSTView opened OK (%p).\n", ptr);
	return true;
#endif
}

//-----------------------------------------------------------------------------
SBVSTView::SBVSTView(SBVST *effect) : AEffEditor(effect)
{
	LOG("SBVSTView constructor (%p).\n", effect)
	mEffect = effect;
	SBRootCircuit *circuit = effect->mainCircuit();
	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	NSSize size = [circuit circuitMinSize];
	[circuit setGuiMode:kRuntime];
	[circuit setActsAsCircuit:YES];
	[circuit setCircuitSize:size];
	
	mX = 0;
	mY = 0;
	mWidth = (int)size.width;
	mHeight = (int)size.height;
	
	mRect.top = 0;
	mRect.left = 0;
	mRect.bottom = mRect.top + mHeight;
	mRect.right =  mRect.left + mWidth;
	
	mLock = 0;
	
	mW = nil;
	mAgl = nil;
	
	mWindow = nil;
	mListener = [[SBListenerCarbon alloc] initWithCircuit:circuit];
	
	if (pool) { [pool release]; pool = nil; }
}

//-----------------------------------------------------------------------------
SBVSTView::~SBVSTView()
{
	LOG("SBVSTView destructor.\n")
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	if (mWindow) close();
	ogRelease(mW);
	if (mAgl) aglDestroyContext(mAgl);
	if (mListener) [mListener release];
	if (pool) { [pool release]; pool = nil; }
}

//-----------------------------------------------------------------------------
void SBVSTView::close()
{
	LOG("SBVSTView close.\n")
	if (mListener) [mListener setWindow:nil];
	if (mAgl) aglSetDrawable(mAgl, nil);
	mWindow = nil;
}

//-----------------------------------------------------------------------------
bool SBVSTView::getRect (ERect **rect)
{
	if (rect)
	{
		*rect = &mRect;
		return true;
	}
	return false;
}

#endif
