/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBRuntimeDesignViewFactory.h"
#import "SBRootCircuit.h"

#import <AudioUnit/AudioUnit.h>

@implementation SBRuntimeDesignViewFactory

- (unsigned) interfaceVersion
{
	return 0;
}

- (NSView *) uiViewForAudioUnit:(AudioUnit)inAudioUnit withSize:(NSSize)inPreferredSize
{
	SBRootCircuit *circuit;
	UInt32 size = sizeof(SBRootCircuit*);
	AudioUnitGetProperty(inAudioUnit, kCircuitID, kAudioUnitScope_Global, 0, &circuit, &size);
	assert(circuit);

	mAUView = nil;
	[NSBundle loadNibNamed:@"AUDesign" owner:self];
	
	if (mCircuitView)
	{
		[mCircuitView setRootCircuit:circuit];
		
		#define add_to_release_array(x) \
			if (x) { [mCircuitView addObjectToArray:x]; [x release]; }
		
		add_to_release_array(m1)
		add_to_release_array(m2)
		//add_to_release_array(m3)
		add_to_release_array(m4)
		add_to_release_array(m5)
	}
	
	if (mAUView)
	{
		[mAUView autorelease]; // mAUView is m3
		
		//fprintf(stderr, "asked w: %f h: %f\n", inPreferredSize.width, inPreferredSize.height);
		//fprintf(stderr, "mAUView w: %f h: %f\n", [mAUView frame].size.width, [mAUView frame].size.height);
	}
	
	return mAUView;
	
	//return [[[NSView alloc] initWithFrame:NSMakeRect(0,0,800,600)] autorelease];
}

@end
