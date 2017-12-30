/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBFormant.h"

#define kPhonemeDesc \
	@"phoneme 0: eee (beet)\n" \
	@"phoneme 1: ihh (bit)\n" \
	@"phoneme 2: ehh (bet)\n" \
	@"phoneme 3: aaa (bat)\n" \
	@"phoneme 4: ahh (father)\n" \
	@"phoneme 5: aww (bought)\n" \
	@"phoneme 6: uhh (but)\n" \
	@"phoneme 7: uuu (foot)\n" \
	@"phoneme 8: ooo (boot)\n" \
	@"phoneme 9: rrr (bird)\n" \
	@"phoneme 10: lll (lull)\n" \
	@"phoneme 11: mmm (mom)\n" \
	@"phoneme 12: nnn (nun)\n"

static const int gPhonemeParametersCount = 13;

typedef struct
{
	double f;
	double r;
	int g;
} PhonemeParameter;

static const PhonemeParameter gPhonemeParameters[gPhonemeParametersCount][4] =
{
   {  { 273, 0.996,  10},       // eee (beet)
      {2086, 0.945, -16}, 
      {2754, 0.979, -12}, 
      {3270, 0.440, -17}},
	  
   {  { 385, 0.987,  10},       // ihh (bit)
      {2056, 0.930, -20},
      {2587, 0.890, -20}, 
      {3150, 0.400, -20}},
	  
   {  { 515, 0.977,  10},       // ehh (bet)
      {1805, 0.810, -10}, 
      {2526, 0.875, -10}, 
      {3103, 0.400, -13}},
	  
   {  { 773, 0.950,  10},       // aaa (bat)
      {1676, 0.830,  -6},
      {2380, 0.880, -20}, 
      {3027, 0.600, -20}},
     
   {  { 770, 0.950,   0},       // ahh (father)
      {1153, 0.970,  -9},
      {2450, 0.780, -29},
      {3140, 0.800, -39}},
	  
   {  { 637, 0.910,   0},       // aww (bought)
      { 895, 0.900,  -3},
      {2556, 0.950, -17},
      {3070, 0.910, -20}},

   {  { 561, 0.965,   0},       // uhh (but)
      {1084, 0.930, -10}, 
      {2541, 0.930, -15}, 
      {3345, 0.900, -20}},
    
   {  { 515, 0.976,   0},       // uuu (foot)
      {1031, 0.950,  -3},
      {2572, 0.960, -11},
      {3345, 0.960, -20}},
	  
   {  { 349, 0.986, -10},       // ooo (boot)
      { 918, 0.940, -20},
      {2350, 0.960, -27},
      {2731, 0.950, -33}},
	  
   {  { 394, 0.959, -10},       // rrr (bird)
      {1297, 0.780, -16},
      {1441, 0.980, -16},
      {2754, 0.950, -40}},
	  
   {  { 462, 0.990,  +5},       // lll (lull)
      {1200, 0.640, -10},
      {2500, 0.200, -20},
      {3000, 0.100, -30}},
     
   {  { 265, 0.987, -10},       // mmm (mom)
      {1176, 0.940, -22},
      {2352, 0.970, -20},
      {3277, 0.940, -31}},
	  
   {  { 204, 0.980, -10},       // nnn (nun)
      {1570, 0.940, -15},
      {2481, 0.980, -12},
      {3133, 0.800, -30}}
};


static bool gPowTableInited = false;
static const int gPowTableSize = 71;
static const int gPowTableOffset = 50;
static double gPowTable[gPowTableSize]; // -50 to 20 inclusive

class Biquad
{
public:
	void setPart(int part)
	{
		mPart = part;
	}
	void prepare(int sr)
	{
		mSR = (double)sr;
	}
	void reset()
	{
		mX1 = 0; mX2 = 0;
		mY1 = 0; mY2 = 0;
	}
	double compute(int v1, int v2, double m, double i)
	{
		double f1 = gPhonemeParameters[v1][mPart].f;
		double f2 = gPhonemeParameters[v2][mPart].f;
		double f = f1 + (f2 - f1) * m;
		
		double r1 = gPhonemeParameters[v1][mPart].r;
		double r2 = gPhonemeParameters[v2][mPart].r;
		double r = r1 + (r2 - r1) * m;
		
		int g1 = gPhonemeParameters[v1][mPart].g;
		int g2 = gPhonemeParameters[v2][mPart].g;
		int g = (int)(g1 + (g2 - g1) * m);
		
		double a2 = r * r;
		double a1 = -2. * r * cos((2*M_PI) * f / mSR);
		
		double b0 = 0.5 - 0.5 * a2;
		double b2 = -b0;
		
		i = i * gPowTable[g + gPowTableOffset];
		
		double o = b0 * i + b2 * mX2;
		o -= a2 * mY2 + a1 * mY1;
		
		mX2 = mX1;
		mX1 = i;
		
		mY2 = mY1;
		mY1 = o;
		
		return o;
	}
private:
	int mPart;
	double mSR;
	double mX1, mX2, mY1, mY2;
};

