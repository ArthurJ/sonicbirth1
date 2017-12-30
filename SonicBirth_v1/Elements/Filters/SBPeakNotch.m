/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#import "SBPeakNotch.h"

/*
http://musicdsp.org/files/Audio-EQ-Cookbook.txt

	w0 = 2*pi*f0/Fs

    A  = sqrt( 10^(dBgain/20) )
       =       10^(dBgain/40)     (for peaking)
	   
	alpha = sin(w0)/(2*Q)                                       (case: Q - peaking)
          = sin(w0)*sinh( ln(2)/2 * BW * w0/sin(w0) )           (case: BW - notch)

notch:      H(s) = (s^2 + 1) / (s^2 + s/Q + 1)

            b0 =   1
            b1 =  -2*cos(w0)
            b2 =   1
            a0 =   1 + alpha
            a1 =  -2*cos(w0)
            a2 =   1 - alpha

peakingEQ:  H(s) = (s^2 + s*(A/Q) + 1) / (s^2 + s/(A*Q) + 1)

            b0 =   1 + alpha*A
            b1 =  -2*cos(w0)
            b2 =   1 - alpha*A
            a0 =   1 + alpha/A
            a1 =  -2*cos(w0)
            a2 =   1 - alpha/A

*/

@implementation SBPeak
+ (NSString*) name
{
	return @"Peak";
}
- (NSString*) name
{
	return @"peak";
}
- (NSString*) informations
{
	return @"Peaking eq, with constant Q (10) and dB gain (20 dB).";
}
- (void) specificPrepare
{
	int i; double fs = mSampleRate;
	
	for(i = 0; i < kCoeffCount; i++)
	{
		double f0 = i + kCoeffBase;
		
		double w0 = 2 * M_PI * f0 / fs;
		double dBGain = 20;
		double A = pow(10, dBGain/40.);
		double Q = 10;
		double alpha = sin(w0)/(Q*2);
		
		double b0 =   1 + alpha*A;
		double b1 =  -2 * cos(w0);
		double b2 =   1 - alpha*A;
		double a0 =   1 + alpha/A;
		double a1 =  -2 * cos(w0);
		double a2 =   1 - alpha/A;
		
		b0 /= a0;
		b1 /= a0;
		b2 /= a0;
		a1 /= a0;
		a2 /= a0;
		
		mCoeffFloat[i].a0 = b0;
		mCoeffFloat[i].a1 = b1;
		mCoeffFloat[i].a2 = b2;
		mCoeffFloat[i].b1 = -a1;
		mCoeffFloat[i].b2 = -a2;
		
		mCoeffDouble[i].a0 = b0;
		mCoeffDouble[i].a1 = b1;
		mCoeffDouble[i].a2 = b2;
		mCoeffDouble[i].b1 = -a1;
		mCoeffDouble[i].b2 = -a2;
	}
}
@end

@implementation SBNotch
+ (NSString*) name
{
	return @"Notch";
}
- (NSString*) name
{
	return @"notch";
}
- (NSString*) informations
{
	return @"Notch with constant bandwitdh (0.1 octave).";
}
- (void) specificPrepare
{
	int i; double fs = mSampleRate;
	
	for(i = 0; i < kCoeffCount; i++)
	{
		double f0 = i + kCoeffBase;
		
		double w0 = 2 * M_PI * f0 / fs;
		double BW = 0.1; // octaves
		double alpha = sin(w0) * sinh( log(2.)/2. * BW * w0/sin(w0) );
		
		double b0 =   1;
		double b1 =  -2 * cos(w0);
		double b2 =   1;
		double a0 =   1 + alpha;
		double a1 =  -2 * cos(w0);
		double a2 =   1 - alpha;
		
		b0 /= a0;
		b1 /= a0;
		b2 /= a0;
		a1 /= a0;
		a2 /= a0;
		
		mCoeffFloat[i].a0 = b0;
		mCoeffFloat[i].a1 = b1;
		mCoeffFloat[i].a2 = b2;
		mCoeffFloat[i].b1 = -a1;
		mCoeffFloat[i].b2 = -a2;
		
		mCoeffDouble[i].a0 = b0;
		mCoeffDouble[i].a1 = b1;
		mCoeffDouble[i].a2 = b2;
		mCoeffDouble[i].b1 = -a1;
		mCoeffDouble[i].b2 = -a2;
	}
}
@end
