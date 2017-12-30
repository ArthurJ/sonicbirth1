/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#import "SBEquation.h"
#import "SBEditCell.h"
#import "equation.h"
#import <Accelerate/Accelerate.h>

#define mES ((EquationState*)mEquationState)

#if (MAX_OS_VERSION_USE >= 4)
extern "C" void SBEquationPrivateCalcFunc(void *inObj, int count, int offset);
extern "C" void SBEquationPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers,
									SBBuffer *mBuffers,
									BOOL *mUpdateBuffer,
									int mSampleCount)
{
	if (count <= 0) return;
	if (!*mUpdateBuffer) return;
	
	EquationState *es = (EquationState *)mModel;
	
	// check if invalid
	BOOL valid = (es && es->isValid() && (es->operationCount() == 0 || mBuffers));
	int opCount = (valid) ? es->operationCount() : 0;
	if (opCount == 0)
	{
		if (mPrecision == kFloatPrecision)
		{
			float *o = mAudioBuffers[0].floatData;
			float v = (valid) ? es->result() : 0.f;
			vDSP_vfill(&v, o, 1, mSampleCount);
		}
		else
		{
			double *o = mAudioBuffers[0].doubleData;
			double v = (valid) ? es->result() : 0.0;
			vDSP_vfillD(&v, o, 1, mSampleCount);
		}
		
	//	printf("splatted %f\n", es->result());
		*mUpdateBuffer = NO;
		
		return;
	}


	// apply plan
	int i;
	if (mPrecision == kFloatPrecision)
		for (i = 0; i < opCount; i++)
		{
			Operation o = es->operationAtIndex(i);
			
			float val = o.value;
			
			float *ip1 = 0;
			float *ip2 = 0;
			float *op = 0;
			
			if (o.type == kCopyVector)
			{
				ip1 = pInputBuffers[o.input].floatData + offset;
			}
			else
			{
				int p = o.pos1;
				if (p != 0)
				{
					if (p < 0) ip1 = pInputBuffers[(-p -1)].floatData + offset;
					else ip1 = mBuffers[(p - 1)].floatData + offset;
				}
				
				p = o.pos2;
				if (p != 0)
				{
					if (p < 0) ip2 = pInputBuffers[(-p -1)].floatData + offset;
					else ip2 = mBuffers[(p - 1)].floatData + offset;
				}
			}
			
			op = mBuffers[o.temp].floatData + offset;
			
			switch(o.type)
			{
				case kSplatConstant:	vDSP_vfill(&val, op, 1, count); break;
				case kCopyVector:		memcpy(op, ip1, count*sizeof(float)); break;
		
				case kScalarAdd:		vDSP_vsadd(ip1, 1, &val, op, 1, count); break;
				case kScalarMul:		vDSP_vsmul(ip1, 1, &val, op, 1, count); break;
		
				case kAdd:				vDSP_vadd(ip1, 1, ip2, 1, op, 1, count); break;
				case kSub:				vDSP_vsub(ip2, 1, ip1, 1, op, 1, count); break;
				case kMul:				vDSP_vmul(ip1, 1, ip2, 1, op, 1, count); break;
				case kDiv:				vvdivf(op, ip1, ip2, &count); break;
				case kNeg:
				{
					unsigned int *x = (unsigned int *)ip1;
					unsigned int *mx = (unsigned int *)op;
					for (int j = 0; j < count; j++) *mx++ = *x++ ^ 0x80000000;
				}
				break;
		
				case kSin:				vvsinf(op, ip1, &count); break;
				case kCos:				vvcosf(op, ip1, &count); break;
				case kTan:				vvtanf(op, ip1, &count); break;
		
				case kSinh:				vvsinhf(op, ip1, &count); break;
				case kCosh:				vvcoshf(op, ip1, &count); break;
				case kTanh:				vvtanhf(op, ip1, &count); break;
		
				case kAsin:				vvasinf(op, ip1, &count); break;
				case kAcos:				vvacosf(op, ip1, &count); break;
				case kAtan:				vvatanf(op, ip1, &count); break;
		
				case kAsinh:			vvasinhf(op, ip1, &count); break;
				case kAcosh:			vvacoshf(op, ip1, &count); break;
				case kAtanh:			vvatanhf(op, ip1, &count); break;
		
				case kMod:
				{
					vvdivf(op, ip1, ip2, &count);				// o = x/y 
					vvintf(op, op, &count);						// o = int(x/y)
					vDSP_vmul(op, 1, ip2, 1, op, 1, count);		// o = int(x/y)*y
					vDSP_vsub(op, 1, ip1, 1, op, 1, count);		// o = x - int(x/y)*y
				}
				break;
				
				case kFloor:			vvfloorf(op, ip1, &count); break;
				case kCeil:				vvceilf(op, ip1, &count); break;
		
				case kPow:				vvpowf(op, ip2, ip1, &count); break;
				case kAtan2:			vvatan2f(op, ip2, ip1, &count); break;
		
				case kInverse:			vvrecf(op, ip1, &count); break;
				case kNearInt:			vvnintf(op, ip1, &count); break;
				case kExp:				vvexpf(op, ip1, &count); break;
				case kLog:				vvlogf(op, ip1, &count); break;
				case kLog10:			vvlog10f(op, ip1, &count); break;
				case kSqrt:				vvsqrtf(op, ip1, &count); break;
				case kRevSqrt:			vvrsqrtf(op, ip1, &count); break;
				
				case kAbs:				vDSP_vabs(ip1, 1, op, 1, count); break;
				case kMin:				vDSP_vmin(ip1, 1, ip2, 1, op, 1, count); break;
				case kMax:				vDSP_vmax(ip1, 1, ip2, 1, op, 1, count); break;
				
				default: break;
			}
		}
	else // double precision
		for (i = 0; i < opCount; i++)
		{
			Operation o = es->operationAtIndex(i);
			
			double val = o.value;
			
			double *ip1 = 0;
			double *ip2 = 0;
			double *op = 0;
			
			if (o.type == kCopyVector)
			{
				ip1 = pInputBuffers[o.input].doubleData + offset;
			}
			else
			{
				int p = o.pos1;
				if (p != 0)
				{
					if (p < 0) ip1 = pInputBuffers[(-p -1)].doubleData + offset;
					else ip1 = mBuffers[(p - 1)].doubleData + offset;
				}
				
				p = o.pos2;
				if (p != 0)
				{
					if (p < 0) ip2 = pInputBuffers[(-p -1)].doubleData + offset;
					else ip2 = mBuffers[(p - 1)].doubleData + offset;
				}
			}
			
			op = mBuffers[o.temp].doubleData + offset;
			
			switch(o.type)
			{
				case kSplatConstant:	vDSP_vfillD(&val, op, 1, count); break;
				case kCopyVector:		memcpy(op, ip1, count*sizeof(double)); break;
		
				case kScalarAdd:		vDSP_vsaddD(ip1, 1, &val, op, 1, count); break;
				case kScalarMul:		vDSP_vsmulD(ip1, 1, &val, op, 1, count); break;
		
				case kAdd:				vDSP_vaddD(ip1, 1, ip2, 1, op, 1, count); break;
				case kSub:				vDSP_vsubD(ip2, 1, ip1, 1, op, 1, count); break;
				case kMul:				vDSP_vmulD(ip1, 1, ip2, 1, op, 1, count); break;
				case kDiv:				vDSP_vdivD(ip2, 1, ip1, 1, op, 1, count); break;
				case kNeg:
				{
					unsigned int *x = (unsigned int *)ip1;
					unsigned int *mx = (unsigned int *)op;
					for (int j = 0; j < count; j++) { *mx++ = *x++ ^ 0x80000000; *mx++ = *x++; }
				}
				break;
		
				case kSin:				vvsin(op, ip1, &count); break;
				case kCos:				vvcos(op, ip1, &count); break;
				case kTan:				vvtan(op, ip1, &count); break;
		
				case kSinh:				vvsinh(op, ip1, &count); break;
				case kCosh:				vvcosh(op, ip1, &count); break;
				case kTanh:				vvtanh(op, ip1, &count); break;
		
				case kAsin:				vvasin(op, ip1, &count); break;
				case kAcos:				vvacos(op, ip1, &count); break;
				case kAtan:				vvatan(op, ip1, &count); break;
		
				case kAsinh:			vvasinh(op, ip1, &count); break;
				case kAcosh:			vvacosh(op, ip1, &count); break;
				case kAtanh:			vvatanh(op, ip1, &count); break;
		
				case kMod:
				{			
					vDSP_vdivD(ip2, 1, ip1, 1, op, 1, count);	// o = x/y 
					vvint(op, op, &count);						// o = int(x/y)
					vDSP_vmulD(op, 1, ip2, 1, op, 1, count);	// o = int(x/y)*y
					vDSP_vsubD(op, 1, ip1, 1, op, 1, count);	// o = x - int(x/y)*y
				}
				break;
				
				case kFloor:			vvfloor(op, ip1, &count); break;
				case kCeil:				vvceil(op, ip1, &count); break;
		
				case kPow:				vvpow(op, ip2, ip1, &count); break;
				case kAtan2:			vvatan2(op, ip2, ip1, &count); break;
		
				case kInverse:			vvrec(op, ip1, &count); break;
				case kNearInt:			vvnint(op, ip1, &count); break;
				case kExp:				vvexp(op, ip1, &count); break;
				case kLog:				vvlog(op, ip1, &count); break;
				case kLog10:			vvlog10(op, ip1, &count); break;
				case kSqrt:				vvsqrt(op, ip1, &count); break;
				case kRevSqrt:			vvrsqrt(op, ip1, &count); break;
				
				case kAbs:				vDSP_vabsD(ip1, 1, op, 1, count); break;
				case kMin:				vDSP_vminD(ip1, 1, ip2, 1, op, 1, count); break;
				case kMax:				vDSP_vmaxD(ip1, 1, ip2, 1, op, 1, count); break;
				
				default: break;
			}
		}
}
#else
#error 10.4 minimum
#endif

