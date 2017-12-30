/* A Bison parser, made by GNU Bison 2.1.  */

/* Skeleton parser for Yacc-like parsing with Bison,
   Copyright (C) 1984, 1989, 1990, 2000, 2001, 2002, 2003, 2004, 2005 Free Software Foundation, Inc.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2, or (at your option)
   any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.  */

/* As a special exception, when this file is copied by Bison into a
   Bison output file, you may use that output file without restriction.
   This special exception was added by the Free Software Foundation
   in version 1.24 of Bison.  */

/* Written by Richard Stallman by simplifying the original so called
   ``semantic'' parser.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output.  */
#define YYBISON 1

/* Bison version.  */
#define YYBISON_VERSION "2.1"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 1

/* Using locations.  */
#define YYLSP_NEEDED 0



/* Tokens.  */
#ifndef YYTOKENTYPE
# define YYTOKENTYPE
   /* Put the tokens into the symbol table, so that GDB and other debuggers
      know about them.  */
   enum yytokentype {
     tEnd = 258,
     tInvalid = 259,
     tFunc = 260,
     tInput = 261,
     tValue = 262,
     UMINUS = 263
   };
#endif
/* Tokens.  */
#define tEnd 258
#define tInvalid 259
#define tFunc 260
#define tInput 261
#define tValue 262
#define UMINUS 263




/* Copy the first part of user declarations.  */
//#line 4 "equation.y"

#include "equation.h"

typedef struct
{	
  	double					value;
  	int 					input;
	int						func;
	int						pos;
} tokenInfo;

typedef union
{
	tokenInfo ti; 
} YYSTYPE;
#define YYSTYPE YYSTYPE

/*
	Copyright 2005-2007 Antoine Missout
	Released under GPL.
	See http://www.gnu.org/copyleft/gpl.txt
*/


typedef struct
{
	const char 		*name;
	int				operands;
	OperationType	type;
	union
	{
		void	*v; // dummy
		double	(*f1)(double);
		double	(*f2)(double, double);
	} func;
} FunctionInfo;

static const char *gOperationNames[kOperationTypeCount] =
{
	"kSplatConstant",
	"kCopyVector",
	
	"kScalarAdd",
	"kScalarMul",
	
	"kAbs",
	"kMin",
	"kMax",
	
	"kAdd",
	"kSub",
	"kMul",
	"kDiv",
	"kNeg",
	
	"kSin",
	"kCos",
	"kTan",
	
	"kSinh",
	"kCosh",
	"kTanh",
	
	"kAsin",
	"kAcos",
	"kAtan",
	
	"kAsinh",
	"kAcosh",
	"kAtanh",
	
	"kMod",
	"kFloor",
	"kCeil",
	
	"kPow",
	"kAtan2",
	
	"kInverse",
	"kNearInt",
	"kExp",
	"kLog",
	"kLog10",
	"kSqrt",
	"kRevSqrt"
};

static double dInverse(double a) { return 1./a; }
static double dNearInt(double a) { return (a<0.) ? ceil(a-0.5) : floor(a+0.5); }
static double dRevSqrt(double a) { return 1./sqrt(a); }

static double dAbs(double a) { return (a < 0) ? (-a) : (a); }
static double dMin(double a, double b) { return (a < b) ? a : b; }
static double dMax(double a, double b) { return (a > b) ? a : b; }

static FunctionInfo gFunctionsInfos[] =
{
	{ "abs",		1, kAbs,	(void*) dAbs },
	{ "min",		2, kMin,	(void*) dMin },
	{ "max",		2, kMax,	(void*) dMax },

	{ "sin",		1, kSin,	(void*) sin },
	{ "cos",		1, kCos,	(void*) cos },
	{ "tan",		1, kTan,	(void*) tan },
	
	{ "sinh",		1, kSinh,	(void*) sinh },
	{ "cosh",		1, kCosh,	(void*) cosh },
	{ "tanh",		1, kTanh,	(void*) tanh },
	
	{ "asin",		1, kAsin,	(void*) asin },
	{ "acos",		1, kAcos,	(void*) acos },
	{ "atan",		1, kAtan,	(void*) atan },
	
	{ "asinh",		1, kAsinh,	(void*) asinh },
	{ "acosh",		1, kAcosh,	(void*) acosh },
	{ "atanh",		1, kAtanh,	(void*) atanh },
	
	{ "mod",		2, kMod,	(void*) fmod },
	{ "floor",		1, kFloor,	(void*) floor },
	{ "ceil",		1, kCeil,	(void*) ceil },
	
	{ "pow",		2, kPow,	(void*) pow },
	{ "atan2",		2, kAtan2,	(void*) atan2 },
	
	{ "inv",		1, kInverse,(void*) dInverse },
	{ "nearint",	1, kNearInt,(void*) dNearInt },
	{ "exp",		1, kExp,	(void*) exp },
	{ "log",		1, kLog,	(void*) log },
	{ "log10",		1, kLog10,	(void*) log10 },
	{ "sqrt",		1, kSqrt,	(void*) sqrt },
	{ "revsqrt",	1, kRevSqrt,(void*) dRevSqrt }
};

static const int gFunctionsCount = sizeof(gFunctionsInfos) / sizeof(FunctionInfo);

static int getFunction(const char *s)
{
	if (!s) return -1;
	for (int i = 0; i < gFunctionsCount; i++)
		if (strcmp(s, gFunctionsInfos[i].name) == 0)
			return i;
	return -1;
}

static int getFunctionOperands(int f)
{
	if (f < 0 || f >= gFunctionsCount) assert(0);
	return gFunctionsInfos[f].operands;
}

static OperationType getFunctionType(int f)
{
	if (f < 0 || f >= gFunctionsCount) assert(0);
	return gFunctionsInfos[f].type;
}

static double applyFunction1(int f, double a)
{
	if (f < 0 || f >= gFunctionsCount) assert(0);
	if (gFunctionsInfos[f].operands != 1) assert(0);
	return (gFunctionsInfos[f].func.f1)(a);
}

static double applyFunction2(int f, double a, double b)
{
	if (f < 0 || f >= gFunctionsCount) assert(0);
	if (gFunctionsInfos[f].operands != 2) assert(0);
	return (gFunctionsInfos[f].func.f2)(a, b);
}


typedef struct
{
	void *lex;
	EquationState eqs;
} State;

#define YY_DECL int yylex (YYSTYPE * yylval_param , void *yyscanner)
#define YYPARSE_PARAM scanner
#define mState ((State*)scanner)->eqs
#define YYLEX_PARAM ((State*)scanner)->lex

