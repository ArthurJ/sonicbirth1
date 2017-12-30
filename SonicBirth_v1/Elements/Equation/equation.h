/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/

#ifndef _EQUATION_H_
#define _EQUATION_H_

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>

#include <vector>
#include <string>
#include <sstream>

using std::vector;
using std::string;
using std::ostringstream;

typedef enum
{
	kSplatConstant = 0,
	kCopyVector,
	
	kScalarAdd,
	kScalarMul,
	
	kAbs,
	kMin,
	kMax,
	
	kAdd,
	kSub,
	kMul,
	kDiv,
	kNeg,
	
	kSin,
	kCos,
	kTan,
	
	kSinh,
	kCosh,
	kTanh,
	
	kAsin,
	kAcos,
	kAtan,
	
	kAsinh,
	kAcosh,
	kAtanh,
	
	kMod,
	kFloor,
	kCeil,
	
	kPow,
	kAtan2,
	
	kInverse,
	kNearInt,
	kExp,
	kLog,
	kLog10,
	kSqrt,
	kRevSqrt,
	
	kOperationTypeCount
} OperationType;



class Operation
{
public:
	Operation()	{ memset(this, 0, sizeof(*this)); }

	OperationType type;

	int		input;	// kCopyVector
	double	value;	// kSplatConstant, kScalarAdd, kScalarMul
	
	int		pos1;	// Others (1 & 2 operands)
	int		pos2;	// Others (2 operands)
	
	int		temp;	// temp buffer index
};


class EquationState
{
public:
	EquationState()
	{
		mMaxInputs = 10;
		mResult = 0;
		mValid = true;
	}

	int addOperation(Operation o);
	string operationPlan();
	void optimizeOperations();
	
	void setResult(double r) { mResult = r; }
	double result()			{ return mResult; }
	
	void setMaxInputs(int m){ if (m < 0) m = 0; mMaxInputs = m; }
	int maxInputs()			{ return mMaxInputs; }
	
	int operationCount()	{ return mOperations.size(); }
	Operation operationAtIndex(int i)
	{
		int c = mOperations.size();
		assert(i >= 0 && i < c);
		return mOperations[i];
	}
	
	void clearOperations()	{ mOperations.clear(); }
	
	void setError(char *s)	{ mError = s; mValid = false; }
	string error()			{ return mError; }
	
	bool isValid()			{ return mValid; }
	
	void printOperations()	{ printf("%s", operationPlan().c_str()); }
	
private:
	vector<Operation>	mOperations;
	int					mMaxInputs;
	double				mResult;
	string				mError;
	bool				mValid;
};

double			parseSimpleEquation(const char *s);
EquationState	parseEquation(const char *s, int inputs);

#endif /* _EQUATION_H_ */