#if 0
static void privateCalcFunc(void *inObj, int count, int offset)
{
	if (count <= 0) return;
	
	//typedef (SBEquation) sbequation;
	//sbequation *obj = (sbequation*)inObj;
	SBEquation *obj = inObj;
	
	if (!(obj->mUpdateBuffer)) return;
	EquationState *es = (EquationState *)obj->mEquationState;

	// check if invalid
	BOOL valid = (es && es->isValid() && (es->operationCount() == 0 || obj->mBuffers));
	int opCount = (valid) ? es->operationCount() : 0;
	if (opCount == 0)
	{
		if (obj->mPrecision == kFloatPrecision)
		{
			float *o = obj->mAudioBuffers[0].floatData;
			float v = (valid) ? es->result() : 0.f;
			//vDSP_vfill(&v, o, 1, obj->mBuffersSize);
			count = obj->mSampleCount; while(count--) *o++ = v;
		}
		else
		{
			double *o = obj->mAudioBuffers[0].doubleData;
			double v = (valid) ? es->result() : 0.0;
			//vDSP_vfillD(&v, o, 1, obj->mBuffersSize);
			count = obj->mSampleCount; while(count--) *o++ = v;
		}
		
	//	printf("splatted %f\n", es->result());
		obj->mUpdateBuffer = NO;
		
		return;
	}

	// apply plan
	int i;
	if (obj->mPrecision == kFloatPrecision)
		for (i = 0; i < opCount; i++)
		{
			Operation o = es->operationAtIndex(i);
			
			float val = o.value;
			
			float *ip1 = 0;
			float *ip2 = 0;
			float *op = 0;
			
			if (o.type == kCopyVector)
			{
				ip1 = obj->pInputBuffers[o.input].floatData + offset;
			}
			else
			{
				int p = o.pos1;
				if (p != 0)
				{
					if (p < 0) ip1 = obj->pInputBuffers[(-p -1)].floatData + offset;
					else ip1 = obj->mBuffers[(p - 1)].floatData + offset;
				}
				
				p = o.pos2;
				if (p != 0)
				{
					if (p < 0) ip2 = obj->pInputBuffers[(-p -1)].floatData + offset;
					else ip2 = obj->mBuffers[(p - 1)].floatData + offset;
				}
			}
			
			op = obj->mBuffers[o.temp].floatData + offset;
			
			switch(o.type)
			{
				case kSplatConstant:	for (int j = 0; j < count; j++) *op++ = val; break;
				case kCopyVector:		memcpy(op, ip1, count*sizeof(float)); break;
		
				case kScalarAdd:		vDSP_vsadd(ip1, 1, &val, op, 1, count); break;
				case kScalarMul:		vDSP_vsmul(ip1, 1, &val, op, 1, count); break;
		
				case kAdd:				vDSP_vadd(ip1, 1, ip2, 1, op, 1, count); break;
				case kSub:				vDSP_vsub(ip2, 1, ip1, 1, op, 1, count); break;
				case kMul:				vDSP_vmul(ip1, 1, ip2, 1, op, 1, count); break;
				case kDiv:				for (int j = 0; j < count; j++) *op++ = *ip1++ / *ip2++; break;
				case kNeg:
				{
					unsigned int *x = (unsigned int *)ip1;
					unsigned int *mx = (unsigned int *)op;
					for (int j = 0; j < count; j++) *mx++ = *x++ ^ 0x80000000;
				}
				break;
		
				case kSin:				for (int j = 0; j < count; j++) *op++ = sinf(*ip1++); break;
				case kCos:				for (int j = 0; j < count; j++) *op++ = cosf(*ip1++); break;
				case kTan:				for (int j = 0; j < count; j++) *op++ = tanf(*ip1++); break;
		
				case kSinh:				for (int j = 0; j < count; j++) *op++ = sinhf(*ip1++); break;
				case kCosh:				for (int j = 0; j < count; j++) *op++ = coshf(*ip1++); break;
				case kTanh:				for (int j = 0; j < count; j++) *op++ = tanhf(*ip1++); break;
		
				case kAsin:				for (int j = 0; j < count; j++) *op++ = asinf(*ip1++); break;
				case kAcos:				for (int j = 0; j < count; j++) *op++ = acosf(*ip1++); break;
				case kAtan:				for (int j = 0; j < count; j++) *op++ = atanf(*ip1++); break;
		
				case kAsinh:			for (int j = 0; j < count; j++) *op++ = asinhf(*ip1++); break;
				case kAcosh:			for (int j = 0; j < count; j++) *op++ = acoshf(*ip1++); break;
				case kAtanh:			for (int j = 0; j < count; j++) *op++ = atanhf(*ip1++); break;
		
				case kMod:				for (int j = 0; j < count; j++) *op++ = fmodf(*ip1++, *ip2++); break;
				
				case kFloor:			for (int j = 0; j < count; j++) *op++ = floorf(*ip1++); break;
				case kCeil:				for (int j = 0; j < count; j++) *op++ = ceilf(*ip1++); break;
		
				case kPow:				for (int j = 0; j < count; j++) *op++ = powf(*ip1++, *ip2++); break;
				case kAtan2:			for (int j = 0; j < count; j++) *op++ = atan2f(*ip2++, *ip1++); break;
		
				case kInverse:			for (int j = 0; j < count; j++) *op++ = 1.f / *ip1++; break;
				case kNearInt:
					for (int j = 0; j < count; j++)
					{
						float t = *ip1++;
						*op++ = (t > 0.f) ? floorf(t + 0.5f) : ceilf(t - 0.5f);
					}
					break;
					
				case kExp:				for (int j = 0; j < count; j++) *op++ = expf(*ip1++); break;
				case kLog:				for (int j = 0; j < count; j++) *op++ = logf(*ip1++); break;
				case kLog10:			for (int j = 0; j < count; j++) *op++ = log10f(*ip1++); break;
				case kSqrt:				for (int j = 0; j < count; j++) *op++ = sqrtf(*ip1++); break;
				case kRevSqrt:			for (int j = 0; j < count; j++) *op++ = 1.f / sqrtf(*ip1++); break;
				
				case kAbs:
				{
					unsigned int *x = (unsigned int *)ip1;
					unsigned int *ax = (unsigned int *)op;
					for (int j = 0; j < count; j++) *ax++ = *x++ & 0x7FFFFFFF;
				}
				break;
				
				case kMin:				for (int j = 0; j < count; j++) *op++ = sminf(*ip1++, *ip2++); break;
				case kMax:				for (int j = 0; j < count; j++) *op++ = smaxf(*ip1++, *ip2++); break;
				
				default: break;
			}
		}
	else // double precision
		for (i = 0; i < opCount; i++)
		{
			Operation o = es->operationAtIndex(i);
			
			double val = o.value;
			
			double *ip1 = 0;
			double *ip2 = 0;
			double *op = 0;
			
			if (o.type == kCopyVector)
			{
				ip1 = obj->pInputBuffers[o.input].doubleData + offset;
			}
			else
			{
				int p = o.pos1;
				if (p != 0)
				{
					if (p < 0) ip1 = obj->pInputBuffers[(-p -1)].doubleData + offset;
					else ip1 = obj->mBuffers[(p - 1)].doubleData + offset;
				}
				
				p = o.pos2;
				if (p != 0)
				{
					if (p < 0) ip2 = obj->pInputBuffers[(-p -1)].doubleData + offset;
					else ip2 = obj->mBuffers[(p - 1)].doubleData + offset;
				}
			}
			
			op = obj->mBuffers[o.temp].doubleData + offset;
			
			switch(o.type)
			{
				case kSplatConstant:	for (int j = 0; j < count; j++) *op++ = val; break;
				case kCopyVector:		memcpy(op, ip1, count*sizeof(double)); break;
		
				case kScalarAdd:		vDSP_vsaddD(ip1, 1, &val, op, 1, count); break;
				case kScalarMul:		vDSP_vsmulD(ip1, 1, &val, op, 1, count); break;
		
				case kAdd:				vDSP_vaddD(ip1, 1, ip2, 1, op, 1, count); break;
				case kSub:				vDSP_vsubD(ip2, 1, ip1, 1, op, 1, count); break;
				case kMul:				vDSP_vmulD(ip1, 1, ip2, 1, op, 1, count); break;
				case kDiv:				for (int j = 0; j < count; j++) *op++ = *ip1++ / *ip2++; break;
				case kNeg:
				{
					unsigned int *x = (unsigned int *)ip1;
					unsigned int *mx = (unsigned int *)op;
					for (int j = 0; j < count; j++) { *mx++ = *x++ ^ 0x80000000; *mx++ = *x++; }
				}
				break;
		
				case kSin:				for (int j = 0; j < count; j++) *op++ = sin(*ip1++); break;
				case kCos:				for (int j = 0; j < count; j++) *op++ = cos(*ip1++); break;
				case kTan:				for (int j = 0; j < count; j++) *op++ = tan(*ip1++); break;
		
				case kSinh:				for (int j = 0; j < count; j++) *op++ = sinh(*ip1++); break;
				case kCosh:				for (int j = 0; j < count; j++) *op++ = cosh(*ip1++); break;
				case kTanh:				for (int j = 0; j < count; j++) *op++ = tanh(*ip1++); break;
		
				case kAsin:				for (int j = 0; j < count; j++) *op++ = asin(*ip1++); break;
				case kAcos:				for (int j = 0; j < count; j++) *op++ = acos(*ip1++); break;
				case kAtan:				for (int j = 0; j < count; j++) *op++ = atan(*ip1++); break;
		
				case kAsinh:			for (int j = 0; j < count; j++) *op++ = asinh(*ip1++); break;
				case kAcosh:			for (int j = 0; j < count; j++) *op++ = acosh(*ip1++); break;
				case kAtanh:			for (int j = 0; j < count; j++) *op++ = atanh(*ip1++); break;
		
				case kMod:				for (int j = 0; j < count; j++) *op++ = fmod(*ip1++, *ip2++); break;
				
				case kFloor:			for (int j = 0; j < count; j++) *op++ = floor(*ip1++); break;
				case kCeil:				for (int j = 0; j < count; j++) *op++ = ceil(*ip1++); break;
		
				case kPow:				for (int j = 0; j < count; j++) *op++ = pow(*ip1++, *ip2++); break;
				case kAtan2:			for (int j = 0; j < count; j++) *op++ = atan2(*ip2++, *ip1++); break;
		
				case kInverse:			for (int j = 0; j < count; j++) *op++ = 1. / *ip1++; break;
				case kNearInt:
					for (int j = 0; j < count; j++)
					{
						float t = *ip1++;
						*op++ = (t > 0.f) ? floor(t + 0.5) : ceil(t - 0.5);
					}
					break;
					
				case kExp:				for (int j = 0; j < count; j++) *op++ = exp(*ip1++); break;
				case kLog:				for (int j = 0; j < count; j++) *op++ = log(*ip1++); break;
				case kLog10:			for (int j = 0; j < count; j++) *op++ = log10(*ip1++); break;
				case kSqrt:				for (int j = 0; j < count; j++) *op++ = sqrt(*ip1++); break;
				case kRevSqrt:			for (int j = 0; j < count; j++) *op++ = 1. / sqrt(*ip1++); break;
				
				case kAbs:
				{
					unsigned int *x = (unsigned int *)ip1;
					unsigned int *ax = (unsigned int *)op;
					for (int j = 0; j < count; j++) { *ax++ = *x++ & 0x7FFFFFFF; *ax++ = *x++; }
				}
				break;
				
				case kMin:				for (int j = 0; j < count; j++) *op++ = smin(*ip1++, *ip2++); break;
				case kMax:				for (int j = 0; j < count; j++) *op++ = smax(*ip1++, *ip2++); break;
				
				default: break;
			}
		}
}
#endif


