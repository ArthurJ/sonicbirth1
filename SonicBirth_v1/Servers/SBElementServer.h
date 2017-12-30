/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"

@interface SBElementServer : NSObject
{
	NSMutableArray  *mElementsArray;
	NSMutableArray  *mCommonElementsArray;
	
	// in application only
	IBOutlet NSPanel		*mElementPanel;
	IBOutlet NSOutlineView	*mOutlineView;
	
	NSMutableArray			*mCategoryArray;
}

- (void) fillMenu:(NSMenu*)menu target:(id)target action:(SEL)action;

- (SBElement*) createElement:(NSString*)name;
- (NSArray*) rawElements;
- (SBElement*) rawElementForClassName:(NSString*)className;

- (void) createElementsArray;

// in application only
- (IBAction) showPanel:(id)server;
- (void) createCategoryArray;

@end

extern SBElementServer *gElementServer;

