/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#ifndef SB_CONTROLLER_LIST
#define SB_CONTROLLER_LIST

typedef struct
{
	NSString *name;
	int num;
} SBControllerType;

#define kOffID (-2)
#define kLearnID (-1)

extern SBControllerType gControllerTypes[];
extern int gControllerTypesCount;

#endif /* SB_CONTROLLER_LIST */
