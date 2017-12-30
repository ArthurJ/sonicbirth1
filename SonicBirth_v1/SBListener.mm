/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBListener.h"


@implementation SBListenerObjc
- (void) setObject:(SBListenerCpp*)obj { mObj = obj; }
- (void) setVSTObject:(SBVST*)obj { mVSTObj = obj; }

- (void) registerEventsFromCircuit:(SBRootCircuit*)c
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
				selector:@selector(argumentsChanged:)
				name:kSBCircuitDidChangeArgumentCountNotification
				object:c];
				
	int numArguments = [c numberOfArguments], i;
	for (i = 0; i < numArguments; i++)
	{
		SBArgument *a = [c argumentAtIndex:i];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(beginGesture:)
					name:kSBArgumentBeginGestureNotification
					object:a];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(parameterUpdated:)
					name:kSBArgumentDidChangeParameterValueNotification
					object:a];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(endGesture:)
					name:kSBArgumentEndGestureNotification
					object:a];
		[[NSNotificationCenter defaultCenter] addObserver:self
					selector:@selector(argumentsChanged:)
					name:kSBArgumentDidChangeParameterInfo
					object:a];
	}
}
- (void) beginGesture:(NSNotification *)notification
{
	NSDictionary *dict = [notification userInfo];
	
	if (mObj) mObj->beginGesture([dict objectForKey:@"argument"], [[dict objectForKey:@"index"] intValue]);
}
- (void) parameterUpdated:(NSNotification *)notification
{
	NSDictionary *dict = [notification userInfo];
	
	if (mObj) mObj->parameterUpdated([dict objectForKey:@"argument"], [[dict objectForKey:@"index"] intValue]);
	if (mVSTObj) mVSTObj->parameterUpdated([dict objectForKey:@"argument"], [[dict objectForKey:@"index"] intValue]);
}
- (void) endGesture:(NSNotification *)notification
{
	NSDictionary *dict = [notification userInfo];
	
	if (mObj) mObj->endGesture([dict objectForKey:@"argument"], [[dict objectForKey:@"index"] intValue]);
}
- (void) argumentsChanged:(NSNotification *)notification
{
	if (mObj) mObj->argumentsChanged();
}
- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}
@end