int EquationState::addOperation(Operation o)
{
	int p = mOperations.size();

	// quick check for equivalent operation
	for (int i = 0; i < p; i++)
	{
		OperationType t = mOperations[i].type;
		if (t == o.type)
		{
			if (t == kSplatConstant)
			{
				if (o.value == mOperations[i].value)
					return i+1;
			}
			else if (t == kCopyVector)
			{
				if (o.input == mOperations[i].input)
					return i+1;
			}
			else if (t == kScalarAdd || t == kScalarMul)
			{
				if (	o.pos1 == mOperations[i].pos1
					&&	o.value == mOperations[i].value)
					return i+1;
			}
			else
			{
				if (	o.pos1 == mOperations[i].pos1
					&&	o.pos2 == mOperations[i].pos2)
					return i+1;
			}
		}
		
	}
	
	o.temp = p;
	mOperations.push_back(o);

	return p+1;
}


string EquationState::operationPlan()
{
	ostringstream st;
	
	for (int i = 0; i < (int)mOperations.size(); i++)
	{
		OperationType t = mOperations[i].type;
		
		st << "t" << mOperations[i].temp << " = " << gOperationNames[t] << " ";
		
		if (t == kSplatConstant)
		{
			st << mOperations[i].value << "\n";
		}
		else if (t == kCopyVector)
		{
			st << "i" << mOperations[i].input << "\n";
		}
		else if (t == kScalarAdd || t == kScalarMul)
		{
			st << mOperations[i].value << " ";
			int p1 = mOperations[i].pos1;
			if (p1 < 0)
				st << "i" << (-p1 - 1) << "\n";
			else
				st << "t" << (p1 - 1) << "\n";
		}
		else
		{
			int p1 = mOperations[i].pos1;
			int p2 = mOperations[i].pos2;
			if (p2 != 0)
			{
				if (p1 < 0)
					st << "i" << (-p1 - 1) << " ";
				else
					st << "t" << (p1 - 1) << " ";
				
				if (p2 < 0)
					st << "i" << (-p2 - 1) << "\n";
				else
					st << "t" << (p2 - 1) << "\n";
			}
			else
			{
				if (p1 < 0)
					st << "i" << (-p1 - 1) << "\n";
				else
					st << "t" << (p1 - 1) << "\n";
			}
		}
	}
	
	return st.str();
}

void EquationState::optimizeOperations()
{
	int c = mOperations.size();
	
	for (int i = 0; i < c - 1; i++)
	{
		int t = mOperations[i].temp + 1;

		// check if used by a subsequent operation
		// starting after the next
		bool notUsed = true;
		for (int j = i+2; j < c; j++)
		{
			if (	mOperations[j].pos1 == t
				||	mOperations[j].pos2 == t)
			{
				notUsed = false;
				break;
			}
		}
			
		// if not, decrement all operations
		if (notUsed)
		{
			mOperations[i+1].temp--;
			for (int j = i+2; j < c; j++)
			{
				if (mOperations[j].pos1 > t) mOperations[j].pos1--;
				if (mOperations[j].pos2 > t) mOperations[j].pos2--;
				mOperations[j].temp--;
			}
		}
	}
}



#define yyerror(s) \
	do \
	{ \
		mState.setError(s); \
	} while(0) 

// forward decl.
YY_DECL;





/* Enabling traces.  */
#ifndef YYDEBUG
# define YYDEBUG 0
#endif

/* Enabling verbose error messages.  */
#ifdef YYERROR_VERBOSE
# undef YYERROR_VERBOSE
# define YYERROR_VERBOSE 1
#else
# define YYERROR_VERBOSE 0
#endif

/* Enabling the token table.  */
#ifndef YYTOKEN_TABLE
# define YYTOKEN_TABLE 0
#endif

#if ! defined (YYSTYPE) && ! defined (YYSTYPE_IS_DECLARED)
typedef int YYSTYPE;
# define yystype YYSTYPE /* obsolescent; will be withdrawn */
# define YYSTYPE_IS_DECLARED 1
# define YYSTYPE_IS_TRIVIAL 1
#endif



/* Copy the second part of user declarations.  */


/* Line 219 of yacc.c.  */
//#line 424 "equation.tab.c"

#if ! defined (YYSIZE_T) && defined (__SIZE_TYPE__)
# define YYSIZE_T __SIZE_TYPE__
#endif
#if ! defined (YYSIZE_T) && defined (size_t)
# define YYSIZE_T size_t
#endif
#if ! defined (YYSIZE_T) && (defined (__STDC__) || defined (__cplusplus))
# include <stddef.h> /* INFRINGES ON USER NAME SPACE */
# define YYSIZE_T size_t
#endif
#if ! defined (YYSIZE_T)
# define YYSIZE_T unsigned int
#endif

#ifndef YY_
# if YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(msgid) dgettext ("bison-runtime", msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(msgid) msgid
# endif
#endif

#if ! defined (yyoverflow) || YYERROR_VERBOSE

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if defined (__STDC__) || defined (__cplusplus)
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#     define YYINCLUDED_STDLIB_H
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's `empty if-body' warning. */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2005 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM ((YYSIZE_T) -1)
#  endif
#  ifdef __cplusplus
extern "C" {
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if (! defined (malloc) && ! defined (YYINCLUDED_STDLIB_H) \
	&& (defined (__STDC__) || defined (__cplusplus)))
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if (! defined (free) && ! defined (YYINCLUDED_STDLIB_H) \
	&& (defined (__STDC__) || defined (__cplusplus)))
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifdef __cplusplus
}
#  endif
# endif
#endif /* ! defined (yyoverflow) || YYERROR_VERBOSE */


