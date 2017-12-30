/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBRuntimeViewFactory.h"
#import "SBRuntimeView.h"
#import "SBRootCircuit.h"

#import <AudioUnit/AudioUnit.h>

@implementation SBRuntimeViewFactory

- (unsigned) interfaceVersion
{
	return 0;
}

- (NSView *) uiViewForAudioUnit:(AudioUnit)inAudioUnit withSize:(NSSize)inPreferredSize
{
	SBRuntimeView *v = [[[SBRuntimeView alloc] init] autorelease];
	
	SBRootCircuit *circuit;
	UInt32 size = sizeof(SBRootCircuit*);
	AudioUnitGetProperty(inAudioUnit, kCircuitID, kAudioUnitScope_Global, 0, &circuit, &size);
	assert(circuit);
	
	if (v) [v setCircuit:circuit];
	return v;
}

- (NSString *) description
{
     return [NSString stringWithString: @"SonicBirth Cocoa View"];
}

@end
