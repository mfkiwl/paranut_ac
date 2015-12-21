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


#include "exu.h"

#include <assert.h>

#include "memory.h"  // only for debugging 'mainMemory'





// **************** Tracing *********************


void MExu::Trace (sc_trace_file *tf, int level) {
  if (!tf || trace_verbose)
    printf ("\nSignals of Module \"%s\":\n", name ());

  // Ports ...
  TRACE (tf, clk);
  TRACE (tf, reset);
  //   to IFU ...
  TRACE (tf, ifu_next);
  TRACE (tf, ifu_jump);
  TRACE (tf, ifu_jump_adr);
  TRACE (tf, ifu_ir_valid);
  TRACE (tf, ifu_npc_valid);
  TRACE (tf, ifu_ir);
  TRACE (tf, ifu_ppc);
  TRACE (tf, ifu_pc);
  TRACE (tf, ifu_npc);
  //   to Load/Store Unit (LSU)...
  TRACE (tf, lsu_rd);
  TRACE (tf, lsu_wr);
  TRACE (tf, lsu_flush);
  TRACE (tf, lsu_cache_invalidate);
  TRACE (tf, lsu_cache_writeback);
  TRACE (tf, lsu_ack);
  TRACE (tf, lsu_width);
  TRACE (tf, lsu_exts);
  TRACE (tf, lsu_adr);
  TRACE (tf, lsu_rdata);
  TRACE (tf, lsu_wdata);

  // Registers...
  TRACE_BUS (tf, regFile, REGISTERS);
  //TRACE (tf, regLR);
  TRACE (tf, regEPCR);
  TRACE (tf, regEEAR);
  TRACE (tf, regESR);
  TRACE (tf, regCY);
  TRACE (tf, regOV);
  TRACE (tf, regF);
  TRACE (tf, regSUMRA);
  TRACE (tf, regDSX);
  TRACE (tf, regICE);
  TRACE (tf, regDCE);
  TRACE (tf, regIEE);
}





// **************** Special Registers ***********


typedef enum {

  // Group 0...
  sprVR = 0,        // VR   - Version register
  sprUPR,           // UPR  - Unit Present register
  sprCPUCFGR,       // CPUCFGR   - CPU Configuration register

  sprDMMUCFGR,      // DMMUCFGR  - Data MMU Configuration register
  sprIMMUCFGR,      // IMMUCFGR  - Instruction MMU Configuration register
  sprDCCFGR,        // DCCFGR    - Data Cache Configuration register
  sprICCFGR,        // ICCFGR    - Instruction Cache Configuration register
  sprDCFGR,         // DCFGR     - Debug Configuration register
  sprPCCFGR,        // PCCFGR    - Performance Counters Configuration register

  sprPC = 16,       // PC        - PC mapped to SPR space (NOTE: NPC according to OR1k, PC according to OR1200!)
  sprSR,            // SR        - Supervision register
  sprPPC,           // PPC       - PC mapped to SPR space (previous PC)
  sprFPCSR = 20,    // FPCSR     - FP Control/Status register

  sprEPCR0 = 32,    // EPCR0-EPCR15 - Exception PC registers
  sprEEAR0 = 48,    // EEAR0-EEAR15 - Exception EA registers
  sprESR0 = 64,     // ESR0-ESR15   - Exception SR registers
  sprGPR0 = 1024,    // GPR0-GPR511  - GPRs mapped to SPR space

  // Group 1 (Data MMU)... (group 2 / IMMU decoded into group 1)
  // Group 3 (Data Cache)... (group 4 / ICache decoded into group 3)
  // Group 6 (Debug)...
  // Group 7 (Performance Counters)...
  // Group 9 (Programmable Interrupt Controler)...
  // Group 10 (Tick Timer)...
  // Group 24 (ParaNut SPR)...
  sprPNCPUS  = 	0xC000,
  	//PNCPUID; Blatt daheim, nachher!!!
  sprPNM2CAP = 	0xC020,
  sprPNCE 	  = 	0xC040,
  sprPNLM 	  = 	0xC060,
  sprPNX 	  = 	0xC080,
  sprPNXID0  = 	0xC400

} ESpr;