#if (! defined (yyoverflow) \
     && (! defined (__cplusplus) \
	 || (defined (YYSTYPE_IS_TRIVIAL) && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  short int yyss;
  YYSTYPE yyvs;
  };

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (sizeof (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (sizeof (short int) + sizeof (YYSTYPE))			\
      + YYSTACK_GAP_MAXIMUM)

/* Copy COUNT objects from FROM to TO.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined (__GNUC__) && 1 < __GNUC__
#   define YYCOPY(To, From, Count) \
      __builtin_memcpy (To, From, (Count) * sizeof (*(From)))
#  else
#   define YYCOPY(To, From, Count)		\
      do					\
	{					\
	  YYSIZE_T yyi;				\
	  for (yyi = 0; yyi < (Count); yyi++)	\
	    (To)[yyi] = (From)[yyi];		\
	}					\
      while (0)
#  endif
# endif

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack)					\
    do									\
      {									\
	YYSIZE_T yynewbytes;						\
	YYCOPY (&yyptr->Stack, Stack, yysize);				\
	Stack = &yyptr->Stack;						\
	yynewbytes = yystacksize * sizeof (*Stack) + YYSTACK_GAP_MAXIMUM; \
	yyptr += yynewbytes / sizeof (*yyptr);				\
      }									\
    while (0)

#endif

#if defined (__STDC__) || defined (__cplusplus)
   typedef signed char yysigned_char;
#else
   typedef short int yysigned_char;
#endif

/* YYFINAL -- State number of the termination state. */
#define YYFINAL  16
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   118

/* YYNTOKENS -- Number of terminals. */
#define YYNTOKENS  16
/* YYNNTS -- Number of nonterminals. */
#define YYNNTS  4
/* YYNRULES -- Number of rules. */
#define YYNRULES  32
/* YYNRULES -- Number of states. */
#define YYNSTATES  59

/* YYTRANSLATE(YYLEX) -- Bison symbol number corresponding to YYLEX.  */
#define YYUNDEFTOK  2
#define YYMAXUTOK   263

#define YYTRANSLATE(YYX)						\
  ((unsigned int) (YYX) <= YYMAXUTOK ? yytranslate[YYX] : YYUNDEFTOK)

/* YYTRANSLATE[YYLEX] -- Bison symbol number corresponding to YYLEX.  */
static const unsigned char yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
      13,    14,    10,     8,    15,     9,     2,    11,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,    12
};

#if YYDEBUG
/* YYPRHS[YYN] -- Index of the first RHS symbol of rule number YYN in
   YYRHS.  */
static const unsigned char yyprhs[] =
{
       0,     0,     3,     6,     9,    12,    16,    21,    28,    35,
      42,    46,    50,    54,    58,    62,    66,    70,    74,    78,
      82,    86,    90,    93,    95,    99,   104,   111,   115,   119,
     123,   127,   130
};

/* YYRHS -- A `-1'-separated list of the rules' RHS. */
static const yysigned_char yyrhs[] =
{
      17,     0,    -1,    19,     3,    -1,    18,     3,    -1,     1,
       3,    -1,    13,    18,    14,    -1,     5,    13,    18,    14,
      -1,     5,    13,    18,    15,    18,    14,    -1,     5,    13,
      19,    15,    18,    14,    -1,     5,    13,    18,    15,    19,
      14,    -1,    18,     8,    18,    -1,    19,     8,    18,    -1,
      18,     8,    19,    -1,    18,     9,    18,    -1,    19,     9,
      18,    -1,    18,     9,    19,    -1,    18,    10,    18,    -1,
      19,    10,    18,    -1,    18,    10,    19,    -1,    18,    11,
      18,    -1,    19,    11,    18,    -1,    18,    11,    19,    -1,
       9,    18,    -1,     6,    -1,    13,    19,    14,    -1,     5,
      13,    19,    14,    -1,     5,    13,    19,    15,    19,    14,
      -1,    19,     8,    19,    -1,    19,     9,    19,    -1,    19,
      10,    19,    -1,    19,    11,    19,    -1,     9,    19,    -1,
       7,    -1
};

/* YYRLINE[YYN] -- source line where rule number YYN was defined.  */
static const unsigned short int yyrline[] =
{
       0,   336,   336,   337,   348,   353,   354,   370,   385,   406,
     427,   435,   445,   455,   463,   477,   487,   495,   505,   515,
     523,   537,   551,   559,   572,   574,   584,   594,   595,   596,
     597,   599,   600
};
#endif

#if YYDEBUG || YYERROR_VERBOSE || YYTOKEN_TABLE
/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals. */
static const char *const yytname[] =
{
  "$end", "error", "$undefined", "tEnd", "tInvalid", "tFunc", "tInput",
  "tValue", "'+'", "'-'", "'*'", "'/'", "UMINUS", "'('", "')'", "','",
  "$accept", "stmt", "vec", "cst", 0
};
#endif

# ifdef YYPRINT
/* YYTOKNUM[YYLEX-NUM] -- Internal token number corresponding to
   token YYLEX-NUM.  */
static const unsigned short int yytoknum[] =
{
       0,   256,   257,   258,   259,   260,   261,   262,    43,    45,
      42,    47,   263,    40,    41,    44
};
# endif

/* YYR1[YYN] -- Symbol number of symbol that rule YYN derives.  */
static const unsigned char yyr1[] =
{
       0,    16,    17,    17,    17,    18,    18,    18,    18,    18,
      18,    18,    18,    18,    18,    18,    18,    18,    18,    18,
      18,    18,    18,    18,    19,    19,    19,    19,    19,    19,
      19,    19,    19
};

/* YYR2[YYN] -- Number of symbols composing right hand side of rule YYN.  */
static const unsigned char yyr2[] =
{
       0,     2,     2,     2,     2,     3,     4,     6,     6,     6,
       3,     3,     3,     3,     3,     3,     3,     3,     3,     3,
       3,     3,     2,     1,     3,     4,     6,     3,     3,     3,
       3,     2,     1
};

/* YYDEFACT[STATE-NAME] -- Default rule to reduce with in state
   STATE-NUM when YYTABLE doesn't specify something else to do.  Zero
   means the default is an error.  */
static const unsigned char yydefact[] =
{
       0,     0,     0,    23,    32,     0,     0,     0,     0,     0,
       4,     0,    22,    31,     0,     0,     1,     3,     0,     0,
       0,     0,     2,     0,     0,     0,     0,     0,     0,     5,
      24,    10,    12,    13,    15,    16,    18,    19,    21,    11,
      27,    14,    28,    17,    29,    20,    30,     6,     0,    25,
       0,     0,     0,     0,     0,     7,     9,     8,    26
};

/* YYDEFGOTO[NTERM-NUM]. */
static const yysigned_char yydefgoto[] =
{
      -1,     7,     8,     9
};

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
#define YYPACT_NINF -8
static const yysigned_char yypact[] =
{
      33,     2,    15,    -8,    -8,    42,    42,    35,    -1,    49,
      -8,    42,    -8,    -8,    69,    76,    -8,    -8,    42,    42,
      42,    42,    -8,    42,    42,    42,    42,    53,    61,    -8,
      -8,    -7,    12,    -7,    12,    -8,    -8,    -8,    -8,    -7,
      12,    -7,    12,    -8,    -8,    -8,    -8,    -8,    42,    -8,
      42,    83,    90,    97,   104,    -8,    -8,    -8,    -8
};

/* YYPGOTO[NTERM-NUM].  */
static const yysigned_char yypgoto[] =
{
      -8,    -8,    -5,     6
};

/* YYTABLE[YYPACT[STATE-NUM]].  What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule which
   number is the opposite.  If zero, do what YYDEFACT says.
   If YYTABLE_NINF, syntax error.  */
#define YYTABLE_NINF -1
static const unsigned char yytable[] =
{
      12,    14,    17,    20,    21,    10,    27,    18,    19,    20,
      21,    13,    15,    31,    33,    35,    37,    28,    39,    41,
      43,    45,    25,    26,    32,    34,    36,    38,    11,    40,
      42,    44,    46,     0,     1,    16,     0,     0,     2,     3,
       4,     0,     5,    51,     0,    53,     6,     2,     3,     4,
       0,     5,    22,     0,    52,     6,    54,    23,    24,    25,
      26,    18,    19,    20,    21,     0,     0,    47,    48,    23,
      24,    25,    26,     0,     0,    49,    50,    18,    19,    20,
      21,     0,     0,    29,    23,    24,    25,    26,     0,     0,
      30,    18,    19,    20,    21,     0,     0,    55,    23,    24,
      25,    26,     0,     0,    56,    18,    19,    20,    21,     0,
       0,    57,    23,    24,    25,    26,     0,     0,    58
};

static const yysigned_char yycheck[] =
{
       5,     6,     3,    10,    11,     3,    11,     8,     9,    10,
      11,     5,     6,    18,    19,    20,    21,    11,    23,    24,
      25,    26,    10,    11,    18,    19,    20,    21,    13,    23,
      24,    25,    26,    -1,     1,     0,    -1,    -1,     5,     6,
       7,    -1,     9,    48,    -1,    50,    13,     5,     6,     7,
      -1,     9,     3,    -1,    48,    13,    50,     8,     9,    10,
      11,     8,     9,    10,    11,    -1,    -1,    14,    15,     8,
       9,    10,    11,    -1,    -1,    14,    15,     8,     9,    10,
      11,    -1,    -1,    14,     8,     9,    10,    11,    -1,    -1,
      14,     8,     9,    10,    11,    -1,    -1,    14,     8,     9,
      10,    11,    -1,    -1,    14,     8,     9,    10,    11,    -1,
      -1,    14,     8,     9,    10,    11,    -1,    -1,    14
};

/* YYSTOS[STATE-NUM] -- The (internal number of the) accessing
   symbol of state STATE-NUM.  */
static const unsigned char yystos[] =
{
       0,     1,     5,     6,     7,     9,    13,    17,    18,    19,
       3,    13,    18,    19,    18,    19,     0,     3,     8,     9,
      10,    11,     3,     8,     9,    10,    11,    18,    19,    14,
      14,    18,    19,    18,    19,    18,    19,    18,    19,    18,
      19,    18,    19,    18,    19,    18,    19,    14,    15,    14,
      15,    18,    19,    18,    19,    14,    14,    14,    14
};

#define yyerrok		(yyerrstatus = 0)
#define yyclearin	(yychar = YYEMPTY)
#define YYEMPTY		(-2)
#define YYEOF		0

#define YYACCEPT	goto yyacceptlab
#define YYABORT		goto yyabortlab
#define YYERROR		goto yyerrorlab


/* Like YYERROR except do call yyerror.  This remains here temporarily
   to ease the transition to the new meaning of YYERROR, for GCC.
   Once GCC version 2 has supplanted version 1, this can go.  */

#define YYFAIL		goto yyerrlab

#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)					\
do								\
  if (yychar == YYEMPTY && yylen == 1)				\
    {								\
      yychar = (Token);						\
      yylval = (Value);						\
      yytoken = YYTRANSLATE (yychar);				\
      YYPOPSTACK;						\
      goto yybackup;						\
    }								\
  else								\
    {								\
      yyerror (YY_("syntax error: cannot back up")); \
      YYERROR;							\
    }								\
while (0)


#define YYTERROR	1
#define YYERRCODE	256


/* YYLLOC_DEFAULT -- Set CURRENT to span from RHS[1] to RHS[N].
   If N is 0, then set CURRENT to the empty location which ends
   the previous symbol: RHS[0] (always defined).  */

#define YYRHSLOC(Rhs, K) ((Rhs)[K])
#ifndef YYLLOC_DEFAULT
# define YYLLOC_DEFAULT(Current, Rhs, N)				\
    do									\
      if (N)								\
	{								\
	  (Current).first_line   = YYRHSLOC (Rhs, 1).first_line;	\
	  (Current).first_column = YYRHSLOC (Rhs, 1).first_column;	\
	  (Current).last_line    = YYRHSLOC (Rhs, N).last_line;		\
	  (Current).last_column  = YYRHSLOC (Rhs, N).last_column;	\
	}								\
      else								\
	{								\
	  (Current).first_line   = (Current).last_line   =		\
	    YYRHSLOC (Rhs, 0).last_line;				\
	  (Current).first_column = (Current).last_column =		\
	    YYRHSLOC (Rhs, 0).last_column;				\
	}								\
    while (0)
#endif


/* YY_LOCATION_PRINT -- Print the location on the stream.
   This macro was not mandated originally: define only if we know
   we won't break user code: when these are the locations we know.  */

#ifndef YY_LOCATION_PRINT
# if YYLTYPE_IS_TRIVIAL
#  define YY_LOCATION_PRINT(File, Loc)			\
     fprintf (File, "%d.%d-%d.%d",			\
              (Loc).first_line, (Loc).first_column,	\
              (Loc).last_line,  (Loc).last_column)
# else
#  define YY_LOCATION_PRINT(File, Loc) ((void) 0)
# endif
#endif


/* YYLEX -- calling `yylex' with the right arguments.  */

#ifdef YYLEX_PARAM
# define YYLEX yylex (&yylval, YYLEX_PARAM)
#else
# define YYLEX yylex (&yylval)
#endif

/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)			\
do {						\
  if (yydebug)					\
    YYFPRINTF Args;				\
} while (0)

