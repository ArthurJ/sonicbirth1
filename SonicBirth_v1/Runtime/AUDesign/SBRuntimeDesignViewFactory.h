/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import <AudioUnit/AUCocoaUIView.h>
#import "SBCircuitView.h"

@interface SBRuntimeDesignViewFactory : NSObject <AUCocoaUIBase>
{
	IBOutlet NSView			*mAUView;
	IBOutlet SBCircuitView	*mCircuitView;

	IBOutlet NSObject *m1, *m2, *m3, *m4, *m5;
}

@end