TWord MExu::GetSpr (TWord _regNo) {
  ESpr regNo = (ESpr) _regNo;
  sc_uint<32> flags;

  //INFOF (("GetSpr: Reading from SPR 0x%x", _regNo));

  if (regNo >= sprEPCR0 && regNo <= sprEPCR0+15) {        // EPCR0-EPCR15 - Exception PC registers
    return regEPCR;
  }
  else if (regNo >= sprEEAR0 && regNo <= sprEEAR0+15) {   // EEAR0-EEAR15 - Exception EA registers
    return regEEAR;
  }
  else if (regNo >= sprESR0 && regNo <= sprESR0+15) {     // ESR0-ESR15   - Exception SR registers
    return regESR;
  }
  else if (regNo >= sprGPR0 && regNo <= sprGPR0+511) {    // GPR0-GPR511  - GPRs mapped to SPR space
    ERROR(("GetSpr: GPRs not supported / should be handled by main controler"));
  }
  else switch (regNo) {
    case sprVR:
      return 0x01000000;   // VER = 0x01, CFG = 0x00, REV = 0x0000
    case sprUPR:
      return 0x00000007;   // present: UP(0), DCP(1), ICP(2), nothing else
    case sprCPUCFGR:       // CPUCFGR   - CPU Configuration register
      return 0x00000020 + (REGISTERS == 32 ? 0x10 : 0);
    case sprDMMUCFGR:      // DMMUCFGR  - Data MMU Configuration register
    case sprIMMUCFGR:      // IMMUCFGR  - Instruction MMU Configuration register
      return 0;     // TBD-MMU
    case sprDCCFGR:        // DCCFGR    - Data Cache Configuration register
    case sprICCFGR:        // ICCFGR    - Instruction Cache Configuration register
      return 0;     // TBD
    case sprDCFGR:         // DCFGR     - Debug Configuration register
      return 0;
    case sprPCCFGR:        // PCCFGR    - Performance Counters Configuration register
      return 0;
    case sprPC:            // NPC       - R/W  PC mapped to SPR space (next PC)
      return ifu_pc;
    case sprPPC:           // PPC       - PC mapped to SPR space (previous PC)
      return ifu_ppc;
    case sprFPCSR:         // FPCSR     - FP Control/Status register
      return 0;
    case sprSR:            // SR        - Supervision register
      flags = (sc_uint<4> (0),     // Context ID (CID)
               sc_uint<11> (0),  // reserved
               regSUMRA,   // SPR User Mode Read Access
               1,          // Fixed One (FO)
               0,          // Exception Prefix High (EPH)
               regDSX,     // Delay Slot Exception (DSX) (1: EPCR points to insn in delay slot)
               0,          // Overflow flag exception (OVE) (1: overflow causes exception)
               regOV, regCY, regF,    // flags: OV, CY and F
               0,          // CID enable (CE),
               0,          // little endian enable (LEE))
               0,          // Insn MMU Enable (IME),
               0,          // Data MMU Enable (DME); map to IME?
               regICE, regDCE, // Instruction Cache Enable (ICE), Data Cache Enable (DCE)
               regIEE,     // Interrupt Exception Enable (IEE)
               0,          // Tick Timer Exception Enable (TEE)
               1);         // Supervisor Mode (SM)
      //INFOF (("GetSpr: Reading SR: 0x%0x, regICE = %i, regDCE = %i", flags.value (), (int) regICE, (int) regDCE));
      return flags.value();
	//PNSPR---
      case sprPNCPUS:
	return CPU_CORES;
      case sprPNM2CAP:
	return CPU_CORES_CAP;
      case sprPNCE:
	return regCPUEN;
      case sprPNLM:
	return regLM;
      case sprPNX:
	return regXT;
      case sprPNXID0:
	return regXID; 
    default:
      ERRORF(("SetSpr: Read access to unknown SPR 0x%04x", _regNo));
      assert (false); // unknown SPR
  }
}