# define YY_SYMBOL_PRINT(Title, Type, Value, Location)		\
do {								\
  if (yydebug)							\
    {								\
      YYFPRINTF (stderr, "%s ", Title);				\
      yysymprint (stderr,					\
                  Type, Value);	\
      YYFPRINTF (stderr, "\n");					\
    }								\
} while (0)

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_stack_print (short int *bottom, short int *top)
#else
static void
yy_stack_print (bottom, top)
    short int *bottom;
    short int *top;
#endif
{
  YYFPRINTF (stderr, "Stack now");
  for (/* Nothing. */; bottom <= top; ++bottom)
    YYFPRINTF (stderr, " %d", *bottom);
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)				\
do {								\
  if (yydebug)							\
    yy_stack_print ((Bottom), (Top));				\
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yy_reduce_print (int yyrule)
#else
static void
yy_reduce_print (yyrule)
    int yyrule;
#endif
{
  int yyi;
  unsigned long int yylno = yyrline[yyrule];
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %lu), ",
             yyrule - 1, yylno);
  /* Print the symbols being reduced, and their result.  */
  for (yyi = yyprhs[yyrule]; 0 <= yyrhs[yyi]; yyi++)
    YYFPRINTF (stderr, "%s ", yytname[yyrhs[yyi]]);
  YYFPRINTF (stderr, "-> %s\n", yytname[yyr1[yyrule]]);
}