@implementation SBEquation

+ (NSString*) name
{
	return @"Equation";
}

- (NSString*) name
{
	return @"eq";
}

- (NSString*) informations
{
	return	@"A mathematical equation. You can use these functions:\n\n"
			@"sin(x), cos(x), tan(x), asin(x), acos(x), atan(x),\n"
			@"sinh(x), cosh(x), tanh(x), asinh(x), acosh(x), atanh(x),\n"
			@"atan2(x,y), pow(x,y), min(x,y), max(x,y), mod(x,y),\n"
			@"abs(x), floor(x), ceil(x), nearint(x), inv(x),\n"
			@"exp(x), log(x), log10(x), sqrt(x), revsqrt(x).\n\n"
			@"Speed: compare the execute plan for:\n"
			@"\t- i0*2*3 and i0*(2*3)\n"
			@"\t- i0*i0*i0*i0 and (i0*i0)*(i0*i0)\n\n"
			@"You can also enter an equation in the constant element (sqrt(2) for example).";
}

+ (SBElementCategory) category
{
	return kMisc;
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
#if (MAX_OS_VERSION_USE >= 4)
		//pCalcFunc = (frameworkOSVersion() >= 4) ? privateCalcFuncFast : privateCalcFunc;
		assert(frameworkOSVersion() >= 4);
		pCalcFunc = SBEquationPrivateCalcFunc;
		
#else
		#error 10.4 minimum
		pCalcFunc = privateCalcFunc;
#endif
	
		mEquation = [[NSMutableString alloc] initWithString:@"0"];
		if (!mEquation)
		{
			[self release];
			return nil;
		}
		
		mEquationState = (void*) new EquationState;
		if (!mES)
		{
			[self release];
			return nil;
		}
		
		mBuffers = nil;
		mBuffersCount = 0;
		mBuffersSize = 0;
		
		mInputs = 1;
		[mInputNames addObject:@"i0"];
		[mOutputNames addObject:@"o"];
		
		[self compileEquation];
		
		[self fixCell];
	}
	return self;
}