void MExu::SetSpr (TWord _regNo, TWord _val) {
  ESpr regNo = (ESpr) _regNo;
  sc_uint<32> val = _val;

  //INFOF (("SetSpr: Writing 0x%x to SPR 0x%x", _val, _regNo));

  if (regNo >= sprEPCR0 && regNo <= sprEPCR0+15) {        // EPCR0-EPCR15 - Exception PC registers
    WARNING(("SetSpr: SPR write to EPCRn - against specification"));
    regEPCR = val;
  }
  else if (regNo >= sprEEAR0 && regNo <= sprEEAR0+15) {   // EEAR0-EEAR15 - Exception EA registers
    WARNING(("SetSpr: ignoring SPR write to EEARn - against specification"));
  }
  else if (regNo >= sprESR0 && regNo <= sprESR0+15) {     // ESR0-ESR15   - Exception SR registers
    WARNING(("SetSpr: ignoring SPR write to ESRn - against specification"));
  }
  else if (regNo >= sprGPR0 && regNo <= sprGPR0+511) {    // GPR0-GPR511  - GPRs mapped to SPR space
    ERROR(("SetSpr: GPRs not supported / should be handled by main controller"));
  }
  else switch (regNo) {
    case sprSR:            // SR        - Supervision register
      //INFOF (("SetSpr: Setting SR to 0x%0x, regICE = %i, regDCE = %i", (int) val, (int) val[4], (int) val[3]));
      regSUMRA = val[16];
      // regDSX = val[13];   // handled as read-only (spec. not clear whether r/w is required)
      regOV = val[11];
      regCY = val[10];
      regF = val[9];
      regICE = val[4];
      regDCE = val[3];
      regIEE = val[2];
      break;
    case sprPNCE:
      regCPUEN = val;
      break;
    case sprPNLM:
      regLM = val;
      break;
    default:
      WARNINGF(("SetSpr: SPR write to read-only register 0x%04x", _regNo));
  }
}





// **************** ALU *************************