# define YY_REDUCE_PRINT(Rule)		\
do {					\
  if (yydebug)				\
    yy_reduce_print (Rule);		\
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args)
# define YY_SYMBOL_PRINT(Title, Type, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef	YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif



#if YYERROR_VERBOSE

# ifndef yystrlen
#  if defined (__GLIBC__) && defined (_STRING_H)
#   define yystrlen strlen
#  else
/* Return the length of YYSTR.  */
static YYSIZE_T
#   if defined (__STDC__) || defined (__cplusplus)
yystrlen (const char *yystr)
#   else
yystrlen (yystr)
     const char *yystr;
#   endif
{
  const char *yys = yystr;

  while (*yys++ != '\0')
    continue;

  return yys - yystr - 1;
}
#  endif
# endif

# ifndef yystpcpy
#  if defined (__GLIBC__) && defined (_STRING_H) && defined (_GNU_SOURCE)
#   define yystpcpy stpcpy
#  else
/* Copy YYSRC to YYDEST, returning the address of the terminating '\0' in
   YYDEST.  */
static char *
#   if defined (__STDC__) || defined (__cplusplus)
yystpcpy (char *yydest, const char *yysrc)
#   else
yystpcpy (yydest, yysrc)
     char *yydest;
     const char *yysrc;
#   endif
{
  char *yyd = yydest;
  const char *yys = yysrc;

  while ((*yyd++ = *yys++) != '\0')
    continue;

  return yyd - 1;
}
#  endif
# endif

# ifndef yytnamerr
/* Copy to YYRES the contents of YYSTR after stripping away unnecessary
   quotes and backslashes, so that it's suitable for yyerror.  The
   heuristic is that double-quoting is unnecessary unless the string
   contains an apostrophe, a comma, or backslash (other than
   backslash-backslash).  YYSTR is taken from yytname.  If YYRES is
   null, do not copy; instead, return the length of what the result
   would have been.  */
static YYSIZE_T
yytnamerr (char *yyres, const char *yystr)
{
  if (*yystr == '"')
    {
      size_t yyn = 0;
      char const *yyp = yystr;

      for (;;)
	switch (*++yyp)
	  {
	  case '\'':
	  case ',':
	    goto do_not_strip_quotes;

	  case '\\':
	    if (*++yyp != '\\')
	      goto do_not_strip_quotes;
	    /* Fall through.  */
	  default:
	    if (yyres)
	      yyres[yyn] = *yyp;
	    yyn++;
	    break;

	  case '"':
	    if (yyres)
	      yyres[yyn] = '\0';
	    return yyn;
	  }
    do_not_strip_quotes: ;
    }

  if (! yyres)
    return yystrlen (yystr);

  return yystpcpy (yyres, yystr) - yyres;
}
# endif

#endif /* YYERROR_VERBOSE */



#if YYDEBUG
/*--------------------------------.
| Print this symbol on YYOUTPUT.  |
`--------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yysymprint (FILE *yyoutput, int yytype, YYSTYPE *yyvaluep)
#else
static void
yysymprint (yyoutput, yytype, yyvaluep)
    FILE *yyoutput;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  if (yytype < YYNTOKENS)
    YYFPRINTF (yyoutput, "token %s (", yytname[yytype]);
  else
    YYFPRINTF (yyoutput, "nterm %s (", yytname[yytype]);


# ifdef YYPRINT
  if (yytype < YYNTOKENS)
    YYPRINT (yyoutput, yytoknum[yytype], *yyvaluep);
# endif
  switch (yytype)
    {
      default:
        break;
    }
  YYFPRINTF (yyoutput, ")");
}

#endif /* ! YYDEBUG */
/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

#if defined (__STDC__) || defined (__cplusplus)
static void
yydestruct (const char *yymsg, int yytype, YYSTYPE *yyvaluep)
#else
static void
yydestruct (yymsg, yytype, yyvaluep)
    const char *yymsg;
    int yytype;
    YYSTYPE *yyvaluep;
#endif
{
  /* Pacify ``unused variable'' warnings.  */
  (void) yyvaluep;

  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yytype, yyvaluep, yylocationp);

  switch (yytype)
    {

      default:
        break;
    }
}


/* Prevent warnings from -Wmissing-prototypes.  */

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM);
# else
int yyparse ();
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int yyparse (void);
#else
int yyparse ();
#endif
#endif /* ! YYPARSE_PARAM */






/*----------.
| yyparse.  |
`----------*/

#ifdef YYPARSE_PARAM
# if defined (__STDC__) || defined (__cplusplus)
int yyparse (void *YYPARSE_PARAM)
# else
int yyparse (YYPARSE_PARAM)
  void *YYPARSE_PARAM;
# endif
#else /* ! YYPARSE_PARAM */
#if defined (__STDC__) || defined (__cplusplus)
int
yyparse (void)
#else
int
yyparse ()
    ;
