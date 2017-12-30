/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/
#include <Accelerate/Accelerate.h>
#include <stdio.h>
#include <math.h>

// Note: FrameworkUtils could not be easily included (ObjC). 
// The function below sb_vDSP_create_fftsetup(… was taken from that file.
#ifndef FRAMEWORK_UTILS
FFTSetup sb_vDSP_create_fftsetup(vDSP_Length log2n, FFTRadix radix)
{
	return vDSP_create_fftsetup(log2n, radix);
}
#endif

void print_time(char *s, float b[8])
{
	printf("%s\n", s);
	
	int i;
	for (i = 0; i < 8; i++) printf("%f ", b[i]);
	
	printf("\n\n");
}

void print_freq(char *s, float b[8])
{
	printf("%s\n", s);
	
	int i;
	printf("dc: %f ny: %f\n", b[0], b[4]);
	for (i = 1; i < 4; i++) printf("bin %i %f %f\n", i, b[i], b[i+4]);
	
	printf("\n");
}


/*
	FFT routine, (C)1996 S.M.Bernsee. Sign = -1 is FFT, 1 is iFFT (inverse)
	Fills fftBuffer[0...2*fftFrameSize-1] with the Fourier transform of the time domain data in
	fftBuffer[0...2*fftFrameSize-1]. The FFT array takes and returns the cosine and sine parts in
	an interleaved manner, ie. fftBuffer[0] = cosPart[0], fftBuffer[1] = sinPart[0], asf. fftFrameSize
	must be a power of 2. It expects a complex input signal (see footnote 2), ie. when working with 'common'
	audio signals our input signal has to be passed as {in[0],0.,in[1],0.,in[2],0.,...} asf. In that case,
	the transform of the frequencies of interest is in fftBuffer[0...fftFrameSize].
*/

void smbFft(float *fftBuffer, long fftFrameSize, long sign)
{
	float wr, wi, arg, *p1, *p2, temp;
	float tr, ti, ur, ui, *p1r, *p1i, *p2r, *p2i;
	long i, bitm, j, le, le2, k, logN;
	logN = (long)(log(fftFrameSize)/log(2.)+.5);
	
	for (i = 2; i < 2*fftFrameSize-2; i += 2)
	{

		for (bitm = 2, j = 0; bitm < 2*fftFrameSize; bitm <<= 1)
		{
			if (i & bitm) j++;
			j <<= 1;
		}

		if (i < j)
		{
			p1 = fftBuffer+i; p2 = fftBuffer+j;
			temp = *p1; *(p1++) = *p2;
			*(p2++) = temp; temp = *p1;
			*p1 = *p2; *p2 = temp;
		}
	}

	for (k = 0, le = 2; k < logN; k++)
	{
		le <<= 1;
		le2 = le>>1;
		ur = 1.0;
		ui = 0.0;
		arg = M_PI / (le2>>1);
		wr = cos(arg);
		wi = sign*sin(arg);
		for (j = 0; j < le2; j += 2)
		{

			p1r = fftBuffer+j; p1i = p1r+1;
			p2r = p1r+le2; p2i = p2r+1;
			for (i = j; i < 2*fftFrameSize; i += le)
			{
				tr = *p2r * ur - *p2i * ui;
				ti = *p2r * ui + *p2i * ur;
				*p2r = *p1r - tr; *p2i = *p1i - ti;
				*p1r += tr; *p1i += ti;
				p1r += le; p1i += le;
				p2r += le; p2i += le;
			}

			tr = ur*wr - ui*wi;
			ui = ur*wi + ui*wr;
			ur = tr;
		}
	}
}

