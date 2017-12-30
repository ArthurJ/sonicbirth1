/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#include "SBTimeStamp.h"

static SBTimeStamp gTimeStamp = 3;

SBTimeStamp SBGetTimeStamp()
{
	return gTimeStamp++;
}

