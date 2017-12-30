/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFreeverb.h"
#include "revmodel.hpp"

extern "C" void SBFreeverbPrivateCalcFunc(void *inObj, int count, int offset);
extern "C" void SBFreeverbPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers)
{
	
	if (count <= 0) return;
	
	revmodel *model = (revmodel *)mModel;
	
	if (mPrecision == kFloatPrecision)
	{
		float *i1 = pInputBuffers[0].floatData + offset;
		float *i2 = pInputBuffers[1].floatData + offset;
		float *rs = pInputBuffers[2].floatData + offset;
		float *damp = pInputBuffers[3].floatData + offset;
		float *wet = pInputBuffers[4].floatData + offset;
		float *dry = pInputBuffers[5].floatData + offset;
		float *width = pInputBuffers[6].floatData + offset;
		float *freeze = pInputBuffers[7].floatData + offset;
		
		float *o1 = mAudioBuffers[0].floatData + offset;
		float *o2 = mAudioBuffers[1].floatData + offset;
		
		model->setroomsize(*rs);
		model->setdamp(*damp);
		model->setwet(*wet);
		model->setdry(*dry);
		model->setwidth(*width);
		model->setmode(*freeze);
		model->update();
		
		model->processreplace(i1, i2, o1, o2, count, 1);
	}
	else if (mPrecision == kDoublePrecision)
	{
		double *i1 = pInputBuffers[0].doubleData + offset;
		double *i2 = pInputBuffers[1].doubleData + offset;
		double *rs = pInputBuffers[2].doubleData + offset;
		double *damp = pInputBuffers[3].doubleData + offset;
		double *wet = pInputBuffers[4].doubleData + offset;
		double *dry = pInputBuffers[5].doubleData + offset;
		double *width = pInputBuffers[6].doubleData + offset;
		double *freeze = pInputBuffers[7].doubleData + offset;
		
		double *o1 = mAudioBuffers[0].doubleData + offset;
		double *o2 = mAudioBuffers[1].doubleData + offset;
		
		model->setroomsize(*rs);
		model->setdamp(*damp);
		model->setwet(*wet);
		model->setdry(*dry);
		model->setwidth(*width);
		model->setmode(*freeze);
		model->update();
		
		model->processreplacedouble(i1, i2, o1, o2, count, 1);
	}
}

@implementation SBFreeverb

+ (SBElementCategory) category
{
	return kMisc;
}

+ (NSString*) name
{
	return @"Freeverb";
}

- (NSString*) name
{
	return @"freeverb";
}

- (NSString*) informations
{
	return	@"Jezar's freeverb. (Room size: 0.5 to 0.999, damp: 0 to 1, wet: 0 to 3, "
			@"dry: 0 to 2, width: 0 to 1, freeze: 0/no or 1/yes)";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = SBFreeverbPrivateCalcFunc;

		[mInputNames addObject:@"in1"];
		[mInputNames addObject:@"in2"];
		[mInputNames addObject:@"room size"];
		[mInputNames addObject:@"damp"];
		[mInputNames addObject:@"wet"];
		[mInputNames addObject:@"dry"];
		[mInputNames addObject:@"width"];
		[mInputNames addObject:@"freeze"];
		
		[mOutputNames addObject:@"out1"];
		[mOutputNames addObject:@"out2"];
		
		mModel = (void*)(new revmodel);
		if (!mModel)
		{
			[self release];
			return nil;
		}
	}
	return self;
}

- (void) dealloc
{
	if (mModel) delete ((revmodel *)mModel);
	[super dealloc];
}

- (void) reset
{
	[super reset];
	((revmodel *)mModel)->mute();
}

@end
