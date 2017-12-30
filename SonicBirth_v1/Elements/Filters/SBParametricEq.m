/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
// http://epubl.luth.se/1402-1773/2003/044/LTU-CUPP-03044-SE.pdf

#import "SBParametricEq.h"

static void privateCalcFunc(void *inObj, int count, int offset)
{
	SBParametricEq *obj = inObj;
	
	if (count <= 0) return;
	
	int gi, fi;
	

	
#define PREPARE_COEFF_INIT(q_min, q_max) \
	gi = ((int)(gc * 10)) - kGainBase; \
	if (gi < 0) gi = 0; else if (gi > kGainIndexMax) gi = kGainIndexMax; \
	gv = gainTable[gi]; \
	 \
	fi = ((int)(fc)) - kFreqBase; \
	if (fi < 0) fi = 0; else if (fi > kFreqIndexMax) fi = kFreqIndexMax; \
	sv = sinTable[fi]; \
	cv = cosTable[fi]; \
	 \
	qv = qc; \
	if (qv < q_min) qv = q_min; else if (qv > q_max) qv = q_max; \
	 \
	av = sv / (qv + qv); \
	 \
	b0 = 1 + av * gv; \
	b1 = -2 * cv; \
	b2 = 1 - av * gv; \
	a0 = 1 / (1 + av / gv); \
	a1 = b1; \
	a2 = 1 - av / gv;
	
#define PREPARE_COEFF(q_min, q_max) \
	gc = *g++; fc = *f++; qc = *Q++; \
	if (gc != gl || fc != fl || qc != ql) \
	{ \
		PREPARE_COEFF_INIT(q_min, q_max) \
		gl = gc; fl = fc; ql = qc; \
	}
	

	
	if (obj->mPrecision == kFloatPrecision)
	{
		float *i = obj->pInputBuffers[0].floatData + offset;
		float *f = obj->pInputBuffers[1].floatData + offset;
		float *g = obj->pInputBuffers[2].floatData + offset;
		float *Q = obj->pInputBuffers[3].floatData + offset;
		float *o = obj->mAudioBuffers[0].floatData + offset;
		float *gainTable = obj->mGainFloatTable;
		float *sinTable = obj->mSinFreqFloatTable;
		float *cosTable = obj->mCosFreqFloatTable;
		float gv, sv, cv, qv, av, gc, fc, qc, gl, fl, ql;
		float a0, a1, a2, b0, b1, b2;
		
		if (count > 1)
		{
			float *x2 = i, *x1 = x2 + 1, *y2 = o, *y1 = y2 + 1;
			
			gl = gc = *g++; fl = fc = *f++; ql = qc = *Q++;
			PREPARE_COEFF_INIT(0.3f, 15.f)
			*o++ = (b0**i++ + b1*((float)obj->mX1) + b2*((float)obj->mX2) - a1*((float)obj->mY1) - a2*((float)obj->mY2)) * a0;
			
			PREPARE_COEFF(0.3f, 15.f)
			*o++ = (b0**i++ + b1**x2 + b2*((float)obj->mX1) - a1**y2 - a2*((float)obj->mY1)) * a0;
			
			count -= 2;
			while(count--)
			{
				PREPARE_COEFF(0.3f, 15.f)
				*o++ = (b0**i++ + b1**x1++ + b2**x2++ - a1**y1++ - a2**y2++) * a0;
			}
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			gc = *g++; fc = *f++; qc = *Q++;
			PREPARE_COEFF_INIT(0.3f, 15.f)
			o[0] = (b0*i[0] + b1*((float)obj->mX1) + b2*((float)obj->mX2) - a1*((float)obj->mY1) - a2*((float)obj->mY2)) * a0;
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = i[0];		obj->mY1 = o[0];
		}
	}
	else if (obj->mPrecision == kDoublePrecision)
	{
		double *i = obj->pInputBuffers[0].doubleData + offset;
		double *f = obj->pInputBuffers[1].doubleData + offset;
		double *g = obj->pInputBuffers[2].doubleData + offset;
		double *Q = obj->pInputBuffers[3].doubleData + offset;
		double *o = obj->mAudioBuffers[0].doubleData + offset;
		double *gainTable = obj->mGainDoubleTable;
		double *sinTable = obj->mSinFreqDoubleTable;
		double *cosTable = obj->mCosFreqDoubleTable;
		double gv, sv, cv, qv, av, gc, fc, qc, gl, fl, ql;
		double a0, a1, a2, b0, b1, b2;
		
		if (count > 1)
		{
			double *x2 = i, *x1 = x2 + 1, *y2 = o, *y1 = y2 + 1;
			
			gl = gc = *g++; fl = fc = *f++; ql = qc = *Q++;
			PREPARE_COEFF_INIT(0.3, 15.)
			*o++ = (b0**i++ + b1*(obj->mX1) + b2*(obj->mX2) - a1*(obj->mY1) - a2*(obj->mY2)) * a0;
			
			PREPARE_COEFF(0.3, 15.)
			*o++ = (b0**i++ + b1**x2 + b2*(obj->mX1) - a1**y2 - a2*(obj->mY1)) * a0;
			
			count -= 2;
			while(count--)
			{
				PREPARE_COEFF(0.3, 15.)
				*o++ = (b0**i++ + b1**x1++ + b2**x2++ - a1**y1++ - a2**y2++) * a0;
			}
			obj->mX2 = *x2;	obj->mY2 = *y2;
			obj->mX1 = *x1;	obj->mY1 = *y1;
		}
		else // count == 1
		{
			gc = *g++; fc = *f++; qc = *Q++;
			PREPARE_COEFF_INIT(0.3, 15.)
			o[0] = (b0*i[0] + b1*(obj->mX1) + b2*(obj->mX2) - a1*(obj->mY1) - a2*(obj->mY2)) * a0;
			obj->mX2 = obj->mX1;	obj->mY2 = obj->mY1;
			obj->mX1 = i[0];		obj->mY1 = o[0];
		}
	}
}

