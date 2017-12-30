/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBEnvelopeFollower.h"

// for time to decay by 40 db:
// g = (10^(-40/20))^(1/(sec * sr))
// g = 0.01^(1000/(ms*sr))

// http://www.musicdsp.org/showArchiveComment.php?ArchiveID=136

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBEnvelopeFollower *obj = inObj;
	
	if (count == 0) return;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *a = obj->pInputBuffers[1].floatData + offset;
		float *r = obj->pInputBuffers[2].floatData + offset;
		float *e = obj->mAudioBuffers[0].floatData + offset;
		float sr = obj->mSampleRate;
		
		float env = obj->mLastE;
		float g;
		
		float la = *a; float lag = powf(0.01f, 1000.f / (la * sr));
		float lr = *r; float lrg = powf(0.01f, 1000.f / (lr * sr));
		
		while(count--)
		{
			float tmp = sabsf(*i++);
			//if (tmp > env) { g = powf(0.01f, 1000.f / (*a++ * sr)); r++; }
			//else { g = powf(0.01f, 1000.f / (*r++ * sr)); a++; }
			
			if (tmp > env)
			{
				float ca = *a++; r++;
				if (ca != la) { la = ca; lag = powf(0.01f, 1000.f / (ca * sr)); }
				g = lag;
			}
			else
			{
				float cr = *r++; a++;
				if (cr != lr) { lr = cr; lrg = powf(0.01f, 1000.f / (cr * sr)); }
				g = lrg;
			}
			
			*e++ = env = g * env + (1.f - g) * tmp;
		}
		
		obj->mLastE = env;
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *a = obj->pInputBuffers[1].doubleData + offset;
		double *r = obj->pInputBuffers[2].doubleData + offset;
		double *e = obj->mAudioBuffers[0].doubleData + offset;
		double sr = obj->mSampleRate;
		
		double env = obj->mLastE;
		double g;
		
		double la = *a; double lag = pow(0.01, 1000. / (la * sr));
		double lr = *r; double lrg = pow(0.01, 1000. / (lr * sr));

		while(count--)
		{
			double tmp = sabs(*i++);
			//if (tmp > env) { g = pow(0.01, 1000. / (*a++ * sr)); r++; }
			//else { g = pow(0.01, 1000. / (*r++ * sr)); a++; }
			
			if (tmp > env)
			{
				double ca = *a++; r++;
				if (ca != la) { la = ca; lag = pow(0.01, 1000. / (ca * sr)); }
				g = lag;
			}
			else
			{
				double cr = *r++; a++;
				if (cr != lr) { lr = cr; lrg = pow(0.01, 1000. / (cr * sr)); }
				g = lrg;
			}
			
			*e++ = env = g * env + (1. - g) * tmp;
		}
		
		obj->mLastE = env;
	}
}

@implementation SBEnvelopeFollower

+ (NSString*) name
{
	return @"Envelope Follower";
}

- (NSString*) name
{
	return @"env fol";
}

+ (SBElementCategory) category
{
	return kAnalysis;
}

- (NSString*) informations
{
	return	@"Envelope follower with variable attack and release time, in milliseconds. "
			@"The output is in positive linear units.";
}

- (void) reset
{
	mLastE = 0;
	[super reset];
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"atck"];
		[mInputNames addObject:@"rlse"];
		
		[mOutputNames addObject:@"env"];
	}
	return self;
}

@end
