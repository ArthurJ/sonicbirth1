/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import <Carbon/Carbon.h>

@class SBRootCircuit;

@interface SBListenerCarbon : NSObject
{
	WindowRef	mWindow;
	ControlRef	mControl;
	int			mTimers;
}

- (id) initWithCircuit:(SBRootCircuit*)c;

- (void) setWindow:(WindowRef)w;
- (void) setControl:(ControlRef)c;

- (void) update:(NSNotification *)notification;

- (void) refresh;
- (void) delayedRefresh;
@end