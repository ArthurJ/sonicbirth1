/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef SBListerner_H
#define SBListerner_H

#import "SBArgument.h"
#import "SBRootCircuit.h"
#import "SonicBirthRuntimeVST.h"

class SBListenerCpp
{
public:
	virtual void beginGesture(SBArgument *a, int i) {}
	virtual void parameterUpdated(SBArgument *a, int i) {}
	virtual void endGesture(SBArgument *a, int i) {}
	virtual void argumentsChanged() {}
	virtual ~SBListenerCpp() {}
};

@interface SBListenerObjc : NSObject
{
	SBListenerCpp	*mObj;
	SBVST			*mVSTObj;
}
- (void) setObject:(SBListenerCpp*)obj;
- (void) setVSTObject:(SBVST*)obj;
- (void) registerEventsFromCircuit:(SBRootCircuit*)c;
- (void) beginGesture:(NSNotification *)notification;
- (void) parameterUpdated:(NSNotification *)notification;
- (void) endGesture:(NSNotification *)notification;
- (void) argumentsChanged:(NSNotification *)notification;
@end

#endif /* SBListerner_H */