- (void) dealloc
{	
	if (mES) delete mES;
	if (mBuffers) free(mBuffers);
	if (mEquation) [mEquation release];
	if (mSettingsView) [mSettingsView release];
	[super dealloc];
}

- (NSView*) settingsView
{
	if (mSettingsView) return mSettingsView;
	else
	{
		[NSBundle loadNibNamed:@"SBEquation" owner:self];
		return mSettingsView;
	}
}

- (void) setNumberOfInputs:(int)c
{
	if (c < 0) c = 0;
	else if (c > 16) c = 16;
	mInputs = c;
	
	while((int)[mInputNames count] > c)
		[mInputNames removeLastObject];
	
	while((int)[mInputNames count] < c)
		[mInputNames addObject:[NSString stringWithFormat:@"i%i", [mInputNames count]]];
}

- (void) specificPrepare
{
	mUpdateBuffer = YES;
	
	if (mSampleCount <= 0) return;

	// check if buffers needed
	if (!mES || !mES->isValid() || mES->operationCount() <= 0)
	{
		// free buffers
		int i;
		if (mBuffers)
		{
			for (i = 0; i < mBuffersCount - 1; i++)
				if (mBuffers[i].ptr)
					free(mBuffers[i].ptr);
			
			free(mBuffers);
		}
		mBuffersCount = 0;
		mBuffers = nil;
		return;
	}
	
	// count temporaries
	int newOutputs = mES->operationAtIndex(mES->operationCount() - 1).temp;
	assert(newOutputs >= 0);
	
	newOutputs++; // for real output
	if (mBuffersCount != newOutputs || mBuffersSize != mSampleCount)
	{
		// first free buffers
		int i;
		if (mBuffers)
		{
			for (i = 0; i < mBuffersCount - 1; i++)
				if (mBuffers[i].ptr)
					free(mBuffers[i].ptr);
			
			free(mBuffers);
		}
		mBuffersCount = 0;
		mBuffers = nil;
		
		mBuffers = (SBBuffer*) malloc (newOutputs * sizeof(SBBuffer));
		if (!mBuffers) return;
		
		mBuffersSize = mSampleCount;
		mBuffersCount = newOutputs;
		memset(mBuffers, 0, newOutputs * sizeof(SBBuffer));
		
		for (i = 0; i < newOutputs - 1; i++)
		{
			mBuffers[i].ptr = malloc (mSampleCount * sizeof(double));
			if (!mBuffers[i].ptr)
			{
				for (i = 0; i < mBuffersCount - 1; i++)
					if (mBuffers[i].ptr)
						free(mBuffers[i].ptr);
			
				free(mBuffers);
				mBuffersCount = 0;
				mBuffers = nil;
				return;
			}
		}
	}
	
	mBuffers[mBuffersCount - 1] = mAudioBuffers[0];
}

