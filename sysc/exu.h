/*************************************************************************

  This file is part of the ParaNut project.
 
  (C) 2010-2013 Gundolf Kiefer <gundolf.kiefer@hs-augsburg.de>
      Hochschule Augsburg, University of Applied Sciences

  Description:
    This is a SystemC model of the execution unit (EXU) of the ParaNut.
    The EXU contains the ALU, the register file, the capability to
    decode instructions. It interfaces with the IFU and the LSU.

 *************************************************************************/


#ifndef _EXU_
#define _EXU_

#include "base.h"

#include <systemc.h>


#define REGISTERS 32
#define DELAY_ALU 1  // NOTE: Other values not supported
#define DELAY_MUL 3


#define LINK_REGISTER 9    // R9 is the link register according to the OR1k manual


typedef enum {
  afAdd = 0x0,   // also: adress calculations for load/store/jumps
  afAdc = 0x1,
  afSub = 0x2,   // also: sf... instructions
  afAnd = 0x3,
  afOr  = 0x4,   // also: mfspr, mtspr
  afXor = 0x5,
  afMul = 0x6,
  afSxx = 0x8,   // includes: sll=00, srl=01, sra=10, ror=11 (subcode in 7:6)
  afDiv = 0x9,   // optional, not implemented
  afDivu = 0xa,  // optional, not implemented
  afMulu = 0xb,
  afExt = 0xc,   // includes: exths=00, extbs=01, exthz=10, exths=11 (subcode in 7:6)
  afCmov = 0xe,
  afFx1 = 0xf,   // includes: ff1=00, fl1=01 (subcode in 7:6); optional, not implemented

  afMovhi = 0x10,
} EAluFunc;


typedef enum {
  aaReg = 0x10,
  aaPc = 0
} EAluASrc;


typedef enum {
  abReg = 0x10,
  abImm16s = 0,
  abImm16z,
  abImm16hi,  // for: movhi
  abImm162s,  // for: sw/sh/sb, mtspr
  abImm26s,   // for: j, jal, bnf, bf
} EAluBSrc;





// **************** MExu ************************


SC_MODULE(MExu) {
public:

  // Ports ...
  sc_in<bool> clk, reset;

  //   to IFU ...
  sc_out<bool> ifu_next, ifu_jump;
  sc_out<TWord> ifu_jump_adr;   // jump adress
  sc_in<bool> ifu_ir_valid, ifu_npc_valid;
  sc_in<TWord> ifu_ir, ifu_ppc, ifu_pc, ifu_npc;   // expected to be registered (fast) outputs

  //   to Load/Store Unit (LSU)...
  sc_out<bool> lsu_rd, lsu_wr, lsu_flush, lsu_cache_invalidate, lsu_cache_writeback;
  sc_in<bool> lsu_ack;
  sc_out<sc_uint<2> > lsu_width;  // "00" = word, "01" = byte, "10" = half word
  sc_out<bool> lsu_exts;
  sc_out<TWord> lsu_adr;
  sc_in<TWord> lsu_rdata;
  sc_out<TWord> lsu_wdata;

  //   controller outputs...
  sc_out<bool> icache_enable, dcache_enable;

  //   TBD: timer, interrupt controller ...

  // Constructor...
  SC_HAS_PROCESS (MExu);
  MExu (sc_module_name name, bool _inCePU, int _modeCap) : sc_module (name) {
    // '_inCePU' indicates whether the surrounding CPU is the CePU.
    // '_modeCap' indicates the maximum mode suppported.
    // The (only) possible combinations of ('_inCePU', '_modeCap') are:
    //    (true, 3)    // CePU, all capabilities
    //    (false, 2)   // CoPU supporting modes 0-2
    //    (false, 1)   // CoPU supporting modes 0-1 (no unlinked mode)
    assert ((_inCePU && _modeCap == 3) || (!_inCePU && _modeCap >= 1 && _modeCap <= 2));

    SC_CTHREAD (MainThread, clk.pos ());
      reset_signal_is (reset, true);
    SC_METHOD (OutputThread);
      sensitive << regICE << regDCE;

    inCePU = _inCePU;
    modeCap = _modeCap;
  }

  // Functions...
  void Trace (sc_trace_file *tf, int levels = 1);
  void DisplayStatistics () { return perfMon.Display (); }

  bool IsHalted () { return mode == 0; }

  // Processes...
  void MainThread ();
  void OutputThread () { icache_enable = regICE && !cfgDisableCache; dcache_enable = regDCE && !cfgDisableCache; }

protected:

  // Configuration ...
  bool inCePU;
  int modeCap;

  // CPU registers...
  sc_signal<TWord>
    regFile[REGISTERS];
  sc_signal<TWord>
    regEPCR, regEEAR, regESR;
  sc_signal<bool>
    regCY, regOV, regF,
    regSUMRA,   // SPR User Mode Read Access
    regDSX,     // Delay Slot Exception (DSX) (1: EPCR points to insn in delay slot)
    regICE, regDCE,     // Instruction Cache Enable (ICE) and Data Cache Enable (DCE)
    regIEE;     // Interrupt Exception Enable (IEE)

  // CPU registers (no SystemC registers yet)...
  int mode;

  // Helper methods...
  int RunAlu (sc_uint<32> insn, EAluFunc aluFunc, EAluASrc aSrc, EAluBSrc bSrc,
              bool setRegD, bool setCyOv, bool setF, TWord *retOutRegD = NULL);
  void SetSpr (TWord regNo, TWord val);
  TWord GetSpr (TWord regNo);

  void DumpRegisterInfo ();

  // Performance Monitor...
  CPerfMonCPU perfMon;
};


#endif
