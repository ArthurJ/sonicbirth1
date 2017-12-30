/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBResonantHighpass.h"

#define UPDATE_COEFF_DOUBLE(f, r, sr, a0, a1, a2, b1, b2) \
	if (f <= 1.) \
	{ \
		a0 = 1; a1 = 0; a2 = 0; b1 = 0; b2 = 0; \
	} \
	else \
	{ \
		if (r < 0.1) r = 0.1; else if (r > 1.415) r = 1.415; \
		if (f > (sr/2.)) f = (sr/2.); \
		double c = tan(M_PI * f / sr); \
		double g = 1.; \
		double k = c*c + r*c + g; \
		a0 = 1. / (g*k); \
		a1 = -(a0+a0); \
		a2 = a0; \
		b1 = 2. * (g - c*c) / k; \
		b2 = -((c*c - r*c +g) / k); \
	}
	
#define UPDATE_COEFF_FLOAT(f, r, sr, a0, a1, a2, b1, b2) \
	if (f <= 1.f) \
	{ \
		a0 = 1; a1 = 0; a2 = 0; b1 = 0; b2 = 0; \
	} \
	else \
	{ \
		if (r < 0.1f) r = 0.1f; else if (r > 1.415f) r = 1.415f; \
		if (f > (sr/2.f)) f = (sr/2.f); \
		double c = tanf((float)M_PI * f / sr); \
		double g = 1.f; \
		double k = c*c + r*c + g; \
		a0 = 1.f / (g*k); \
		a1 = -(a0+a0); \
		a2 = a0; \
		b1 = 2.f * (g - c*c) / k; \
		b2 = -((c*c - r*c +g) / k); \
	}

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBResonantHighpass *obj = inObj;
	
	if (count <= 0) return;
	
	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *f = obj->pInputBuffers[1].floatData + offset;
		float *r = obj->pInputBuffers[2].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		
		float sr = obj->mSampleRate;
		
		float a0, a1, a2, b1, b2;
		float cf, cr, tf, tr;


		if (count > 1)
		{
			float *x2 = i, *x1 = x2 + 1, *y2 = o, *y1 = y2 + 1;
			
			cf = *f++; cr = *r++;
			UPDATE_COEFF_FLOAT(cf, cr, sr, a0, a1, a2, b1, b2)
			*o++ = a0**i++ + a1*((float)obj->mX1) + a2*((float)obj->mX2) + b1*((float)obj->mY1) + b2*((float)obj->mY2);
			
			tf = *f++; tr = *r++;
			if (tf != cf || tr != cr)
			{
				cf = tf; cr = tr;
				UPDATE_COEFF_FLOAT(cf, cr, sr, a0, a1, a2, b1, b2)
			}
			*o++ = a0**i++ + a1**x2 + a2*((float)obj->mX1) + b1**y2 + b2*((float)obj->mY1);
			
			count -= 2;
			while(count--)
			{
				tf = *f++; tr = *r++;
				if (tf != cf || tr != cr)
				{
					cf = tf; cr = tr;
					UPDATE_COEFF_FLOAT(cf, cr, sr, a0, a1, a2, b1, b2)
				}
				*o++ = a0**i++ + a1**x1++ + a2**x2++ + b1**y1++ + b2**y2++;
			}
			
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			cf = *f; cr = *r;
			UPDATE_COEFF_FLOAT(cf, cr, sr, a0, a1, a2, b1, b2)
			*o = a0**i + a1*((float)obj->mX1) + a2*((float)obj->mX2) + b1*((float)obj->mY1) + b2*((float)obj->mY2);
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = *i;			obj->mY1 = *o;
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *f = obj->pInputBuffers[1].doubleData + offset;
		double *r = obj->pInputBuffers[2].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		
		double sr = obj->mSampleRate;
		
		double a0, a1, a2, b1, b2;
		double cf, cr, tf, tr;

		if (count > 1)
		{
			double *x2 = i, *x1 = x2 + 1, *y2 = o, *y1 = y2 + 1;
			
			cf = *f++; cr = *r++;
			UPDATE_COEFF_DOUBLE(cf, cr, sr, a0, a1, a2, b1, b2)
			*o++ = a0**i++ + a1*((float)obj->mX1) + a2*((float)obj->mX2) + b1*((float)obj->mY1) + b2*((float)obj->mY2);
			
			tf = *f++; tr = *r++;
			if (tf != cf || tr != cr)
			{
				cf = tf; cr = tr;
				UPDATE_COEFF_DOUBLE(cf, cr, sr, a0, a1, a2, b1, b2)
			}
			*o++ = a0**i++ + a1**x2 + a2*((float)obj->mX1) + b1**y2 + b2*((float)obj->mY1);
			
			count -= 2;
			while(count--)
			{
				tf = *f++; tr = *r++;
				if (tf != cf || tr != cr)
				{
					cf = tf; cr = tr;
					UPDATE_COEFF_DOUBLE(cf, cr, sr, a0, a1, a2, b1, b2)
				}
				*o++ = a0**i++ + a1**x1++ + a2**x2++ + b1**y1++ + b2**y2++;
			}
			
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			cf = *f; cr = *r;
			UPDATE_COEFF_DOUBLE(cf, cr, sr, a0, a1, a2, b1, b2)
			*o = a0**i + a1*((float)obj->mX1) + a2*((float)obj->mX2) + b1*((float)obj->mY1) + b2*((float)obj->mY2);
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = *i;			obj->mY1 = *o;
		}
	}
}

@implementation SBResonantHighpass

+ (NSString*) name
{
	return @"Resonant highpass";
}

- (NSString*) name
{
	return @"res.hpass";
}

- (NSString*) informations
{
	return	@"Resonant highpass filter, 12/db octave (Butterworth), with variable cutoff frequency (clamped to [20, 20000]). "
			@"Resonance should be between sqrt(2), that is 1.414..., for no resonance, and 0.1 for max resonance.";
}

+ (SBElementCategory) category
{
	return kFilter;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"f"];
		[mInputNames addObject:@"r"];
		
		[mOutputNames addObject:@"out"];
		
		pCalcFunc = privateCalcFunc;
	}
	return self;
}

- (void) reset
{
	[super reset];
	mX1 = mX2 = mY1 = mY2 = 0.;
}

@end