#endif
#endif
{
  /* The look-ahead symbol.  */
int yychar;

/* The semantic value of the look-ahead symbol.  */
YYSTYPE yylval;

/* Number of syntax errors so far.  */
int yynerrs;

  int yystate;
  int yyn;
  int yyresult;
  /* Number of tokens to shift before error messages enabled.  */
  int yyerrstatus;
  /* Look-ahead token as an internal (translated) token number.  */
  int yytoken = 0;

  /* Three stacks and their tools:
     `yyss': related to states,
     `yyvs': related to semantic values,
     `yyls': related to locations.

     Refer to the stacks thru separate pointers, to allow yyoverflow
     to reallocate them elsewhere.  */

  /* The state stack.  */
  short int yyssa[YYINITDEPTH];
  short int *yyss = yyssa;
  short int *yyssp;

  /* The semantic value stack.  */
  YYSTYPE yyvsa[YYINITDEPTH];
  YYSTYPE *yyvs = yyvsa;
  YYSTYPE *yyvsp;



#define YYPOPSTACK   (yyvsp--, yyssp--)

  YYSIZE_T yystacksize = YYINITDEPTH;

  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;


  /* When reducing, the number of symbols on the RHS of the reduced
     rule.  */
  int yylen;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yystate = 0;
  yyerrstatus = 0;
  yynerrs = 0;
  yychar = YYEMPTY;		/* Cause a token to be read.  */

  /* Initialize stack pointers.
     Waste one element of value and location stack
     so that they stay on the same level as the state stack.
     The wasted elements are never initialized.  */

  yyssp = yyss;
  yyvsp = yyvs;

  goto yysetstate;

/*------------------------------------------------------------.
| yynewstate -- Push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
 yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed. so pushing a state here evens the stacks.
     */
  yyssp++;

 yysetstate:
  *yyssp = yystate;

  if (yyss + yystacksize - 1 <= yyssp)
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYSIZE_T yysize = yyssp - yyss + 1;

#ifdef yyoverflow
      {
	/* Give user a chance to reallocate the stack. Use copies of
	   these so that the &'s don't force the real ones into
	   memory.  */
	YYSTYPE *yyvs1 = yyvs;
	short int *yyss1 = yyss;


	/* Each stack pointer address is followed by the size of the
	   data in use in that stack, in bytes.  This used to be a
	   conditional around just the two extra args, but that might
	   be undefined if yyoverflow is a macro.  */
	yyoverflow (YY_("memory exhausted"),
		    &yyss1, yysize * sizeof (*yyssp),
		    &yyvs1, yysize * sizeof (*yyvsp),

		    &yystacksize);

	yyss = yyss1;
	yyvs = yyvs1;
      }
#else /* no yyoverflow */
# ifndef YYSTACK_RELOCATE
      goto yyexhaustedlab;
# else
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
	goto yyexhaustedlab;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
	yystacksize = YYMAXDEPTH;

      {
	short int *yyss1 = yyss;
	union yyalloc *yyptr =
	  (union yyalloc *) YYSTACK_ALLOC (YYSTACK_BYTES (yystacksize));
	if (! yyptr)
	  goto yyexhaustedlab;
	YYSTACK_RELOCATE (yyss);
	YYSTACK_RELOCATE (yyvs);

#  undef YYSTACK_RELOCATE
	if (yyss1 != yyssa)
	  YYSTACK_FREE (yyss1);
      }
# endif
#endif /* no yyoverflow */

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;


      YYDPRINTF ((stderr, "Stack size increased to %lu\n",
		  (unsigned long int) yystacksize));

      if (yyss + yystacksize - 1 <= yyssp)
	YYABORT;
    }

  YYDPRINTF ((stderr, "Entering state %d\n", yystate));

  goto yybackup;

/*-----------.
| yybackup.  |
`-----------*/
yybackup:

