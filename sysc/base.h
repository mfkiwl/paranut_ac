/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This module contains various types, constants and helper functions
    for the SystemC model of ParaNut.

 *************************************************************************/


#ifndef _BASE_
#define _BASE_



// Static Configuration...

#define PN_BIG_ENDIAN 1



// Dynamic Configuration...

extern int cfgVcdLevel;       // VCD trace level (0 = no VCD file)
extern int cfgInsnTrace;      // if set, simulation info is printed with each instruction
extern int cfgDisableCache;   // if set, caching is disabled by the EXUs, independent of the ICE/DCE flag




// Basic types and constants...

#define KB 1024
#define MB (1024 * 1024)
#define GB (1024 * 1024 * 1024)

typedef unsigned char TByte;
typedef unsigned THalfWord;
typedef unsigned TWord;

#define MIN(A, B) ((A) < (B) ? (A) : (B))
#define MAX(A, B) ((A) > (B) ? (A) : (B))



// SystemC tracing...

#include <systemc.h>

extern bool trace_verbose;


char *GetTraceName (sc_object *obj, const char *name, int dim, int arg1, int arg2);
// char *GetTraceName (void *obj, const char *name, int dim, int arg1, int arg2);   // 'obj' is of type 'sc_object' (try to avoid including systemc.h here)


#define TRACE(TF, OBJ) {                                                                      \
  if (TF) sc_trace (TF, OBJ, GetTraceName (&(OBJ), #OBJ, 0, 0, 0));                           \
  if (!TF || trace_verbose) cout << "  " #OBJ " = '" << (OBJ).name () << "'\n";               \
}


#define TRACE_BUS(TF, OBJ, N_MAX) {                                                           \
  for (int n = 0; n < N_MAX; n++) {                                                           \
    if (TF) sc_trace (TF, (OBJ)[n], GetTraceName (&(OBJ)[n], #OBJ, 1, n, 0));                 \
    if (!TF || trace_verbose)                                                                 \
      cout << "  " #OBJ "[" << n << "] = '" << (OBJ)[n].name () << "'\n";                     \
  }                                                                                           \
}

#define TRACE_BUS_BUS(TF, OBJ, N_MAX, K_MAX) {                                                \
  for (int n = 0; n < N_MAX; n++) for (int k = 0; k < K_MAX; k++) {                           \
    if (TF) sc_trace (TF, (OBJ)[n][k], GetTraceName (&(OBJ)[n][k], #OBJ, 2, n, k));           \
    if (!TF || trace_verbose)                                                                 \
      cout << "  " #OBJ "[" << n << "][" << k << "] = '" << (OBJ)[n][k].name () << "'\n";     \
  }                                                                                           \
}


#define PRINT(OBJ) TRACE(NULL, OBJ)
#define PRINT_BUS(OBJ, N_MAX) TRACE_BUS(NULL, OBJ, N_MAX)
#define PRINT_BUS_BUS(OBJ, N_MAX, K_MAX) TRACE_BUS(NULL, OBJ, N_MAX, K_MAX)





// **************** Testbench helpers ***********


extern sc_trace_file *trace_file;

char *TbPrintf (const char *format, ...);
void TbAssert (bool cond, const char *msg, const char *fileName, const int lineNo);
void TbInfo (const char *msg, const char *fileName, const int lineNo);
void TbWarning (const char *msg, const char *fileName, const int lineNo);
void TbError (const char *msg, const char *fileName, const int lineNo);


/*
char *TbStringF (const char *format, ...) {
}
*/


#define ASSERT(COND) TbAssert (COND, NULL, __FILE__, __LINE__)
#define ASSERTF(COND, FMT) TbAssert (COND, TbPrintf FMT, __FILE__, __LINE__)
#define ASSERTM(COND, MSG) TbAssert (COND, MSG, __FILE__, __LINE__)

#define INFO(MSG) TbInfo (MSG, __FILE__, __LINE__)
#define INFOF(FMT) TbInfo (TbPrintf FMT, __FILE__, __LINE__)

#define WARNING(MSG) TbWarning (MSG, __FILE__, __LINE__)
#define WARNINGF(FMT) TbWarning (TbPrintf FMT, __FILE__, __LINE__)

#define ERROR(MSG) TbError (MSG, __FILE__, __LINE__)
#define ERRORF(FMT) TbError (TbPrintf FMT, __FILE__, __LINE__)



// Functions...

char *DisAss (TWord insn);  // disassemble OR32 instruction; return string valid until next call to this function





// **************** Performance measuring *****************


class CEventDef {
public:
  const char *name;
  bool isTimed;
};


class CPerfMon {
public:
  CPerfMon () { Init (0, NULL); }
  CPerfMon (int _events, CEventDef *_evTab) { Init (_events, _evTab); }
  ~CPerfMon () { Done (); }

  void Init (int _events, CEventDef *_evTab);
  void Done ();

  void Reset ();
  void Count (int evNo);

  void Display (char *name = NULL);

protected:
  int events;
  CEventDef *evTab;
  int *countTab;
  double *timeTab, *minTab, *maxTab;

  double lastStamp;
  int lastEvNo;
};



// ***** CPerfMonCPU *****


typedef enum {
  evALU = 0,
  evLoad,
  evStore,
  evJump,
  evOther
} EEventsCPU;


class CPerfMonCPU: public CPerfMon {
public:
  CPerfMonCPU () { Init (); }
  void Init ();

  void Count (EEventsCPU _evNo) { CPerfMon::Count ((int) _evNo); }
};



#endif