class FormantImp
{
public:
	FormantImp()
	{
		if (!gPowTableInited)
		{
			gPowTableInited = true;
			for (int i = 0; i < gPowTableSize; i++)
				gPowTable[i] = pow(10., (i - gPowTableOffset) / 20.);
			//for (int i = -50; i <= 20; i++)
			//	printf("%i %f\n", i, gPowTable[i + gPowTableOffset]);
		}
	
		mBQ[0].setPart(0);
		mBQ[1].setPart(1);
		mBQ[2].setPart(2);
		mBQ[3].setPart(3);
	}
	void prepare(int sr)
	{
		mBQ[0].prepare(sr);
		mBQ[1].prepare(sr);
		mBQ[2].prepare(sr);
		mBQ[3].prepare(sr);
	}
	void reset()
	{
		mBQ[0].reset();
		mBQ[1].reset();
		mBQ[2].reset();
		mBQ[3].reset();
	}
	double compute(int v1, int v2, double m, double i)
	{
		if (v1 < 0) v1 = 0; else if (v1 >= gPhonemeParametersCount) v1 = gPhonemeParametersCount - 1;
		if (v2 < 0) v2 = 0; else if (v2 >= gPhonemeParametersCount) v2 = gPhonemeParametersCount - 1;
		if (m < 0) m = 0; else if (m > 1) m = 1;
		
		double o = mBQ[0].compute(v1, v2, m, i);
		o += mBQ[1].compute(v1, v2, m, i);
		o += mBQ[2].compute(v1, v2, m, i);
		o += mBQ[3].compute(v1, v2, m, i);
		
		return o;
	}
private:
	Biquad mBQ[4];
};

extern "C" void SBFormantPrivateCalcFunc(void *inObj, int count, int offset);
extern "C" void SBFormantPrivateCalcFuncImpl(int count, int offset,
									void *mModel, SBPrecision mPrecision,
									SBBuffer *pInputBuffers,
									SBBuffer *mAudioBuffers)
{
	if (count <= 0) return;

	FormantImp *imp = (FormantImp *)mModel;
	
	if (mPrecision == kFloatPrecision)
	{
		float *i = pInputBuffers[0].floatData + offset;
		float *v1 = pInputBuffers[1].floatData + offset;
		float *v2 = pInputBuffers[2].floatData + offset;
		float *m = pInputBuffers[3].floatData + offset;
		float *o = mAudioBuffers[0].floatData + offset;

		while(count--)
			*o++ = (float)imp->compute((int)(*v1++ + 0.5f), (int)(*v2++ + 0.5f), (double)*m++, (double)*i++);

	}
	else if (mPrecision == kDoublePrecision)
	{
		double *i = pInputBuffers[0].doubleData + offset;
		double *v1 = pInputBuffers[1].doubleData + offset;
		double *v2 = pInputBuffers[2].doubleData + offset;
		double *m = pInputBuffers[3].doubleData + offset;
		double *o = mAudioBuffers[0].doubleData + offset;

		while(count--)
			*o++ = imp->compute((int)(*v1++ + 0.5), (int)(*v2++ + 0.5), *m++, *i++);
	}
}


@implementation SBFormant

+ (NSString*) name
{
	return @"Formant filter";
}

- (NSString*) name
{
	return @"form flt";
}

+ (SBElementCategory) category
{
	return kFilter;
}

- (NSString*) informations
{
	return	@"Formant filter with variable phonemes. Choose one on v1, another on v2, "
			@"and you can mix between the two using input m [0,1]. Here are the phonemes:\n"
			kPhonemeDesc;
}

- (void) reset
{
	[super reset];
	mImp->reset();
}

- (id) init
{
	self = [super init];
	if (self != nil)
	{
		mImp = new FormantImp();
		if (!mImp)
		{
			[self release];
			return nil;
		}
	
		pCalcFunc = SBFormantPrivateCalcFunc;

		[mInputNames addObject:@"i"];
		[mInputNames addObject:@"v1"];
		[mInputNames addObject:@"v2"];
		[mInputNames addObject:@"m"];
		[mOutputNames addObject:@"o"];
	}
	return self;
}

- (void) dealloc
{
	delete mImp;
	[super dealloc];
}

- (void) specificPrepare
{
	mImp->prepare(mSampleRate);
}

@end
