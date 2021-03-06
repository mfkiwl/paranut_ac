/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2015 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  This program is free software: you can redistribute it and/or modify
  it under the terms of the GNU General Public License as published by
  the Free Software Foundation, either version 3 of the License, or
  (at your option) any later version.

  This program is distributed in the hope that it will be useful,
  but WITHOUT ANY WARRANTY; without even the implied warranty of
  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
  GNU General Public License for more details.

  You should have received a copy of the GNU General Public License
  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 
 *************************************************************************/



#include "base.h"

#include <stdio.h>
#include <string.h>
#include <stdarg.h>
#include <float.h>

#include <systemc.h>



// *********** Dynamic Configuration ************


int cfgVcdLevel = 2;
int cfgInsnTrace = 0;
int cfgDisableCache = 0;





// **************** Tracing *********************


bool trace_verbose = false;


char *GetTraceName (sc_object *obj, const char *name, int dim, int arg1, int arg2) {
  static char buf[200];
  char *p;

  strcpy (buf, obj->name ());
  //strcpy (buf, ((sc_object *) obj)->name ());
  p = strrchr (buf, '.');
  p = p ? p+1 : buf;
  sprintf (p, dim == 0 ? "%s" : dim == 1 ? "%s(%i)" : "%s(%i)(%i)", name, arg1, arg2);
  // printf ("### %s, %i, %i, %i -> %s\n", ((sc_object *) obj)->name (), dim, arg1, arg2, buf);
  return buf;
}





// **************** Testbench helpers ***********


sc_trace_file *trace_file = NULL;


char *TbPrintf (const char *format, ...) {
  static char buf[200];

  va_list ap;
  va_start (ap, format);
  vsprintf (buf, format, ap);
  return buf;
}


void TbAssert (bool cond, const char *msg, const char *fileName, const int lineNo) {
  if (!cond) {
    fprintf (stderr, "ASSERTION FAILURE: %s, %s:%i", sc_time_stamp ().to_string ().c_str (), fileName, lineNo);
    if (msg) fprintf (stderr, ": %s\n", msg);
    else fprintf (stderr, "\n");
    sc_start (1, SC_NS);
    if (trace_file) sc_close_vcd_trace_file (trace_file);
    abort ();
  }
}


void TbInfo (const char *msg, const char *fileName, const int lineNo) {
  fprintf (stderr, "INFO:%15s, %s:%i: %s\n", sc_time_stamp ().to_string ().c_str (), fileName, lineNo, msg);
}


void TbWarning (const char *msg, const char *fileName, const int lineNo) {
  fprintf (stderr, "WARNING:%12s, %s:%i: %s\n", sc_time_stamp ().to_string ().c_str (), fileName, lineNo, msg);
}


void TbError (const char *msg, const char *fileName, const int lineNo) {
  fprintf (stderr, "ERROR:%14s, %s:%i: %s\n", sc_time_stamp ().to_string ().c_str (), fileName, lineNo, msg);
  exit (3);
}





// **************** DisAss **********************


