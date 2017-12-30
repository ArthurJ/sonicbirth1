/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


@class SBRootCircuit;

@interface SBRuntimeView : NSOpenGLView
{
	SBRootCircuit	*mCircuit;
	int				mLastX, mLastY;
	ogWrap			*mW;
	int				mTimers;
}

- (void) setCircuit:(SBRootCircuit*)circuit;
- (void) circuitDidChangeView:(NSNotification *)notification;
- (void) circuitDidChangeGlobalView:(NSNotification *)notification;
- (void) refresh;
- (void) delayedRefresh;
@end
