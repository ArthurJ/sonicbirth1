/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBElement.h"


@interface SBGranulate : SBElement
{
@public
	struct GranulateImp *mImp;
}
@end

@interface SBGranulatePicth : SBElement
{
@public
	struct GranulatePitchImp *mImp;
}
@end