char *DisAss (TWord insn) {
  static char ret[80] = "";
  TWord opcode, subcode, a, b, d, i16z, i16s, i162z, i162s, i26z, i26s, bits_9_8, bits_7_6, bits_3_0, bits_10_5, bits_4_0;

  opcode = insn >> 26;

  d = (insn >> 21) & 0x1f;
  a = (insn >> 16) & 0x1f;
  b = (insn >> 11) & 0x1f;
  i16z = insn & 0x0000ffff;
  i16s = (i16z ^ 0x00008000) - 0x00008000;
  i162z = (insn & 0x000007ff) + ((insn & 0x03e00000) >> 10);
  i162s = (i162z ^ 0x00008000) - 0x00008000;
  i26z = (insn & 0x03ffffff);
  i26s = (i26z ^ 0x02000000) - 0x02000000;

  bits_9_8 = (insn >> 8) & 0x3;
  bits_7_6 = (insn >> 6) & 0x3;
  bits_3_0 = insn & 0x0f;
  bits_10_5 = (insn >> 5) & 0x3f;
  bits_4_0 = insn & 0x1f;

  strcpy (ret, "l.");

  // ALU instructions...
  if (opcode == 0x38 && bits_9_8 == 0 && bits_3_0 <= 5) {
    static const char *table [] = { "add", "addc", "sub", "and", "or", "xor" };
    sprintf (ret+2, "%s r%i, r%i, r%i", table [bits_3_0], d, a, b);
  }
  else if (opcode == 0x38 && bits_9_8 == 0 && bits_3_0 == 0x8) {
    static const char *table [] = { "sll", "srl", "sra", "ror_" };
    sprintf (ret+2, "%s r%i, r%i, r%i", table [bits_7_6], d, a, b);
  }
  else if (opcode == 0x38 && bits_9_8 == 0 && bits_3_0 == 0xc) {
    static const char *table [] = { "exths_", "extbs_", "exthz_", "extbz_" };
    sprintf (ret+2, "%s r%i, r%i", table [bits_7_6], d, a);
  }
  else if (opcode == 0x38 && bits_9_8 == 0 && bits_3_0 == 0xe) {
    sprintf (ret+2, "cmov r%i, r%i, r%i", d, a, b);
  }
  else if (opcode == 0x38 && bits_9_8 == 3 && (bits_3_0 == 6 || (bits_3_0 >= 0x9 && bits_3_0 <= 0xb))) {
    static const char *table [] = { "mul", "", "", "div_", "divu_", "mulu" };
    sprintf (ret+2, "%s r%i, r%i, r%i", table [bits_3_0] - 6, d, a, b);
  }
  else if (opcode == 0x38 && bits_7_6 <= 1 && bits_3_0 == 0xf) {
    static const char *table [] = { "ff1_", "fl1_" };
    sprintf (ret+2, "%s r%i, r%i", table [bits_7_6], d, a);
  }
  else if (opcode == 0x39 && (d <= 0x5 || (d >= 0xa && d <= 0xd))) {
    static const char *table [] = { "sfeq", "sfne", "sfgtu", "sfgeu", "sfltu", "sfleu", "", "", "", "",
                              "sfgts", "sfges", "sflts", "sfles" };
    sprintf (ret+2, "%s r%i, r%i", table [d], a, b);
  }
  else if (opcode >= 0x27 && opcode <= 0x2c) {
    static const char *table [] = { "addi", "addic", "andi", "ori", "xori", "muli" };
    sprintf (ret+2, "%s r%i, r%i, 0x%x", table [opcode - 0x27], d, a, (opcode == 0x29 || opcode == 0x2a) ? i16z : i16s);
  }
  else if (opcode == 0x2f && (d <= 0x5 || (d >= 0xa && d <= 0xd))) {
    static const char *table [] = { "sfeqi", "sfnei", "sfgtui", "sfgeui", "sfltui", "sfleui", "", "", "", "",
                                    "sfgtsi", "sfgesi", "sfltsi", "sflesi" };
    sprintf (ret+2, "%s r%i, %i", table [d], a, d >= 2 && d <= 5 ? i16z : i16s);
  }
  else if (opcode == 0x2e) {
    static const char *table [] = { "slli_", "srli_", "srai_", "rori_" };
    sprintf (ret+2, "%s r%i, r%i, %i", table[bits_7_6], d, a, bits_4_0);
  }
  else if (opcode == 0x06 && (insn & 0x00010000) == 0) {
    sprintf (ret+2, "movhi r%i, 0x%x", d, i16z);
  }
  // MAC instructions skipped

  // Load/Store instructions...
  else if (opcode >= 0x21 && opcode <= 0x26) {
    static const char *table [] = { "lwz", "lws", "lbz", "lbs", "lhz", "lhs" };
    sprintf (ret+2, "%s r%i, 0x%x(r%i)", table [opcode - 0x21], d, i16s, a);
  }
  else if (opcode >= 0x35 && opcode <= 0x37) {
    static const char *table [] = { "sw", "sb", "sh" };
    sprintf (ret+2, "%s 0x%x(r%i), r%i", table [opcode - 0x35], i162s, a, b);
  }

  // Jumps...
  else if (opcode <= 0x01 || (opcode >= 0x03 && opcode <= 0x04)) {
    static const char *table [] = { "j", "jal", "", "bnf", "bf" };
    sprintf (ret+2, "%s %i", table [opcode], 4 * i26s);
  }
  else if (opcode == 0x05 && (d & 0x18) == 0x08) {
    sprintf (ret+2, "nop %i", i16z);
  }
  else if (opcode >= 0x11 && opcode <= 0x12) {
    sprintf (ret+2, "%s r%i", opcode == 0x11 ? "jr" : "jalr", b);
  }
  else if (opcode == 0x08 && a == 0 && (d == 0 || d == 0x08)) {
    sprintf (ret+2, d == 0 ? "sys" : "trap_");
  }
  else if (opcode == 0x09) {
    sprintf (ret+2, "rfe");
  }

  // Other...
  else if (opcode == 0x2d) {
    sprintf (ret+2, "mfspr r%i, r%i, %i", d, a, i16z);
  }
  else if (opcode == 0x30) {
    sprintf (ret+2, "mtspr r%i, r%i, %i", a, b, i162z);
  }
  else if (opcode == 0x08 && (d == 0x10 || d == 0x14 || d == 0x18)) {
    static const char *table [] = { "msync_", "psync_", "csync_" };
    sprintf (ret+2, table[(d >> 2) - 4]);
  }

  // ParaNut extensions...
  else if (opcode == 0x3e) {
    static const char *table [] = { "cwriteback", "cinvalidate", "cflush" };
    sprintf (ret, "pn.%s 0x%x(r%i)", table [(b & 3)-1], i162s, a);
  }

  // Unknown & custom instruction...
  else if (opcode >= 0x1c && opcode <= 0x1f) {
    sprintf (ret+2, "cust%i_ 0x%07x", opcode - 0x1b, i26z);
  }
  else if (opcode >= 0x3c) {
    sprintf (ret+2, "cust%i_ r%i, r%i, r%i, %i, %i", d, a, b, bits_10_5, bits_4_0);
  }

  else sprintf (ret, "? 0x%08x ?", insn);

  return ret;
}