- (void) compileEquation
{
	NSString *st = [mEquation stringByAppendingString:@";"];

	EquationState *es = mES;
	*es = parseEquation([st UTF8String], mInputs);
	
	if (mExecutePlan)
	{
		if (!mES->isValid())
			st = [NSString stringWithCString:mES->error().c_str()];
		else if (mES->operationCount() == 0)
			st = [NSString stringWithFormat:@"Output %f", mES->result()];
		else
			st = [NSString stringWithCString:mES->operationPlan().c_str()];

		if (st) [mExecutePlan setString:st];
	}
	
	// reallocate temps
	[self specificPrepare];
}

- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
	id tf = [aNotification object];
	if (tf == mInputsTF)
	{
		[self willChangeAudio];
			[self setNumberOfInputs:[mInputsTF intValue]];
			[mInputsTF setIntValue:mInputs];
			
			[self compileEquation];
			
			[self didChangeConnections];
		[self didChangeAudio];
		
		[self didChangeGlobalView];
	}
	else if (tf == mEquationTF)
	{
		NSString *s = [mEquationTF stringValue];
		if (s) [mEquation setString:s];
		
		[self willChangeAudio];
			[self compileEquation];
		[self didChangeAudio];
		
		[self fixCell];
	}
}

- (void) awakeFromNib
{
	[super awakeFromNib];

	[mInputsTF setIntValue:mInputs];
	[mEquationTF setStringValue:mEquation];
	
	[mExecutePlan setTypingAttributes:
			[NSDictionary dictionaryWithObject:[NSFont fontWithName:@"Courier" size:12]
								      	forKey:NSFontAttributeName ]];

	NSString *st;
	if (!mES->isValid())
		st = [NSString stringWithCString:mES->error().c_str()];
	else if (mES->operationCount() == 0)
		st = [NSString stringWithFormat:@"Output %f", mES->result()];
	else
		st = [NSString stringWithCString:mES->operationPlan().c_str()];

	if (st) [mExecutePlan setString:st];
}