@implementation SBParametricEq

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		pCalcFunc = privateCalcFunc;
	
		[mInputNames addObject:@"in"];
		[mInputNames addObject:@"f"];
		[mInputNames addObject:@"g"];
		[mInputNames addObject:@"Q"];
		
		[mOutputNames addObject:@"out"];
	}
	return self;
}

+ (SBElementCategory) category
{
	return kFilter;
}

+ (NSString*) name
{
	return @"Parametric Eq.";
}

- (NSString*) name
{
	return @"prm eq";
}

- (NSString*) informations
{
	return	@"Parametric Eq: f is the center frequency, g is the gain or cut in dB (clamped in the range -15 .. 15). "
			@"Q should be between 0.3 and 15.";
}

- (void) reset
{
	[super reset];
	mX1 = mX2 = mY1 = mY2 = 0.;
}

- (void) specificPrepare
{
	double sr = mSampleRate;

	int i;
	for(i = 0; i < kFreqCount; i++)
	{
		double f = i + kFreqBase;
		
		double w = (2 * M_PI * f) / sr;
		if (w < 0.) w = 0.;
		else if (w > 1.) w = 1;
		
		double sn = sin(w);
		double cs = cos(w);
		
		mSinFreqDoubleTable[i] = sn;
		mCosFreqDoubleTable[i] = cs;
		
		mSinFreqFloatTable[i] = sn;
		mCosFreqFloatTable[i] = cs;
	}
	
	for(i = 0; i < kGainCount; i++)
	{
		double g = (i + kGainBase) / 10.; // g is in decibels, table is in tenths of decibels
		
		double ling = pow(10.,g/40.);
		
		mGainDoubleTable[i] = ling;
		mGainFloatTable[i] = ling;
	}
}

@end
