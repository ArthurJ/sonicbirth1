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

- (id) init
{
	NSLog(@"SBRuntimeViewFactory init");
	self = [super init];
	return self;
}

- (unsigned) interfaceVersion
{
	return 0;
}

- (NSView *) uiViewForAudioUnit:(AudioUnit)inAudioUnit withSize:(NSSize)inPreferredSize
{
	NSLog(@"sonicbirth -uiViewForAudioUnit:%p", inAudioUnit);

	SBRuntimeView *v = [[[SBRuntimeView alloc] init] autorelease];
	assert(v);
	
	SBRootCircuit *circuit;
	UInt32 size = sizeof(SBRootCircuit*);
	AudioUnitGetProperty(inAudioUnit, kCircuitID, kAudioUnitScope_Global, 0, &circuit, &size);
	assert(circuit);
	
	if (v) [v setCircuit:circuit];
	return v;
}

+ (NSView *) uiViewForAudioUnit:(AudioUnit)inAudioUnit withSize:(NSSize)inPreferredSize
{
	NSLog(@"sonicbirth +uiViewForAudioUnit:%p", inAudioUnit);

	SBRuntimeView *v = [[[SBRuntimeView alloc] init] autorelease];
	assert(v);
	
	SBRootCircuit *circuit;
	UInt32 size = sizeof(SBRootCircuit*);
	AudioUnitGetProperty(inAudioUnit, kCircuitID, kAudioUnitScope_Global, 0, &circuit, &size);
	assert(circuit);
	
	if (v) [v setCircuit:circuit];
	return v;
}

- (NSString *) description
{
     return @"SonicBirth Cocoa View";
}

@end