int main(int argc, char *argv[])
{
	int j;
	
	float test[16] = {	0, 0, 0, 0, 0, 0, 0, 0,
						0, 0, 0, 0, 0, 0, 1, 0 };
						
	float filt[16] = {	0, 0, 1, 0, 0, 0, 0, 0,
						0, 0, 0, 0, 0, 0, 0, 0 };

	printf("sign "); for (j = 0; j < 16; j += 2) printf("%f ", test[j]); printf("\n");
	printf("filt "); for (j = 0; j < 16; j += 2) printf("%f ", filt[j]); printf("\n");
	
	smbFft(test, 8, -1);
	smbFft(filt, 8, -1);
	
	printf("sign "); for (j = 0; j < 16; j++) printf("%f ", test[j]); printf("\n");
	printf("filt "); for (j = 0; j < 16; j++) printf("%f ", filt[j]); printf("\n");
	

	for(j = 0; j < 16; j+= 2)
	{
		test[j] = test[j] * filt[j] - test[j+1] * filt[j+1];
		test[j+1] = test[j+1] * filt[j] + test[j] * filt[j+1];
	}
	
	printf("conv "); for (j = 0; j < 16; j++) printf("%f ", test[j]); printf("\n");
	
	smbFft(test, 8, 1);
	
	printf("conv "); for (j = 0; j < 16; j += 2) printf("%f ", test[j] / 8.); printf("\n");

	int i;
	//float signal[8] = { 0, 0, 0, 0, 1, 1, 1, 1 };
	//float signal[8] = { 1, 1, 1, 1, 1, 1, 1, 1 };
	//float signal[8] = { 1, 1, 1, 1, 0, 0, 0, 0 };
	//float signal[8] = { 0, 0, 1, 1, 1, 1, 0, 0 };
	//float signal[8] = { 0, 0, 0, 0, 1, 1, 0, 0 };
	//float signal[8] = { 0, 0, 1, 1, 0, 0, 0, 0 };
	//float signal[8] = { 0, 0, 0, 1, 0, 0, 0, 0 };
	//float signal[8] = { 0, 0, 0, 0, 0, 0, 0, 1 };
	//float signal[8] = { 0, 0, 0, 1, 0, 0, 0, 0 };
	float signal[8] = { 0, 0, 0, 0, 0, 0, 0, 1 };
	float filter[8] = { 0, 0, 0, 0, 1, 0, 0, 0 };
	float convol[8];
	FFTSetup setup = sb_vDSP_create_fftsetup(3, kFFTRadix2);
	/*
	float test2[16] = {	0, 1, 0, 0, 0, 0, 0, 0,
						0, 0, 0, 0, 0, 0, 0, 0 };
	
	DSPSplitComplex sc_test2 = {test2 , test2+8};
	vDSP_fft_zrip(setup, &sc_test2, 1, 3, kFFTDirection_Forward);
	
	printf("test2 "); for (j = 0; j < 16; j++) printf("%f ", test2[j] * 0.5); printf("\n");
	*/
	print_time("signal", signal);
	print_time("filter", filter);
	
	DSPSplitComplex sc_signal = {signal , signal+4};
	DSPSplitComplex sc_filter = {filter , filter+4};
	DSPSplitComplex sc_convol = {convol , convol+4};
	
	vDSP_fft_zrip(setup, &sc_signal, 1, 3, kFFTDirection_Forward);
	vDSP_fft_zrip(setup, &sc_filter, 1, 3, kFFTDirection_Forward); 
	
	for (i = 0; i < 8; i++) signal[i] *= 0.5;
	for (i = 0; i < 8; i++) filter[i] *= 0.5;
	
	print_freq("signal", signal);
	print_freq("filter", filter);
	
	convol[0] = signal[0] * filter[0]; // dc
	convol[4] = signal[4] * filter[4]; // ny
	for (i = 1; i < 4; i++)
	{
		convol[i] = signal[i] * filter[i] - signal[i+4] * filter[i+4];
		convol[i+4] = signal[i+4] * filter[i] + signal[i] * filter[i+4];
	}
	
	print_freq("convol", convol);
	
	vDSP_fft_zrip(setup, &sc_signal, 1, 3, kFFTDirection_Inverse);
	vDSP_fft_zrip(setup, &sc_filter, 1, 3, kFFTDirection_Inverse);
	vDSP_fft_zrip(setup, &sc_convol, 1, 3, kFFTDirection_Inverse);
	
	for (i = 0; i < 8; i++) signal[i] /= 8.;
	for (i = 0; i < 8; i++) filter[i] /= 8.;
	for (i = 0; i < 8; i++) convol[i] /= 8.;
	
	print_time("signal", signal);
	print_time("filter", filter);
	print_time("convol", convol);
	

	return 0;
}