int MExu::RunAlu (sc_uint<32> insn, EAluFunc aluFunc, EAluASrc aSrc, EAluBSrc bSrc,
                  bool setRegD, bool setCyOv, bool setF, TWord *retOutRegD) {
  // 'opcode' is only used for immediate values and:
  // - subcode 7:6 for sll/srl/sra/ror, extXX, ff1/fl1
  // - subcode 26:21 (= b) for sfXXX
  //
  // Return value: Number of required clock cycles

  sc_uint<5> d = insn.range (25, 21), a = insn.range (20, 16), b = insn.range (15, 11);
  sc_uint<32> inA, inB, outRegD, minusInB;
  bool outCY = 0, outOV = 0, outF = 0, haveCyOv = 0;
  bool zero, lt;
  sc_uint<33> result, signedB;
  int retDelay, n;

  retDelay = DELAY_ALU;

  // Determine inputs...
  switch (aSrc) {
    case aaPc:
      inA = ifu_pc;
      break;
    default:
      inA = regFile[a];
  }
  switch (bSrc) {
    case abImm16z:
      inB = insn & 0xffff;
      break;
    case abImm16s:
      inB = ((insn & 0xffff) ^ 0x8000) - 0x8000;
      break;
    case abImm16hi:
      inB = (insn & 0xffff) << 16;
      break;
    case abImm162s:
      inB = (insn & 0x000007ff) + ((insn & 0x03e00000) >> 10);
      inB = (inB ^ 0x8000) - 0x8000;
      break;
    case abImm26s:
      inB = (insn & 0x03ffffff);
      inB = (inB ^ 0x02000000) - 0x02000000;
      inB <<= 2;
      break;
    default:
      inB = regFile[b];
  }

  // Run ALU operation...
  switch (aluFunc) {

    // Add/sub...
    case afAdd:
    case afAdc:
    case afSub:
      if (aluFunc != afSub) signedB = ('0', inB);
      else signedB = -('0', inB);
      result = ('0', inA) + signedB;
      if (aluFunc == afAdc) result += regCY;
  
      outRegD = result.range (31, 0);
      outCY = result [32];
      outOV = (inA[31] & signedB[31] & ~outRegD[31]) | (~inA[31] & ~signedB[31] & outRegD[31]);
  
      // compute comparison flag 'outFlag'...
      zero = (outRegD == 0);
      if (d[3]) lt = (outCY & !(inA[31] ^ inB[31])) | (inA[31] & !inB[31]);   // "less than" for signed comparison
      else      lt = outCY;                                                // "less than" for unsigned comparison
      if (d <= 1)                 // ==, !=
        outF = (d[0] ^ zero);
      else {                      // other cases
        if (d[1] == 0) outF = lt;  // "less than" and "less or equal"
        else outF = !lt;    // "greater than" and "greater or equal"
        if (d[1] != d[0]) outF = outF ^ zero;  // "less or equal" and "greater than"
      }
      haveCyOv = 1;
      // INFOF (("Comparing 0x%x and 0x%x: zero = %i, C = %i, F = %i", (int) inA, (int) inB, (int) zero, (int) outCY, (int) outF));
      break;

    // Logical...
    case afAnd:
      outRegD = inA & inB;
      break;
    case afOr:
      outRegD = inA | inB;
      break;
    case afXor:
      outRegD = inA ^ inB;
      break;

    // Multiplication...
    case afMulu:
      outRegD = sc_uint<64> (inA) * sc_uint<64> (inB);
      //outCY = (outRegD (63, 32) > 0);
      // TBD: outCY, outOV?
      haveCyOv = 1;
      retDelay = DELAY_MUL;
      break;
    case afMul:
      outRegD = sc_int<64> (inA) * sc_int<64> (inB);
      // TBD: outCY, outOV?
      haveCyOv = 1;
      retDelay = DELAY_MUL;
      break;

    // Shift & Rotation...
    case afSxx:
      n = inB.range (4, 0);
      if (n > 0) switch (insn.range (7, 6).value()) {
        case 0: // sll
          outRegD = ( inA.range (31-n, 0), sc_uint<32> (0).range (n-1, 0) );
          break;
        case 1: // srl
          outRegD = ( sc_uint<32> (0).range (n-1, 0), inA.range (31, n) );
          break;
        case 2: // sra
          outRegD = ( sc_uint<32> (inA[31] == 1 ? -1 : 0).range (n-1, 0), inA.range (31, n) );
          break;
        case 3: // ror
          outRegD = ( inA.range (31-n, 0), inA.range (31, n) );
          break;
      }
      else outRegD = inA;
      retDelay = MAX(n, 1);   // assume sequential shift
      break;

    // Byte & half word extensions...
    case afExt:
      switch (insn.range (7, 6).value()) {
        case 0:
          outRegD = inA & 0xffff;
          outRegD = (outRegD ^ 0x8000) - 0x8000;
          break;
        case 1:
          outRegD = inA & 0xff;
          outRegD = (outRegD ^ 0x80) - 0x80;
          break;
        case 2:
          outRegD = inA & 0xffff;
          break;
        case 3:
          outRegD = inA & 0xff;
          break;
      }
      break;

    // MOVHI...
    case afMovhi:
      outRegD = inB;
      break;

    // CMOV...
    case afCmov:
      outRegD = regF ? inA : inB;
      break;

    // Unimplemented...
    case afDiv:
    case afDivu:
    case afFx1:
    default:
      assert (false);   // illegal function
  }

  // Write back results as requested...
  if (setRegD) regFile[d] = outRegD;
  if (setCyOv && haveCyOv) {
    regCY = outCY;
    regOV = outOV;
  }
  if (setF) regF = outF;

  // return
  if (retOutRegD) *retOutRegD = outRegD;
  return retDelay;
}



void MExu::DumpRegisterInfo () {
  INFOF (("   (%s)  F=%i C=%i O=%i  R1=%08x  R2=%08x  R3=%08x  R4=%08x  R5=%08x  R6=%08x  R7=%08x",
          strrchr (name (), '.') + 1,
          regF.read (), regCY.read (), regOV.read (), regFile[1].read (), regFile[2].read (), regFile[3].read (),
          regFile[4].read (), regFile[5].read (), regFile[6].read (), regFile[7].read ()));
  INFOF (("   (%s)  R8=%08x  R9=%08x R10=%08x R11=%08x R12=%08x R13=%08x R14=%08x R15=%08x",
          strrchr (name (), '.') + 1,
          regFile[8].read (), regFile[9].read (), regFile[10].read (), regFile[11].read (),
          regFile[12].read (), regFile[13].read (), regFile[14].read (), regFile[15].read ()));
  INFOF (("   (%s) R16=%08x R17=%08x R18=%08x R19=%08x R20=%08x R21=%08x R22=%08x R23=%08x",
          strrchr (name (), '.') + 1,
          regFile[16].read (), regFile[17].read (), regFile[18].read (), regFile[19].read (),
          regFile[20].read (), regFile[21].read (), regFile[22].read (), regFile[23].read ()));
  INFOF (("   (%s) R24=%08x R25=%08x R26=%08x R27=%08x R28=%08x R29=%08x R30=%08x R31=%08x",
          strrchr (name (), '.') + 1,
          regFile[24].read (), regFile[25].read (), regFile[26].read (), regFile[27].read (),
          regFile[28].read (), regFile[29].read (), regFile[30].read (), regFile[31].read ()));
}