/* Do appropriate processing given the current state.  */
/* Read a look-ahead token if we need one and don't already have one.  */
/* yyresume: */

  /* First try to decide what to do without reference to look-ahead token.  */

  yyn = yypact[yystate];
  if (yyn == YYPACT_NINF)
    goto yydefault;

  /* Not known => get a look-ahead token if don't already have one.  */

  /* YYCHAR is either YYEMPTY or YYEOF or a valid look-ahead symbol.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token: "));
      yychar = YYLEX;
    }

  if (yychar <= YYEOF)
    {
      yychar = yytoken = YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yyn == 0 || yyn == YYTABLE_NINF)
	goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  /* Shift the look-ahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);

  /* Discard the token being shifted unless it is eof.  */
  if (yychar != YYEOF)
    yychar = YYEMPTY;

  *++yyvsp = yylval;


  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  yystate = yyn;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- Do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     `$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
        case 2:
//#line 336 "equation.y"
    { mState.setResult((yyvsp[-1].ti).value); YYACCEPT; ;}
    break;

  case 3:
//#line 337 "equation.y"
    {
	 						if (mState.operationCount() == 0)
	 						{
	 							Operation o;
	 							o.type = kCopyVector;
	 							o.input = -(yyvsp[-1].ti).pos -1;
	 								
	 							mState.addOperation(o);
	 						}
	 						YYACCEPT;
	 					;}
    break;

  case 4:
//#line 348 "equation.y"
    { mState.clearOperations(); YYABORT; ;}
    break;

  case 5:
//#line 353 "equation.y"
    {    (yyval.ti)  =  (yyvsp[-1].ti);  ;}
    break;

  case 6:
//#line 354 "equation.y"
    {
	 								int op = getFunctionOperands((yyvsp[-3].ti).func);
	 								if (op != 1)
	 								{
	 									yyerror("Wrong operand count in function call");
	 									YYERROR;
	 								}
	 								
	 								Operation o;
	 								o.type = getFunctionType((yyvsp[-3].ti).func);
	 								o.pos1 = (yyvsp[-1].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 7:
//#line 370 "equation.y"
    {
	 								int op = getFunctionOperands((yyvsp[-5].ti).func);
	 								if (op != 2)
	 								{
	 									yyerror("Wrong operand count in function call");
	 									YYERROR;
	 								}

	 								Operation o;
	 								o.type = getFunctionType((yyvsp[-5].ti).func);
	 								o.pos1 = (yyvsp[-3].ti).pos;
	 								o.pos2 = (yyvsp[-1].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 8:
//#line 385 "equation.y"
    {
	 								int op = getFunctionOperands((yyvsp[-5].ti).func);
	 								if (op != 2)
	 								{
	 									yyerror("Wrong operand count in function call");
	 									YYERROR;
	 								}

	 								Operation o;
	 								
	 								o.type = kSplatConstant;
	 								o.value = (yyvsp[-3].ti).value;
	 								
	 								int p = mState.addOperation(o);
	 								
	 								o.type = getFunctionType((yyvsp[-5].ti).func);
	 								o.pos1 = p;
	 								o.pos2 = (yyvsp[-1].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 9:
//#line 406 "equation.y"
    {
	 								int op = getFunctionOperands((yyvsp[-5].ti).func);
	 								if (op != 2)
	 								{
	 									yyerror("Wrong operand count in function call");
	 									YYERROR;
	 								}

	 								Operation o;
	 								
	 								o.type = kSplatConstant;
	 								o.value = (yyvsp[-1].ti).value;
	 								
	 								int p = mState.addOperation(o);
	 								
	 								o.type = getFunctionType((yyvsp[-5].ti).func);
	 								o.pos1 = (yyvsp[-3].ti).pos;
	 								o.pos2 = p;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 10:
//#line 427 "equation.y"
    {
	 								Operation o;
	 								o.type = kAdd;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = (yyvsp[0].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 11:
//#line 435 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kScalarAdd;
	 								o.value = (yyvsp[-2].ti).value;
	 								o.pos1 = (yyvsp[0].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 12:
//#line 445 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kScalarAdd;
	 								o.value = (yyvsp[0].ti).value;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 13:
//#line 455 "equation.y"
    {
	 								Operation o;
	 								o.type = kSub;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = (yyvsp[0].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 14:
//#line 463 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kSplatConstant;
	 								o.value = (yyvsp[-2].ti).value;
	 								
	 								int p = mState.addOperation(o);
	 								
	 								o.type = kSub;
	 								o.pos1 = p;
	 								o.pos2 = (yyvsp[0].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 15:
//#line 477 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kScalarAdd;
	 								o.value = - ((yyvsp[0].ti).value);
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 16:
//#line 487 "equation.y"
    {
	 								Operation o;
	 								o.type = kMul;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = (yyvsp[0].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 17:
//#line 495 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kScalarMul;
	 								o.value = (yyvsp[-2].ti).value;
	 								o.pos1 = (yyvsp[0].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 18:
//#line 505 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kScalarMul;
	 								o.value = (yyvsp[0].ti).value;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 19:
//#line 515 "equation.y"
    {
	 								Operation o;
	 								o.type = kDiv;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = (yyvsp[0].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 20:
//#line 523 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kSplatConstant;
	 								o.value = (yyvsp[-2].ti).value;
	 								
	 								int p = mState.addOperation(o);
	 								
	 								o.type = kDiv;
	 								o.pos1 = p;
	 								o.pos2 = (yyvsp[0].ti).pos;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 21:
//#line 537 "equation.y"
    {
	 								Operation o;
	 								
	 								o.type = kSplatConstant;
	 								o.value = (yyvsp[0].ti).value;
	 								
	 								int p = mState.addOperation(o);
	 								
	 								o.type = kDiv;
	 								o.pos1 = (yyvsp[-2].ti).pos;
	 								o.pos2 = p;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 22:
//#line 551 "equation.y"
    {
	 								Operation o;
	 								o.type = kNeg;
	 								o.pos1 = (yyvsp[0].ti).pos;
	 								o.pos2 = 0;
	 								
	 								(yyval.ti).pos = mState.addOperation(o);
	 							;}
    break;

  case 23:
//#line 559 "equation.y"
    {
	 								if ((yyvsp[0].ti).input >= mState.maxInputs())
	 								{
	 									yyerror("Incorrect input index");
	 									YYERROR;
	 								}
	 								
	 								(yyval.ti).pos = -((yyvsp[0].ti).input) - 1;
	 							;}
    break;

  case 24:
//#line 572 "equation.y"
    {    (yyval.ti).value  =  (yyvsp[-1].ti).value;  ;}
    break;

  case 25:
//#line 574 "equation.y"
    {
	 								int op = getFunctionOperands((yyvsp[-3].ti).func);
	 								if (op != 1)
	 								{
	 									yyerror("Wrong operand count in function call");
	 									YYERROR;
	 								}
	 								(yyval.ti).value = applyFunction1((yyvsp[-3].ti).func, (yyvsp[-1].ti).value);
	 							;}
    break;

  case 26:
//#line 584 "equation.y"
    {
	 								int op = getFunctionOperands((yyvsp[-5].ti).func);
	 								if (op != 2)
	 								{
	 									yyerror("Wrong operand count in function call");
	 									YYERROR;
	 								}
	 								(yyval.ti).value = applyFunction2((yyvsp[-5].ti).func, (yyvsp[-3].ti).value, (yyvsp[-1].ti).value);
	 							;}
    break;

  case 27:
//#line 594 "equation.y"
    {    (yyval.ti).value = (yyvsp[-2].ti).value  +  (yyvsp[0].ti).value;  ;}
    break;

  case 28:
//#line 595 "equation.y"
    {    (yyval.ti).value = (yyvsp[-2].ti).value  -  (yyvsp[0].ti).value;  ;}
    break;

  case 29:
//#line 596 "equation.y"
    {    (yyval.ti).value = (yyvsp[-2].ti).value  *  (yyvsp[0].ti).value;  ;}
    break;

  case 30:
//#line 597 "equation.y"
    {    (yyval.ti).value = (yyvsp[-2].ti).value  /  (yyvsp[0].ti).value;  ;}
    break;

  case 31:
//#line 599 "equation.y"
    {    (yyval.ti).value = -((yyvsp[0].ti).value);	;}
    break;

  case 32:
//#line 600 "equation.y"
    {    (yyval.ti).value = (yyvsp[0].ti).value; 		;}
    break;


      default: break;
    }

/* Line 1126 of yacc.c.  */
//#line 1838 "equation.tab.c"

  yyvsp -= yylen;
  yyssp -= yylen;


  YY_STACK_PRINT (yyss, yyssp);

  *++yyvsp = yyval;


  /* Now `shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */

  yyn = yyr1[yyn];

  yystate = yypgoto[yyn - YYNTOKENS] + *yyssp;
  if (0 <= yystate && yystate <= YYLAST && yycheck[yystate] == *yyssp)
    yystate = yytable[yystate];
  else
    yystate = yydefgoto[yyn - YYNTOKENS];

  goto yynewstate;


