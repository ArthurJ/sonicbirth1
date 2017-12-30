/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBAudioPlayer.h"
#import "SBInterpolation.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBAudioPlayer *obj = inObj;
	
	if (!count) return;
	
	float *bf = obj->pInputBuffers[5].audioData->data;
	int bfc = obj->pInputBuffers[5].audioData->count;
	double pos = obj->mPos;
	BOOL playing = obj->mPlaying;
	
	if (bfc <= 0)
	{
		if (obj->mPrecision == kFloatPrecision)
			memset(obj->mAudioBuffers[0].floatData + offset, 0, count * sizeof(float));
		else
			memset(obj->mAudioBuffers[0].doubleData + offset, 0, count * sizeof(double));
			
		return;
	}
	
	SBInterpolation ip = obj->mInterpolation;
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *t = obj->pInputBuffers[0].floatData + offset;
		float *s = obj->pInputBuffers[1].floatData + offset;
		float *e = obj->pInputBuffers[2].floatData + offset;
		float *l = obj->pInputBuffers[3].floatData + offset;
		float *v = obj->pInputBuffers[4].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		while(count--)
		{
			BOOL play = ((int)(*t++ + 0.5f) != 0);
			if (play && !playing) pos = 0;
			playing = play;
			if (play)
			{
				int start = *s++ * (bfc - 1);
				int end = *e++ * (bfc - 1);
				BOOL loop = ((int)(*l++ + 0.5f) != 0);
				float speed = *v++;
				
				if (start < 0) start = 0; else if (start >= bfc) start = bfc - 1;
				if (end < 0) end = 0; else if (end >= bfc) end = bfc - 1;
				if (speed < -5.f) speed = -5.f; else if (speed > 5.f) speed = 5.f;
				if (end < start)
				{
					int tVar = end;
					end = start;
					start = tVar;
					speed = -speed;
				}
				
				int bfs = end - start;
				
				if ((bfs <= 0) || ((pos < 0.f || pos >= bfs) && !loop))
					*o++ = 0;
				else
				{
					if (ip == kNoInterpolation)
						*o++ = interpolate_float_no(pos, bf + start, bfs);
					else
						*o++ = interpolate_float_lin(pos, bf + start, bfs);
						
					pos += speed;

					if (loop)
					{
						if (isinf(pos) || isnan(pos)) pos = 0;
						while(pos < 0) pos += bfs;
						while(pos > bfs) pos -= bfs;
					}
				}
			}
			else
			{
				s++; e++; l++; v++;
				*o++ = 0.f;
			}
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *t = obj->pInputBuffers[0].doubleData + offset;
		double *s = obj->pInputBuffers[1].doubleData + offset;
		double *e = obj->pInputBuffers[2].doubleData + offset;
		double *l = obj->pInputBuffers[3].doubleData + offset;
		double *v = obj->pInputBuffers[4].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		while(count--)
		{
			BOOL play = ((int)(*t++ + 0.5) != 0);
			if (play && !playing) pos = 0;
			playing = play;
			if (play)
			{
				int start = *s++ * (bfc - 1);
				int end = *e++ * (bfc - 1);
				BOOL loop = ((int)(*l++ + 0.5) != 0);
				float speed = *v++;
				
				if (start < 0) start = 0; else if (start >= bfc) start = bfc - 1;
				if (end < 0) end = 0; else if (end >= bfc) end = bfc - 1;
				if (speed < -5.f) speed = -5.f; else if (speed > 5.f) speed = 5.f;
				if (end < start)
				{
					int tVar = end;
					end = start;
					start = tVar;
					speed = -speed;
				}
				
				int bfs = end - start;
				
				if ((bfs <= 0) || ((pos < 0. || pos >= bfs) && !loop))
					*o++ = 0;
				else
				{
					if (ip == kNoInterpolation)
						*o++ = interpolate_float_no(pos, bf + start, bfs);
					else
						*o++ = interpolate_float_lin(pos, bf + start, bfs);
						
					pos += speed;

					if (loop)
					{
						if (isinf(pos) || isnan(pos)) pos = 0;
						while(pos < 0) pos += bfs;
						while(pos > bfs) pos -= bfs;
					}
				}
			}
			else
			{
				s++; e++; l++; v++;
				*o++ = 0.;
			}
		}
	}
	
	obj->mPos = pos;
	obj->mPlaying = playing;
}

@implementation SBAudioPlayer

+ (NSString*) name
{
	return @"Audio player";
}

- (NSString*) name
{
	return @"audio play.";
}

+ (SBElementCategory) category
{
	return kAudioFile;
}

- (NSString*) informations
{
	return	@"Audio player plays the audio from the buffer when trig is non-zero. "
			@"Start and end represents the playing offset. "
			@"If end is smaller than start, speed is negated. "
			@"Both these values should be between 0 and 1. "
			@"Playing will loop if the loop input is non-zero. "
			@"Speed give the playing speed, should be between -5 and 5. "
			@"A negative speed means the buffers is played reversed.";
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"trig"];
		[mInputNames addObject:@"start"];
		[mInputNames addObject:@"end"];
		[mInputNames addObject:@"loop"];
		[mInputNames addObject:@"speed"];
		[mInputNames addObject:@"buf"];
		
		[mOutputNames addObject:@"o"];
	}
	return self;
}

- (SBConnectionType) typeOfInputAtIndex:(int)idx
{
	if (idx < 5) return kNormal;
	return kAudioBuffer;
}

- (void) reset
{
	[super reset];
	mPlaying = NO;
	mPos = 0;
}

- (BOOL) interpolates
{
	return YES;
}

@end