// **************** Main ************************


void MExu::MainThread () {
  sc_uint<32> insn;
  int opcode, delay;
  EAluFunc aluFunc;
  bool illOp, signExt;
  // Variables for exception handling (may become registers later)
  int exceptId;  // 0 = no exception
  bool exceptRestart;
  bool inDelaySlot, nextInDelaySlot;

  // Reset...
  mode = inCePU ? 3 : 0;
  inDelaySlot = nextInDelaySlot = 0;
  ifu_next = 0;
  exceptId = 0;

  //   initialize internal registers...
  regICE = 0;  // disable instruction caching
  regDCE = 0;  // disable data caching
  regIEE = 0;  // disable interrupts

  // Main loop...
  while (true) {
    regFile[0] = 0;   // R0 is always zero

    // wait (1);

    // preset control signals ...
    ifu_next = 0;
    ifu_jump = 0;

    lsu_rd = 0;
    lsu_wr = 0;
    lsu_cache_invalidate = 0;
    lsu_cache_writeback = 0;

    wait (1);  // to let the current IFU outputs propagate to this EXU...

    if (ifu_ir_valid == 1) {

      // Decode instruction...
      insn = ifu_ir;
      opcode = insn.range (31, 26);
      illOp = 0;
      inDelaySlot = nextInDelaySlot;
      nextInDelaySlot = 0;

      if (cfgInsnTrace) {
        DumpRegisterInfo ();
        INFOF (("   (%s)", strrchr (name (), '.') + 1));
        //mainMemory->Dump (0x12d88, 0x12d90);
        //INFOF (("   (%s)", strrchr (name (), '.') + 1));
        INFOF (("   (%s) %s", strrchr (name (), '.') + 1, mainMemory->GetDumpStr ((TWord) ifu_pc.read ())));
      }

      // Perform instruction...
      if (opcode == 0x38) {
        // (ALU) ALU without immediate...
        perfMon.Count (evALU);
        aluFunc = (EAluFunc) insn.range (3, 0).value ();
        delay = RunAlu (insn, aluFunc, aaReg, abReg, 1, 1, 0);
        if (delay > 1) wait (delay - 1);
        ifu_next = 1;
        wait (1);
      }
      else if (opcode == 0x39) {
        // (ALU) Set-flag without immediate...
        perfMon.Count (evALU);
        delay = RunAlu (insn, afSub, aaReg, abReg, 0, 0, 1);
        if (delay > 1) wait (delay - 1);
        ifu_next = 1;
        wait (1);
      }
      else if (opcode >= 0x27 && opcode <= 0x2c) {
        // (ALU) ALU with immediate...
        perfMon.Count (evALU);
        static const EAluFunc aluFuncTable [] = { afAdd, afAdc, afAnd, afOr, afXor, afMul };
        static const bool signExtTable []     = {     1,     1,     0,    0,     1,     1 };
        aluFunc = aluFuncTable [opcode - 0x27];
        signExt = signExtTable [opcode - 0x27];
        delay = RunAlu (insn, aluFunc, aaReg, signExt ? abImm16s : abImm16z, 1, 1, 0);
        if (delay > 1) wait (delay - 1);
        ifu_next = 1;
        wait (1);
      }
      else if (opcode == 0x2e) {
        // (ALU) Shift & rotate with immediate...
        perfMon.Count (evALU);
        delay = RunAlu (insn, afSxx, aaReg, abImm16s, 1, 1, 0);
        if (delay > 1) wait (delay - 1);
        ifu_next = 1;
        wait (1);
      }

      else if (opcode == 0x2f) {
        // (ALU) Set-flag with immediate...
        perfMon.Count (evALU);
        delay = RunAlu (insn, afSub, aaReg, abImm16s, 0, 0, 1);
        if (delay > 1) wait (delay - 1);
        ifu_next = 1;
        wait (1);
      }

      else if (opcode == 0x06) {
        // (ALU) MOVHI...
        perfMon.Count (evALU);
        delay = RunAlu (insn, afMovhi, aaReg, abImm16hi, 1, 0, 0);
        if (delay > 1) wait (delay - 1);
        ifu_next = 1;
        wait (1);
      }

      else if (opcode >= 0x21 && opcode <= 0x26) {
        // (LS) Load...
        sc_uint<2> width = ((opcode - 1) & 6) >> 1;   // will need awful table for implementation
        bool signExt = !(opcode & 1);
        TWord data, adr;

        perfMon.Count (evLoad);

        //   calculate adress & set LSU signals...
        delay = RunAlu (insn, afAdd, aaReg, abImm16s, 0, 0, 0, &adr);
        if (delay > 1) wait (delay - 1);
        lsu_adr = adr;
        lsu_width = width;
        lsu_exts = signExt;
        lsu_rd = 1;
        //   wait for ACK...
        while (lsu_ack == 0) wait (1);
        lsu_rd = 0;
        //INFOF (("Load (%08x) = %08x    SP/R1 = %08x", adr, lsu_rdata.read (), regFile[1].read ()));
        ifu_next = 1;
        wait (1);
        //   read & write back result (were delayed)...
        regFile [insn.range(25, 21)] = lsu_rdata;
      }
      else if (opcode >= 0x35 && opcode <= 0x37) {
        // (LS) Store...
        sc_uint<2> width = (opcode -1) & 3;
        TWord adr;

        perfMon.Count (evStore);

        //   calculate adress & set LSU signals...
        delay = RunAlu (insn, afAdd, aaReg, abImm162s, 0, 0, 0, &adr);
        if (delay > 1) wait (delay - 1);
        lsu_adr = adr;
        lsu_wdata = regFile [insn.range(15, 11)];
        lsu_width = width;
        lsu_wr = 1;
        //   wait for ACK...
        while (lsu_ack == 0) wait (1);
        lsu_wr = 0;
        // INFOF (("Store (%08x) = %08x   SP/R1 = %08x", adr, regFile [insn.range(15, 11)].read (), regFile[1].read ()));
        ifu_next = 1;
        wait (1);
      }

      else if (opcode == 0x3e) {
        // (LS, ParaNut extension) Cache control...
        TWord adr;
        perfMon.Count (evOther);
        //   calculate adress...
        delay = RunAlu (insn, afAdd, aaReg, abImm162s, 0, 0, 0, &adr);
        if (delay > 1) wait (delay - 1);
        lsu_adr = adr;
        //   flush LSU...
        lsu_flush = 1;
        //   wait for ACK...
        while (lsu_ack == 0) wait (1);
        lsu_flush = 0;
        wait (1);  // wait for 'lsu_ack' to go down
        //   set cache control signals...
        lsu_cache_invalidate = insn [11];
        lsu_cache_writeback = insn [12];
        //   wait for ACK...
        while (lsu_ack == 0) wait (1);
        lsu_cache_invalidate = 0;
        lsu_cache_writeback = 0;
        //INFOF (("Cache control op-%i, adr = 0x%08x", (int) insn.range (12, 11).value (), adr));
        //    done...
        ifu_next = 1;
        wait (1);
      }

      else if (opcode <= 0x04 || opcode == 0x11 || opcode == 0x12) {
        // (JMP) j, jal, bnf, bf, jr, jalr ...
        TWord adr;

        perfMon.Count (evJump);
        if (opcode <= 0x01 || opcode >= 0x11 || (regF == insn[28])) {    // Jump or Branch taken?
          if (opcode >= 0x11)
            adr = regFile [insn.range(15, 11)];
          else {
            delay = RunAlu (insn, afAdd, aaPc, abImm26s, 0, 0, 0, &adr);
            if (delay > 1) wait (delay - 1);
          }
          // INFOF (("Jumping to 0x%x", adr));

          ifu_jump_adr = adr;
          nextInDelaySlot = 1;
          if (opcode == 0x01 || opcode == 0x12) {    // write to link register?
            // first get link adress, then perform the jump...
            ifu_next = 1;
            //INFOF (("### jal[r]: before step: pc = 0x%x, npc = 0x%x", ifu_pc.read (), ifu_npc.read ()));
            wait (1);
            ifu_next = 0;
            wait (1);    // FIXME: This wait is only necessary due to SystemC scheduling of the 'npc_*pc' signals
            //INFOF (("### jal[r]: before wait: pc = 0x%x, npc = 0x%x", ifu_pc.read (), ifu_npc.read ()));
            while (ifu_npc_valid == 0) wait (1);
            //INFOF (("### jal[r]: after  wait: pc = 0x%x, npc = 0x%x", ifu_pc.read (), ifu_npc.read ()));
            regFile[LINK_REGISTER] = ifu_npc;
            ifu_jump = 1;
            wait (1);
          }
          else {   // no writing to link register necessary...
            ifu_jump = 1;
            ifu_next = 1;
            wait (1);
          }
        }
        else {
          // no jump: just fetch the next instruction
          ifu_next = 1;
          wait (1);
        }
      }

      else if (opcode == 0x05) {
        // (other) NOP...
        perfMon.Count (evOther);
        switch (insn.range (15, 0)) {
          case 0x0001:    // HALT
            // INFO ("HALT instruction received.");
	    mode = 0;
            while (true) wait ();
            break;
          case 0x0004:    // outbyte
            putchar (regFile[3].read ());
            //INFOF(("TERM: '%c'", regFile[3].read ()));
            break;
        }
        ifu_next = 1;
        wait (1);
      }

      else if (opcode == 0x08 && insn.range (25, 21) == 0) {
        // (other) SYS / (TRAP to be inserted here)...
        perfMon.Count (evOther);
        exceptId = 0xc;
        exceptRestart = false;
        //WARNING (("System calls not implemented yet - ignoring l.sys/l.trap."));    // Exceptions not implemented yet
      }
      else if (opcode == 0x09) {
        // (other) RFE ...
        perfMon.Count (evOther);
        SetSpr (sprSR, regESR);
        ifu_jump_adr = regEPCR;
        ifu_jump = 1;
        ifu_next = 1;
        wait (1);
        ifu_next = ifu_jump = 0;
        wait (1);
        while (ifu_ir_valid == 0) wait (1);  // skip next instruction (delay slot)
        //ERROR (("Exeptions not implemented yet."));    // Exceptions not implemented yet
      }

      else if (opcode == 0x2d) {
        // (other) MFSPR...
        TWord regNo;
        perfMon.Count (evOther);
        delay = RunAlu (insn, afOr, aaReg, abImm16z, 0, 0, 0, &regNo);
        if (delay > 1) wait (delay - 1);
        regFile [insn.range(25, 21)] = GetSpr (regNo & 0xffff);
        ifu_next = 1;
        wait (1);
      }
      else if (opcode == 0x30) {
        // (other) MTSPR...
        TWord regNo;
        perfMon.Count (evOther);
        delay = RunAlu (insn, afOr, aaReg, abImm162s, 0, 0, 0, &regNo);
        if (delay > 1) wait (delay - 1);
        SetSpr (regNo & 0xffff, regFile [insn.range(15, 11)]);
        ifu_next = 1;
        wait (1);
      }

      else ASSERTM (false, "Unsupported or illegal opcode");   // illegal or unknown opcode

    }  // if (ifu_ir_valid)

    // Handle Exception...
    if (exceptId > 0) {
      if (inCePU) {        // CePU exceptions...
        // Store ESR, EPCR and EEAR (if applicable)...
        regESR = GetSpr (sprSR);
        if (exceptRestart)
          regEPCR = inDelaySlot ? ifu_ppc : ifu_pc;
        else
          regEPCR = ifu_npc;
        // Disable interrupts...
        regIEE = 0;
        // Jump to exception routine...
        ifu_jump_adr = exceptId * 0x100;
        ifu_jump = 1;
        ifu_next = 1;
        // Wait & ignore delay slot instruction...
        wait (1);
        ifu_next = ifu_jump = 0;
        while (ifu_ir_valid == 0) wait (1);
        // Reset 'exceptId'...
        exceptId = 0;
      }
      else {               // CoPU exceptions...
        ERROR (("CoPU exception asserted - not implemented yet."));
      }

    }   // if (exceptId > 0)

  }  // while (true)
}