// **************** Performance measuring *****************


void CPerfMon::Init (int _events, CEventDef *_evTab) {
  int n;

  events = _events;
  evTab = _evTab;
  countTab = new int [_events];
  timeTab = new double [_events];
  minTab = new double [_events];
  maxTab = new double [_events];
  Reset ();
}


void CPerfMon::Done () {
  if (events > 0) {
    delete [] countTab;
    delete [] timeTab;
    delete [] minTab;
    delete [] maxTab;
  }
}


void CPerfMon::Reset () {
  int n;

  lastEvNo = -1;
  for (n = 0; n < events; n++) {
    countTab [n] = 0;
    timeTab [n] = maxTab[n] = 0.0;
    minTab[n] = DBL_MAX;
  }
}


void CPerfMon::Count (int evNo) {
  double curStamp, t;

  curStamp = sc_time_stamp ().to_double ();
  if (lastEvNo >= 0) {
    if (evTab [lastEvNo].isTimed) {
      t = curStamp - lastStamp;
      timeTab [lastEvNo] += t;
      if (t < minTab[lastEvNo]) minTab[lastEvNo] = t;
      if (t > maxTab[lastEvNo]) maxTab[lastEvNo] = t;
    }
  }
  countTab [evNo]++;
  if (evTab [evNo].isTimed) lastStamp = curStamp;
  lastEvNo = evNo;
}


static void DisplayLine (const char *name, int count, int avgCount, double total, double min, double max, bool isTimed) {
  if (avgCount > 0 && isTimed)
    printf ("(perf)   %-10s %7i   %8.1lf %8.1lf %8.1lf %11.1lf\n", name, count, min, total / avgCount, max, total);
  else
    printf ("(perf)   %-10s %7i\n", name, count);
}


void CPerfMon::Display (char *name) {
  double timeTotal, minTotal, maxTotal;
  int countTotal, avgCountTotal, n;

  printf ("(perf)\n"
          "(perf) ********** Performance statics ");
  if (name) printf ("of unit '%s'", name);
  printf ("\n"
          "(perf)\n"
          "(perf)                          Time [ns]\n"
          "(perf)   Event        Count        min      avg      max       Total\n"
          "(perf)   -----------------------------------------------------------\n");
  countTotal = avgCountTotal = 0;
  timeTotal = maxTotal = 0.0;
  minTotal = DBL_MAX;
  for (n = 0; n < events; n++) {
    DisplayLine (evTab[n].name, countTab [n], countTab [n], timeTab[n], minTab[n], maxTab[n], evTab[n].isTimed);
    countTotal += countTab[n];
    if (evTab[n].isTimed) avgCountTotal += countTab[n];
    timeTotal += timeTab[n];
    if (minTab[n] < minTotal) minTotal = minTab[n];
    if (maxTab[n] > maxTotal) maxTotal = maxTab[n];
  }
  printf ("(perf)   -----------------------------------------------------------\n");
  DisplayLine ("Total", countTotal, avgCountTotal, timeTotal, minTotal, maxTotal, true);
  printf ("(perf)\n");
}





// ***** CPerfMonCPU *****


void CPerfMonCPU::Init () {
  static CEventDef eventDef [] = {
    { "ALU", true },
    { "Load", true },
    { "Store", true },
    { "Jump", true },
    { "Other", true }
  };
  CPerfMon::Init (5, eventDef);
}