- (NSMutableDictionary*) saveData
{
	NSMutableDictionary *md = [[[NSMutableDictionary alloc] init] autorelease];
	if (!md) return nil;
	
	[md setObject:[NSNumber numberWithInt:mInputs] forKey:@"inputs"];
	[md setObject:mEquation forKey:@"equation"];
	
	return md;
}

- (BOOL) loadData:(NSDictionary*)data
{
	if (!data) return NO;

	NSNumber *n = [data objectForKey:@"inputs"];
	if (n) [self setNumberOfInputs:[n intValue]];
	
	NSString *s = [data objectForKey:@"equation"];
	if (s) [mEquation setString:s];
	
	[self fixCell];
	[self compileEquation];
	
	return YES;
}

- (SBCell*) createCell
{
	SBEditCell *c = [[SBEditCell alloc] init];
	if (c) [c setTarget:self];
	return c;
}

- (void) reset
{
	mUpdateBuffer = YES;
	[super reset];
}

- (void) changePrecision:(SBPrecision)precision
{
	mUpdateBuffer = YES;
	[super changePrecision:precision];
}

- (void) editCellUpdated:(SBEditCell*)cell
{
	NSString *s = [cell string];
	if (s) [mEquation setString:s];
	if (mEquationTF) [mEquationTF setStringValue:mEquation];
		
	[self willChangeAudio];
		[self compileEquation];
	[self didChangeAudio];

	[self fixCell];
}

- (void) fixCell
{
	SBEditCell *c = (SBEditCell*)mCell;
	if (c)
	{
		[c setString:mEquation];
	
		int w = (int)ogStringWidth([mEquation UTF8String]) + 10;
		if (w < 30) w = 30;
		else if (w > 100) w = 100;
		
		[c setWidth:w height:16];
		mCalculatedFrame = NO;
	}
	[self didChangeGlobalView];
}

@end