/*------------------------------------.
| yyerrlab -- here on detecting error |
`------------------------------------*/
yyerrlab:
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
#if YYERROR_VERBOSE
      yyn = yypact[yystate];

      if (YYPACT_NINF < yyn && yyn < YYLAST)
	{
	  int yytype = YYTRANSLATE (yychar);
	  YYSIZE_T yysize0 = yytnamerr (0, yytname[yytype]);
	  YYSIZE_T yysize = yysize0;
	  YYSIZE_T yysize1;
	  int yysize_overflow = 0;
	  char *yymsg = 0;
#	  define YYERROR_VERBOSE_ARGS_MAXIMUM 5
	  char const *yyarg[YYERROR_VERBOSE_ARGS_MAXIMUM];
	  int yyx;

#if 0
	  /* This is so xgettext sees the translatable formats that are
	     constructed on the fly.  */
	  YY_("syntax error, unexpected %s");
	  YY_("syntax error, unexpected %s, expecting %s");
	  YY_("syntax error, unexpected %s, expecting %s or %s");
	  YY_("syntax error, unexpected %s, expecting %s or %s or %s");
	  YY_("syntax error, unexpected %s, expecting %s or %s or %s or %s");
#endif
	  char *yyfmt;
	  char const *yyf;
	  static char const yyunexpected[] = "syntax error, unexpected %s";
	  static char const yyexpecting[] = ", expecting %s";
	  static char const yyor[] = " or %s";
	  char yyformat[sizeof yyunexpected
			+ sizeof yyexpecting - 1
			+ ((YYERROR_VERBOSE_ARGS_MAXIMUM - 2)
			   * (sizeof yyor - 1))];
	  char const *yyprefix = yyexpecting;

	  /* Start YYX at -YYN if negative to avoid negative indexes in
	     YYCHECK.  */
	  int yyxbegin = yyn < 0 ? -yyn : 0;

	  /* Stay within bounds of both yycheck and yytname.  */
	  int yychecklim = YYLAST - yyn;
	  int yyxend = yychecklim < YYNTOKENS ? yychecklim : YYNTOKENS;
	  int yycount = 1;

	  yyarg[0] = yytname[yytype];
	  yyfmt = yystpcpy (yyformat, yyunexpected);

	  for (yyx = yyxbegin; yyx < yyxend; ++yyx)
	    if (yycheck[yyx + yyn] == yyx && yyx != YYTERROR)
	      {
		if (yycount == YYERROR_VERBOSE_ARGS_MAXIMUM)
		  {
		    yycount = 1;
		    yysize = yysize0;
		    yyformat[sizeof yyunexpected - 1] = '\0';
		    break;
		  }
		yyarg[yycount++] = yytname[yyx];
		yysize1 = yysize + yytnamerr (0, yytname[yyx]);
		yysize_overflow |= yysize1 < yysize;
		yysize = yysize1;
		yyfmt = yystpcpy (yyfmt, yyprefix);
		yyprefix = yyor;
	      }

	  yyf = YY_(yyformat);
	  yysize1 = yysize + yystrlen (yyf);
	  yysize_overflow |= yysize1 < yysize;
	  yysize = yysize1;

	  if (!yysize_overflow && yysize <= YYSTACK_ALLOC_MAXIMUM)
	    yymsg = (char *) YYSTACK_ALLOC (yysize);
	  if (yymsg)
	    {
	      /* Avoid sprintf, as that infringes on the user's name space.
		 Don't have undefined behavior even if the translation
		 produced a string with the wrong number of "%s"s.  */
	      char *yyp = yymsg;
	      int yyi = 0;
	      while ((*yyp = *yyf))
		{
		  if (*yyp == '%' && yyf[1] == 's' && yyi < yycount)
		    {
		      yyp += yytnamerr (yyp, yyarg[yyi++]);
		      yyf += 2;
		    }
		  else
		    {
		      yyp++;
		      yyf++;
		    }
		}
	      yyerror (yymsg);
	      YYSTACK_FREE (yymsg);
	    }
	  else
	    {
	      yyerror (YY_("syntax error"));
	      goto yyexhaustedlab;
	    }
	}
      else
#endif /* YYERROR_VERBOSE */
	yyerror (YY_("syntax error"));
    }



  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse look-ahead token after an
	 error, discard it.  */

      if (yychar <= YYEOF)
        {
	  /* Return failure if at end of input.  */
	  if (yychar == YYEOF)
	    YYABORT;
        }
      else
	{
	  yydestruct ("Error: discarding", yytoken, &yylval);
	  yychar = YYEMPTY;
	}
    }

  /* Else will try to reuse look-ahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:

  /* Pacify compilers like GCC when the user code never invokes
     YYERROR and the label yyerrorlab therefore never appears in user
     code.  */
  if (0)
     goto yyerrorlab;

yyvsp -= yylen;
  yyssp -= yylen;
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;	/* Each real token shifted decrements this.  */

  for (;;)
    {
      yyn = yypact[yystate];
      if (yyn != YYPACT_NINF)
	{
	  yyn += YYTERROR;
	  if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYTERROR)
	    {
	      yyn = yytable[yyn];
	      if (0 < yyn)
		break;
	    }
	}

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
	YYABORT;


      yydestruct ("Error: popping", yystos[yystate], yyvsp);
      YYPOPSTACK;
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  if (yyn == YYFINAL)
    YYACCEPT;

  *++yyvsp = yylval;


  /* Shift the error token. */
  YY_SYMBOL_PRINT ("Shifting", yystos[yyn], yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturn;

/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturn;

#ifndef yyoverflow
/*-------------------------------------------------.
| yyexhaustedlab -- memory exhaustion comes here.  |
`-------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  /* Fall through.  */
#endif

yyreturn:
  if (yychar != YYEOF && yychar != YYEMPTY)
     yydestruct ("Cleanup: discarding lookahead",
		 yytoken, &yylval);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
		  yystos[*yyssp], yyvsp);
      YYPOPSTACK;
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif
  return yyresult;
}


//#line 606 "equation.y"


#include "lex.yy.c"

double parseSimpleEquation(const char *s)
{
	State state;
	state.eqs.setMaxInputs(0);

	int err;
	err = yylex_init(&(state.lex));
	if (err) return 0;

	if (*s == '=') s++;
	yy_scan_string(s, state.lex);
	
	err = yyparse(&state);
	yylex_destroy(state.lex);	
	
	if (err) return 0;
	else return state.eqs.result();
}

EquationState parseEquation(const char *s, int inputs)
{
	State state;
	state.eqs.setMaxInputs(inputs);

	int err;
	err = yylex_init(&(state.lex));
	if (err) return state.eqs;

	if (*s == '=') s++;
	yy_scan_string(s, state.lex);
	
	err = yyparse(&state);
	yylex_destroy(state.lex);	
	
	if (err) state.eqs.clearOperations();
	else state.eqs.optimizeOperations();
	
	return state.eqs;
}

/*
int main(int argc, char** argv)
{
	if (argc < 2) return 1;
	
	EquationState st = parseEquation(argv[1], 10);
	
	if (!st.isValid())
	{
		printf("%s\n", st.error().c_str());
	}
	else
	{
		if (st.operationCount() == 0)
		{
			printf("result: %f\n", st.result());
		}
		else
		{
			st.optimizeOperations();
			st.printOperations();
		}
	}

	return 0;
}
*/


